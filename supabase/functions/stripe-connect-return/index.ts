import Stripe from 'npm:stripe@14';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const profileId = url.searchParams.get('pid');

  if (profileId) {
    try {
      const serviceClient = createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      );

      const { data: profile } = await serviceClient
        .from('profiles')
        .select('stripe_account_id')
        .eq('id', profileId)
        .single();

      if (profile?.stripe_account_id) {
        const account = await stripe.accounts.retrieve(profile.stripe_account_id);
        await serviceClient
          .from('profiles')
          .update({ stripe_payouts_enabled: account.payouts_enabled ?? false })
          .eq('id', profileId);
      }
    } catch (e) {
      console.error('stripe-connect-return sync error:', e);
    }
  }

  const html = `<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>Stripe Setup Complete</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
      body { font-family: sans-serif; display: flex; flex-direction: column;
             align-items: center; justify-content: center; min-height: 100vh;
             margin: 0; background: #f5f5f5; color: #333; text-align: center; padding: 24px; }
      h1 { font-size: 24px; margin-bottom: 8px; }
      p  { color: #666; }
      a  { display: inline-block; margin-top: 24px; padding: 12px 28px;
           background: #635BFF; color: #fff; border-radius: 8px;
           text-decoration: none; font-weight: 600; }
    </style>
    <script>
      // Android Chrome blocks custom URI schemes from JS; use Intent URI instead.
      var intentUrl = 'intent://stripe-return#Intent;scheme=luxihub;package=com.example.luxihub_handyman;end';
      var customUrl = 'luxihub://stripe-return';

      window.onload = function () {
        var ua = navigator.userAgent.toLowerCase();
        var isAndroid = ua.indexOf('android') > -1;
        window.location.href = isAndroid ? intentUrl : customUrl;
        setTimeout(function () {
          document.getElementById('fallback').style.display = 'block';
        }, 2500);
      };
    </script>
  </head>
  <body>
    <h1>Setup Complete &#10003;</h1>
    <p>Your Stripe payout account has been connected.<br/>Returning to the app&#8230;</p>
    <div id="fallback" style="display:none">
      <p>If the app did not open automatically:</p>
      <a href="intent://stripe-return#Intent;scheme=luxihub;package=com.example.luxihub_handyman;end">Open App (Android)</a>
    </div>
  </body>
</html>`;

  return new Response(html, {
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Access-Control-Allow-Origin': '*',
    },
  });
});
