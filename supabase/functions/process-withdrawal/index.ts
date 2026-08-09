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

    // Recompute the platform fee here, from the live platform_settings value,
    // rather than trusting withdrawal.fee_amount/net_amount as stored. Those
    // were computed client-side when the withdrawal was requested — using
    // them directly for the actual transfer would mean a modified client (or
    // a stale admin-configured fee at request time) could under-pay the
    // platform. This is the one place real money moves, so it's the one place
    // the admin-configured fee has to be authoritative.
    const grossAmount: number = withdrawal.amount;
    let feePercent = 10.0;
    try {
      const { data: feeSetting } = await supabase
        .from('platform_settings')
        .select('value')
        .eq('key', 'platform_fee_percent')
        .maybeSingle();
      const rawValue = feeSetting?.value;
      if (rawValue !== null && rawValue !== undefined) {
        const parsed = typeof rawValue === 'number' ? rawValue : parseFloat(String(rawValue));
        if (!Number.isNaN(parsed)) feePercent = parsed;
      }
    } catch (_err) {
      // Fall back to the 10% default below if platform_settings is unreachable.
    }
    const feeAmount = Math.round(grossAmount * (feePercent / 100) * 100) / 100;
    const payoutAmount = Math.round((grossAmount - feeAmount) * 100) / 100;
    const amountCents = Math.round(payoutAmount * 100);
    const currency: string = withdrawal.currency ?? 'gbp';

    // Persist the authoritative figures so the stored record matches what's
    // actually transferred, regardless of what was estimated at request time.
    await supabase
      .from('withdrawals')
      .update({
        platform_fee_percent: feePercent,
        fee_amount: feeAmount,
        net_amount: payoutAmount,
      })
      .eq('id', withdrawal_id);

    // ── 8. Create the Stripe transfer (platform → connected account) ───────
    let transfer: Stripe.Transfer;
    try {
      transfer = await stripe.transfers.create({
        amount: amountCents,           // net amount — platform fee already deducted
        currency,
        destination: stripeAccountId,
        transfer_group: `withdrawal_${withdrawal_id}`,
        description: `Withdrawal for ${profile?.name ?? user.id} (gross £${grossAmount}, fee £${feeAmount})`,
        metadata: {
          withdrawal_id,
          provider_id: user.id,
          provider_stripe_account: stripeAccountId,
          gross_amount: String(grossAmount),
          fee_amount: String(feeAmount),
          net_amount: String(payoutAmount),
          platform_fee_percent: String(feePercent),
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
