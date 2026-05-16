import Stripe from 'npm:stripe@14';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), { status: 401 });
    }

    // Verify caller is authenticated
    const anonClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: authError } = await anonClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    }

    const serviceClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Fetch existing stripe_account_id from profile
    const { data: profile } = await serviceClient
      .from('profiles')
      .select('stripe_account_id, email')
      .eq('id', user.id)
      .single();

    let accountId: string = profile?.stripe_account_id;

    if (!accountId) {
      const account = await stripe.accounts.create({
        type: 'express',
        email: profile?.email ?? user.email,
        capabilities: { transfers: { requested: true } },
      });
      accountId = account.id;

      await serviceClient
        .from('profiles')
        .update({ stripe_account_id: accountId, stripe_payouts_enabled: false })
        .eq('id', user.id);
    } else {
      // Sync latest payouts_enabled from Stripe into the DB
      const existing = await stripe.accounts.retrieve(accountId);
      await serviceClient
        .from('profiles')
        .update({ stripe_payouts_enabled: existing.payouts_enabled ?? false })
        .eq('id', user.id);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const accountLink = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: `${supabaseUrl}/functions/v1/create-connect-account`,
      return_url: `${supabaseUrl}/functions/v1/stripe-connect-return?pid=${user.id}`,
      type: 'account_onboarding',
    });

    return new Response(JSON.stringify({ url: accountLink.url }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    });
  } catch (err) {
    console.error('create-connect-account error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
