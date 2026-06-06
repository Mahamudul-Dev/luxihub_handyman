import Stripe from "https://esm.sh/stripe@14.25.0";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!);

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }
  try {
    const { amount, currency, providerId, jobRequestId } = await req.json();

    if (!providerId) {
      throw new Error("providerId is required.");
    }
    if (!jobRequestId) {
      throw new Error("jobRequestId is required.");
    }

    // Money is collected by the platform (no transfer_data).
    // The stripe-webhook function credits the provider wallet on
    // payment_intent.succeeded, and process-withdrawal handles
    // the real Stripe transfer when the handyman requests a payout.
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // smallest currency unit
      currency: currency ?? "gbp",
      automatic_payment_methods: { enabled: true },
      metadata: {
        job_request_id: jobRequestId,
        provider_id: providerId,
        amount: amount.toString(),
      },
    });

    return new Response(
      JSON.stringify({ clientSecret: paymentIntent.client_secret }),
      { headers: { ...cors, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      headers: { ...cors, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
