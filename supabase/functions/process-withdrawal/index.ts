import Stripe from 'npm:stripe@14';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  try {
    // ── 1. Authenticate the caller ─────────────────────────────────────────
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return json({ error: 'Unauthorized' }, 401);

    const userSupabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: authError } = await userSupabase.auth.getUser();
    if (authError || !user) return json({ error: 'Unauthorized' }, 401);

    // ── 2. Parse & validate input ──────────────────────────────────────────
    const { withdrawal_id } = await req.json();
    if (!withdrawal_id) return json({ error: 'Missing withdrawal_id' }, 400);

    // Service-role client for DB writes.
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // ── 3. Fetch withdrawal with provider's Stripe account ─────────────────
    const { data: withdrawal, error: fetchError } = await supabase
      .from('withdrawals')
      .select('*, profiles!profile_id(stripe_account_id, name)')
      .eq('id', withdrawal_id)
      .single();

    if (fetchError || !withdrawal) return json({ error: 'Withdrawal not found' }, 404);

    // ── 4. Ownership check ─────────────────────────────────────────────────
    if (withdrawal.profile_id !== user.id) {
      return json({ error: 'Forbidden' }, 403);
    }

    // ── 5. Status guard — only process pending withdrawals ─────────────────
    if (withdrawal.status !== 'pending') {
      return json({
        error: `Withdrawal is already ${withdrawal.status}`,
        transfer_id: withdrawal.stripe_transfer_id ?? null,
      }, 400);
    }

    // ── 6. Idempotency — skip if already transferred ───────────────────────
    if (withdrawal.stripe_transfer_id) {
      return json({ transfer_id: withdrawal.stripe_transfer_id });
    }

    // ── 7. Validate connected account ─────────────────────────────────────
    const profile = withdrawal.profiles as {
      stripe_account_id: string | null;
      name: string | null;
    } | null;

    const stripeAccountId = profile?.stripe_account_id;
    if (!stripeAccountId) {
      return json({ error: 'Provider has no connected Stripe account' }, 400);
    }

    // Use net_amount (after platform fee) if available; fall back to gross amount
    // for legacy rows created before fee columns existed.
    const payoutAmount: number = withdrawal.net_amount > 0
      ? withdrawal.net_amount
      : withdrawal.amount;
    const amountCents = Math.round(payoutAmount * 100);
    const currency: string = withdrawal.currency ?? 'gbp';

    // ── 8. Create the Stripe transfer (platform → connected account) ───────
    let transfer: Stripe.Transfer;
    try {
      transfer = await stripe.transfers.create({
        amount: amountCents,           // net amount — platform fee already deducted
        currency,
        destination: stripeAccountId,
        transfer_group: `withdrawal_${withdrawal_id}`,
        description: `Withdrawal for ${profile?.name ?? user.id} (gross £${withdrawal.amount}, fee £${withdrawal.fee_amount ?? 0})`,
        metadata: {
          withdrawal_id,
          provider_id: user.id,
          provider_stripe_account: stripeAccountId,
          gross_amount: String(withdrawal.amount),
          fee_amount: String(withdrawal.fee_amount ?? 0),
          net_amount: String(payoutAmount),
        },
      });
    } catch (stripeErr) {
      const msg = stripeErr instanceof Stripe.errors.StripeError
        ? stripeErr.message
        : String(stripeErr);

      console.error('Stripe transfer failed:', msg);

      // Mark as failed so the handyman and admin can see it.
      await supabase
        .from('withdrawals')
        .update({ status: 'failed' })
        .eq('id', withdrawal_id);

      return json({ error: `Transfer failed: ${msg}` }, 502);
    }

    // ── 9. Persist result and mark completed ──────────────────────────────
    await supabase
      .from('withdrawals')
      .update({
        stripe_transfer_id: transfer.id,
        status: 'completed',
      })
      .eq('id', withdrawal_id);

    console.log(
      `Withdrawal ${withdrawal_id}: transferred ${withdrawal.amount} ${currency} ` +
      `to ${stripeAccountId} via ${transfer.id}`,
    );

    return json({ transfer_id: transfer.id });

  } catch (err) {
    console.error('process-withdrawal unexpected error:', err);
    return json({ error: String(err) }, 500);
  }
});
