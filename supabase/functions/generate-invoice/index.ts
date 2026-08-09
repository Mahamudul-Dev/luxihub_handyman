import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { PDFDocument, StandardFonts, rgb, type PDFFont, type PDFPage } from "https://esm.sh/pdf-lib@1.17.1";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

interface Branding {
  company_name: string;
  logo_url: string;
  address_line: string;
  support_email: string;
  support_phone: string;
  footer_note: string;
}

const DEFAULT_BRANDING: Branding = {
  company_name: "LuxiHub",
  logo_url: "",
  address_line: "",
  support_email: "",
  support_phone: "",
  footer_note: "Thank you for using LuxiHub.",
};

function money(amount: number, currency: string) {
  const symbol = currency?.toLowerCase() === "gbp" ? "£" : currency?.toLowerCase() === "usd" ? "$" : currency?.toLowerCase() === "eur" ? "€" : `${currency?.toUpperCase() ?? ""} `;
  return `${symbol}${(amount ?? 0).toFixed(2)}`;
}

function formatDate(iso: string | null | undefined) {
  if (!iso) return "—";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}

async function buildInvoicePdf(params: {
  txn: any;
  job: any;
  clientProfile: any;
  providerProfile: any;
  branding: Branding;
}): Promise<Uint8Array> {
  const { txn, job, clientProfile, providerProfile, branding } = params;

  const pdfDoc = await PDFDocument.create();
  const page = pdfDoc.addPage([595.28, 841.89]); // A4
  const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const bold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

  const margin = 48;
  const contentWidth = page.getWidth() - margin * 2;
  const brandColor = rgb(0.17, 0.48, 0.31); // #2D7A4F
  const mutedColor = rgb(0.42, 0.42, 0.42);
  const lineColor = rgb(0.85, 0.85, 0.85);

  let y = page.getHeight() - margin;

  // ── Header: logo (if any) + company name on the left, INVOICE + number on the right ──
  let logoDrawn = false;
  if (branding.logo_url) {
    try {
      const res = await fetch(branding.logo_url);
      const contentType = res.headers.get("content-type") ?? "";
      const bytes = new Uint8Array(await res.arrayBuffer());
      const image = contentType.includes("png")
        ? await pdfDoc.embedPng(bytes)
        : await pdfDoc.embedJpg(bytes);
      const logoHeight = 40;
      const logoWidth = (image.width / image.height) * logoHeight;
      page.drawImage(image, { x: margin, y: y - logoHeight, width: logoWidth, height: logoHeight });
      logoDrawn = true;
    } catch (_err) {
      // Logo fetch/embed failed — fall back to text-only header, invoice still generates.
      logoDrawn = false;
    }
  }

  if (!logoDrawn) {
    page.drawText(branding.company_name || "LuxiHub", {
      x: margin,
      y: y - 20,
      size: 18,
      font: bold,
      color: brandColor,
    });
  }

  const invoiceNumber = `INV-${(txn.id as string).slice(0, 8).toUpperCase()}`;
  const invoiceTitleWidth = bold.widthOfTextAtSize("INVOICE", 20);
  page.drawText("INVOICE", {
    x: page.getWidth() - margin - invoiceTitleWidth,
    y: y - 18,
    size: 20,
    font: bold,
    color: rgb(0.1, 0.1, 0.1),
  });
  const metaLine = `${invoiceNumber}  ·  ${formatDate(txn.created_at)}`;
  const metaWidth = font.widthOfTextAtSize(metaLine, 10);
  page.drawText(metaLine, {
    x: page.getWidth() - margin - metaWidth,
    y: y - 34,
    size: 10,
    font,
    color: mutedColor,
  });

  y -= 56;
  if (branding.address_line) {
    page.drawText(branding.address_line, { x: margin, y, size: 9, font, color: mutedColor });
    y -= 14;
  }
  const contactBits = [branding.support_email, branding.support_phone].filter(Boolean).join("  ·  ");
  if (contactBits) {
    page.drawText(contactBits, { x: margin, y, size: 9, font, color: mutedColor });
    y -= 14;
  }

  y -= 12;
  page.drawLine({ start: { x: margin, y }, end: { x: margin + contentWidth, y }, thickness: 1, color: lineColor });
  y -= 28;

  // ── Billed to / Service provider ──────────────────────────────────────────
  const colWidth = contentWidth / 2;
  const drawParty = (label: string, name: string, email: string, x: number) => {
    page.drawText(label, { x, y, size: 9, font: bold, color: mutedColor });
    page.drawText(name || "—", { x, y: y - 16, size: 12, font: bold, color: rgb(0.1, 0.1, 0.1) });
    page.drawText(email || "", { x, y: y - 32, size: 10, font, color: mutedColor });
  };
  drawParty("BILLED TO", clientProfile?.name, clientProfile?.email, margin);
  drawParty("SERVICE PROVIDER", providerProfile?.name, providerProfile?.email, margin + colWidth);

  y -= 64;
  page.drawLine({ start: { x: margin, y }, end: { x: margin + contentWidth, y }, thickness: 1, color: lineColor });
  y -= 28;

  // ── Job details ───────────────────────────────────────────────────────────
  const category = job?.category
    ? job.category.charAt(0).toUpperCase() + job.category.slice(1)
    : "Service";
  page.drawText("SERVICE", { x: margin, y, size: 9, font: bold, color: mutedColor });
  y -= 16;
  page.drawText(category, { x: margin, y, size: 12, font: bold, color: rgb(0.1, 0.1, 0.1) });
  y -= 16;
  if (job?.description) {
    const wrapped = wrapText(job.description, font, 10, contentWidth);
    for (const line of wrapped.slice(0, 3)) {
      page.drawText(line, { x: margin, y, size: 10, font, color: mutedColor });
      y -= 14;
    }
  }
  y -= 8;
  page.drawText(`Completed: ${formatDate(job?.completed_at ?? txn.created_at)}`, {
    x: margin,
    y,
    size: 10,
    font,
    color: mutedColor,
  });

  y -= 32;
  page.drawLine({ start: { x: margin, y }, end: { x: margin + contentWidth, y }, thickness: 1, color: lineColor });
  y -= 28;

  // ── Payment summary ───────────────────────────────────────────────────────
  const rows: Array<[string, string]> = [
    ["Payment method", txn.payment_method === "stripe" ? "Card" : "Cash"],
    ["Status", (txn.status ?? "").charAt(0).toUpperCase() + (txn.status ?? "").slice(1)],
    ["Transaction ID", txn.id],
  ];
  for (const [label, value] of rows) {
    page.drawText(label, { x: margin, y, size: 10, font, color: mutedColor });
    const valueWidth = font.widthOfTextAtSize(value, 10);
    page.drawText(value, { x: margin + contentWidth - valueWidth, y, size: 10, font, color: rgb(0.1, 0.1, 0.1) });
    y -= 18;
  }

  y -= 10;
  page.drawRectangle({
    x: margin,
    y: y - 30,
    width: contentWidth,
    height: 40,
    color: rgb(0.95, 0.97, 0.96),
  });
  page.drawText("Total Paid", { x: margin + 16, y: y - 12, size: 12, font: bold, color: rgb(0.1, 0.1, 0.1) });
  const totalText = money(txn.amount, txn.currency);
  const totalWidth = bold.widthOfTextAtSize(totalText, 16);
  page.drawText(totalText, {
    x: margin + contentWidth - 16 - totalWidth,
    y: y - 14,
    size: 16,
    font: bold,
    color: brandColor,
  });

  // ── Footer ─────────────────────────────────────────────────────────────────
  if (branding.footer_note) {
    page.drawText(branding.footer_note, {
      x: margin,
      y: margin,
      size: 9,
      font,
      color: mutedColor,
    });
  }

  return pdfDoc.save();
}

function wrapText(text: string, font: PDFFont, size: number, maxWidth: number): string[] {
  const words = text.split(/\s+/);
  const lines: string[] = [];
  let current = "";
  for (const word of words) {
    const candidate = current ? `${current} ${word}` : word;
    if (font.widthOfTextAtSize(candidate, size) > maxWidth && current) {
      lines.push(current);
      current = word;
    } else {
      current = candidate;
    }
  }
  if (current) lines.push(current);
  return lines;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const authHeader = req.headers.get("authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!token) return jsonError("Missing authorization", 401);

    // Client scoped to the caller's own JWT — used only to find out who's asking.
    const callerClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });
    const { data: userData, error: userError } = await callerClient.auth.getUser();
    if (userError || !userData.user) return jsonError("Invalid session", 401);
    const callerId = userData.user.id;

    let body: { transactionId?: string };
    try {
      body = await req.json();
    } catch {
      return jsonError("Invalid JSON body", 400);
    }

    const transactionId = body.transactionId;
    if (!transactionId) return jsonError("transactionId is required", 400);

    // Service-role client for the actual data fetch — the caller was already
    // authenticated above, and we check row ownership explicitly below.
    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    // Fetched as plain, separate queries rather than PostgREST embeds — the
    // transactions/job_requests/profiles relationships aren't confirmed to
    // have named FK constraints in this schema (embedding without one fails
    // with a schema-cache error), so this joins manually instead.
    const { data: txn, error: txnError } = await admin
      .from("transactions")
      .select("*")
      .eq("id", transactionId)
      .single();

    if (txnError || !txn) return jsonError("Transaction not found", 404);

    if (txn.client_id !== callerId && txn.provider_id !== callerId) {
      return jsonError("Forbidden", 403);
    }

    const [{ data: job }, { data: clientProfile }, { data: providerProfile }, { data: brandingSetting }] = await Promise.all([
      admin.from("job_requests").select("category, description, posted_at, completed_at").eq("id", txn.job_request_id).maybeSingle(),
      admin.from("profiles").select("name, email").eq("id", txn.client_id).maybeSingle(),
      admin.from("profiles").select("name, email").eq("id", txn.provider_id).maybeSingle(),
      admin.from("platform_settings").select("value").eq("key", "invoice_branding").maybeSingle(),
    ]);

    const branding: Branding = { ...DEFAULT_BRANDING, ...(brandingSetting?.value ?? {}) };

    const pdfBytes = await buildInvoicePdf({ txn, job, clientProfile, providerProfile, branding });

    return new Response(pdfBytes, {
      status: 200,
      headers: {
        ...cors,
        "Content-Type": "application/pdf",
        "Content-Disposition": `attachment; filename="invoice-${(txn.id as string).slice(0, 8)}.pdf"`,
      },
    });
  } catch (err) {
    console.error("generate-invoice error:", err);
    return jsonError("Internal handler error", 500);
  }
});
