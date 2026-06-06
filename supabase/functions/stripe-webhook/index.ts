import Stripe from "https://esm.sh/stripe@14.25.0";
import { createClient } from "jsr:@supabase/supabase-js@2";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!);
const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;

Deno.serve(async (req) => {
  // Stripe sends POST requests with a raw body — read as text for signature check.
  const body = await req.text();
  const sig = req.headers.get("stripe-signature");

  if (!sig) {
    return new Response("Missing stripe-signature header", { status: 400 });
  }

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(body, sig, webhookSecret);
  } catch (e) {
    console.error("Webhook signature verification failed:", e);
    return new Response(`Webhook Error: ${(e as Error).message}`, {
      status: 400,
    });
  }

  // Only handle successful payments.
  if (event.type !== "payment_intent.succeeded") {
    return new Response(JSON.stringify({ received: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  }

  const pi = event.data.object as Stripe.PaymentIntent;
  const jobRequestId = pi.metadata?.job_request_id;
  const providerId = pi.metadata?.provider_id;
  // Amount is in smallest currency unit (pence/cents); convert back.
  const amount = pi.amount_received / 100;

  if (!jobRequestId || !providerId) {
    console.error("Missing metadata on PaymentIntent:", pi.id);
    return new Response("Missing metadata", { status: 400 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // 1. Mark job as completed and record the paid amount.
  const { error: jobError } = await supabase
    .from("job_requests")
    .update({
      status: "completed",
      amount: amount,
      completed_at: new Date().toISOString(),
    })
    .eq("id", jobRequestId);

  if (jobError) {
    console.error("Failed to update job_request:", jobError.message);
    return new Response(JSON.stringify({ error: jobError.message }), {
      status: 500,
    });
  }

  // 2. Credit the provider wallet.
  //    Use a raw RPC increment so concurrent updates don't race.
  const { error: walletError } = await supabase.rpc("increment_wallet_balance", {
    p_provider_id: providerId,
    p_amount: amount,
  });

  if (walletError) {
    // Fallback: read-then-write if the RPC doesn't exist yet.
    console.warn("RPC not available, falling back:", walletError.message);

    const { data: existing } = await supabase
      .from("wallet")
      .select("balance")
      .eq("id", providerId)
      .maybeSingle();

    const newBalance = ((existing?.balance as number) ?? 0) + amount;

    await supabase
      .from("wallet")
      .upsert({ id: providerId, balance: newBalance });
  }

  console.log(
    `Payment ${pi.id}: job ${jobRequestId} completed, ` +
      `wallet +${amount} for provider ${providerId}`
  );

  return new Response(JSON.stringify({ received: true }), {
    headers: { "Content-Type": "application/json" },
    status: 200,
  });
});
