import Stripe from 'npm:stripe@14';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);

Deno.serve(async (req) => {
  try {
    const { withdrawal_id } = await req.json();
    if (!withdrawal_id) {
      return new Response(JSON.stringify({ error: 'Missing withdrawal_id' }), { status: 400 });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Fetch withdrawal + provider's Stripe account via FK join
    const { data: withdrawal, error } = await supabase
      .from('withdrawals')
      .select('*, profiles!profile_id(stripe_account_id)')
      .eq('id', withdrawal_id)
      .single();

    if (error || !withdrawal) {
      return new Response(JSON.stringify({ error: 'Withdrawal not found' }), { status: 404 });
    }

    if (withdrawal.stripe_transfer_id) {
      // Already processed — idempotent return
      return new Response(JSON.stringify({ transfer_id: withdrawal.stripe_transfer_id }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const stripeAccountId = (withdrawal.profiles as { stripe_account_id: string | null } | null)
      ?.stripe_account_id;
    if (!stripeAccountId) {
      return new Response(
        JSON.stringify({ error: 'Provider has no connected Stripe account' }),
        { status: 400 },
      );
    }

    const amountCents = Math.round(withdrawal.amount * 100);

    const transfer = await stripe.transfers.create({
      amount: amountCents,
      currency: 'eur',
      destination: stripeAccountId,
      transfer_group: `withdrawal_${withdrawal_id}`,
    });

    // Persist transfer ID so we never double-pay
    await supabase
      .from('withdrawals')
      .update({ stripe_transfer_id: transfer.id })
      .eq('id', withdrawal_id);

    return new Response(JSON.stringify({ transfer_id: transfer.id }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('process-withdrawal error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
