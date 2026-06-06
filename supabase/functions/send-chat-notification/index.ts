/**
 * send-chat-notification
 *
 * Triggered by a DB trigger on messages INSERT.
 * Sends an FCM push to the recipient of the chat message.
 * Does NOT write to the notifications table.
 */

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
    const payload = await req.json();
    const message = payload.record as {
      id: string;
      conversation_id: string;
      sender_id: string;
      text: string;
      created_at: string;
    };

    if (!message?.id) {
      return new Response(JSON.stringify({ error: "No record in payload" }), {
        status: 400, headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    console.log(`send-chat-notification: message ${message.id} in conv ${message.conversation_id}`);

    // ── 1. Load the conversation to find the recipient ─────────────────────
    const { data: conv, error: convError } = await supabase
      .from("conversations")
      .select("client_id, provider_id")
      .eq("id", message.conversation_id)
      .single();

    if (convError || !conv) {
      console.error("Conversation not found:", convError);
      return new Response(JSON.stringify({ error: "Conversation not found" }), {
        status: 404, headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    // Recipient is the party who did NOT send the message
    const recipientId =
      message.sender_id === conv.client_id ? conv.provider_id : conv.client_id;

    // ── 2. Load sender display name ────────────────────────────────────────
    const { data: sender } = await supabase
      .from("profiles")
      .select("name")
      .eq("id", message.sender_id)
      .maybeSingle();

    const senderName = sender?.name ?? "Someone";

    // ── 3. Load recipient device tokens ────────────────────────────────────
    const { data: tokenRows, error: tokensError } = await supabase
      .from("device_tokens")
      .select("token")
      .eq("user_id", recipientId);

    if (tokensError) throw new Error(tokensError.message);
    if (!tokenRows?.length) {
      console.log(`No device tokens for recipient ${recipientId}`);
      return new Response(JSON.stringify({ sent: 0 }), {
        status: 200, headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    // ── 4. Send FCM push ───────────────────────────────────────────────────
    const account = getServiceAccount();
    const accessToken = await getFcmAccessToken(account);

    const tokens = tokenRows.map((r) => r.token as string);
    const sent = await sendFcmToMany(
      accessToken,
      account.project_id,
      tokens,
      senderName,
      message.text.length > 100
        ? `${message.text.slice(0, 97)}…`
        : message.text,
      {
        type: "chat",
        conversationId: message.conversation_id,
        senderId: message.sender_id,
        senderName,
      }
    );

    console.log(`send-chat-notification: pushed to ${sent}/${tokens.length} device(s) for recipient ${recipientId}`);

    return new Response(
      JSON.stringify({ success: true, sent }),
      { status: 200, headers: { ...cors, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("send-chat-notification error:", e);
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 500, headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
