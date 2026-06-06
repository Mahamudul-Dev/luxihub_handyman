import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")! // service role bypasses RLS
);

const ADMIN_API_KEY = Deno.env.get("ADMIN_API_KEY")!;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type NotificationType = "general" | "job_update" | "payment" | "system";

interface SendNotificationBody {
  title: string;
  body: string;
  type?: NotificationType;
  targetUserId?: string | null; // null or omitted = send to ALL users
  data?: Record<string, unknown>;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  // ── Auth check ─────────────────────────────────────────────────────────────
  const authHeader = req.headers.get("authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();

  if (!ADMIN_API_KEY || token !== ADMIN_API_KEY) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }

  // ── Parse body ─────────────────────────────────────────────────────────────
  let payload: SendNotificationBody;
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }

  const { title, body, type = "general", targetUserId, data } = payload;

  if (!title?.trim() || !body?.trim()) {
    return new Response(
      JSON.stringify({ error: "title and body are required" }),
      {
        status: 400,
        headers: { ...cors, "Content-Type": "application/json" },
      }
    );
  }

  const validTypes: NotificationType[] = [
    "general",
    "job_update",
    "payment",
    "system",
  ];
  if (!validTypes.includes(type)) {
    return new Response(
      JSON.stringify({
        error: `Invalid type. Must be one of: ${validTypes.join(", ")}`,
      }),
      { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
    );
  }

  // ── Insert notification ─────────────────────────────────────────────────────
  const isTargeted = !!targetUserId;

  // If targeted, verify the user exists
  if (isTargeted) {
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("id")
      .eq("id", targetUserId)
      .maybeSingle();

    if (profileError || !profile) {
      return new Response(
        JSON.stringify({ error: `User not found: ${targetUserId}` }),
        {
          status: 404,
          headers: { ...cors, "Content-Type": "application/json" },
        }
      );
    }
  }

  const { data: inserted, error } = await supabase
    .from("notifications")
    .insert({
      title: title.trim(),
      body: body.trim(),
      type,
      target_type: isTargeted ? "user" : "all",
      target_user_id: isTargeted ? targetUserId : null,
      data: data ?? null,
    })
    .select("id")
    .single();

  if (error) {
    console.error("Insert notification error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }

  console.log(
    `Notification sent [${inserted.id}] → ${isTargeted ? `user:${targetUserId}` : "all users"}`
  );

  return new Response(
    JSON.stringify({
      success: true,
      notificationId: inserted.id,
      sentTo: isTargeted ? `user:${targetUserId}` : "all",
    }),
    { status: 200, headers: { ...cors, "Content-Type": "application/json" } }
  );
});
