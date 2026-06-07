import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  getFcmAccessToken,
  getServiceAccount,
  sendFcmToMany,
} from "../_shared/fcm.ts";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const rawBody = await req.text();
    if (!rawBody) {
      return new Response(JSON.stringify({ error: "Empty request body" }), {
        status: 400, headers: { ...cors, "Content-Type": "application/json" },
      });
    }
    const payload = JSON.parse(rawBody);
    const record = payload.record as {
      id: string;
      title: string;
      body: string;
      type: string;
      target_type: "all" | "user";
      target_user_id: string | null;
      data: Record<string, unknown> | null;
    };

    if (!record?.id) {
      return new Response(JSON.stringify({ error: "No record in payload" }), {
        status: 400,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    console.log(`push-notification: ${record.id} → ${record.target_type}`);

    let tokensQuery = supabase.from("device_tokens").select("token");
    if (record.target_type === "user" && record.target_user_id) {
      tokensQuery = tokensQuery.eq("user_id", record.target_user_id);
    }

    const { data: tokenRows, error } = await tokensQuery;
    if (error) throw new Error(error.message);
    if (!tokenRows?.length) {
      return new Response(JSON.stringify({ sent: 0 }), {
        status: 200, headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const account = getServiceAccount();
    const accessToken = await getFcmAccessToken(account);

    const fcmData: Record<string, string> = {
      notificationId: record.id,
      type: record.type,
    };
    if (record.data) {
      for (const [k, v] of Object.entries(record.data)) fcmData[k] = String(v);
    }

    const tokens = tokenRows.map((r) => r.token as string);
    const sent = await sendFcmToMany(
      accessToken,
      account.project_id,
      tokens,
      record.title,
      record.body,
      fcmData
    );

    console.log(`push-notification: sent to ${sent}/${tokens.length} device(s).`);
    return new Response(
      JSON.stringify({ success: true, sent }),
      { status: 200, headers: { ...cors, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("push-notification error:", e);
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 500, headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
