// Money helpers mirroring the SQL in migrations/20261002000200_helpers_settings_money.sql and
// migrations/20261002001050_sales_tax_ppm.sql.
// Integer minor units (paise / cents) only. India GST rates are integer basis points
// (1800 = 18 %); US sales tax rates are integer parts per million (88750 = 8.875 %).
// round_half_up(n, d) = (2n + d) div (2d).
// Shared fixtures: supabase/tests/fixtures/money_rounding_cases.json.

export function roundHalfUp(numerator: bigint, denominator: bigint): bigint {
  if (numerator < 0n || denominator <= 0n) throw new Error("invalid_money_rounding_input");
  return (2n * numerator + denominator) / (2n * denominator);
}

/** Quantity (up to 3 decimals) as integer thousandths, without float drift. */
export function qtyToMilli(qty: number | string): bigint {
  const s = typeof qty === "number" ? qty.toFixed(3) : qty.trim();
  const m = /^(\d+)(?:\.(\d{0,3}))?$/.exec(s);
  if (!m) throw new Error("invalid_line_item");
  return BigInt(m[1]) * 1000n + BigInt((m[2] ?? "").padEnd(3, "0"));
}

function assertRate(bp: number) {
  if (!Number.isInteger(bp) || bp < 0 || bp > 10000) throw new Error("invalid_line_item");
}

export interface GstLineTax {
  base_minor: bigint;
  cgst_minor: bigint;
  sgst_minor: bigint;
  igst_minor: bigint;
  tax_minor: bigint;
}

export function gstLineTax(qty: number | string, unitPriceMinor: bigint | number, rateBp: number, intraState = true): GstLineTax {
  const unit = BigInt(unitPriceMinor);
  const milli = qtyToMilli(qty);
  if (milli <= 0n || unit < 0n) throw new Error("invalid_line_item");
  assertRate(rateBp);
  const base = roundHalfUp(milli * unit, 1000n);
  const bp = BigInt(rateBp);
  if (intraState) {
    const half = roundHalfUp(base * bp, 20000n);
    return { base_minor: base, cgst_minor: half, sgst_minor: half, igst_minor: 0n, tax_minor: half * 2n };
  }
  const igst = roundHalfUp(base * bp, 10000n);
  return { base_minor: base, cgst_minor: 0n, sgst_minor: 0n, igst_minor: igst, tax_minor: igst };
}

/** Parts per million in 100 %. */
export const PPM_PER_UNIT = 1_000_000;

function assertRatePpm(ppm: number) {
  if (!Number.isInteger(ppm) || ppm < 0 || ppm > PPM_PER_UNIT) throw new Error("invalid_sales_tax_input");
}

/** Basis points sent by older apps -> ppm (exact: bp * 100). */
export function bpToPpm(bp: number): number {
  if (!Number.isInteger(bp) || bp < 0 || bp > 10000) throw new Error("invalid_sales_tax_input");
  return bp * 100;
}

/** ppm -> basis points rounded half up; only for the legacy `rate_bp` field (display). */
export function ppmToLegacyBp(ppm: number): number {
  assertRatePpm(ppm);
  return Number(roundHalfUp(BigInt(ppm), 100n));
}

/** `us_sales_tax`: round_half_up(subtotal * rate_ppm, 1000000). */
export function usSalesTax(subtotalMinor: bigint | number, ratePpm: number): bigint {
  const sub = BigInt(subtotalMinor);
  if (sub < 0n) throw new Error("invalid_sales_tax_input");
  assertRatePpm(ratePpm);
  return roundHalfUp(sub * BigInt(ratePpm), BigInt(PPM_PER_UNIT));
}

/** The sales tax rate of a stored breakdown: `rate_ppm`, or a legacy row's `rate_bp` * 100. */
export function salesTaxRatePpm(breakdown: { rate_ppm?: number; rate_bp?: number }): number {
  if (typeof breakdown.rate_ppm === "number") return breakdown.rate_ppm;
  if (typeof breakdown.rate_bp === "number") return breakdown.rate_bp * 100;
  return 0;
}

export interface QuoteLineInput {
  description?: string;
  qty: number | string;
  unit_price_minor: number | bigint;
  tax_rate_bp?: number;
  hsn_sac?: string | null;
}

export type TaxBreakdown =
  | { kind: "gst"; mode: "intra" | "inter"; rate_bp: number; cgst: number; sgst: number; igst: number }
  /** rate_bp is rate_ppm rounded half up to basis points, kept for older apps (display only). */
  | { kind: "sales_tax"; rate_ppm: number; rate_bp: number; amount: number };

export interface QuoteTotals {
  subtotal_minor: number;
  tax_minor: number;
  delivery_minor: number;
  total_minor: number;
  tax_breakdown: TaxBreakdown;
}

/** Same result as public.compute_quote_totals (minus the echoed lines). */
export function computeQuoteTotals(
  country: "IN" | "US",
  lines: QuoteLineInput[],
  deliveryMinor = 0,
  salesTaxRatePpm = 0,
  intraState = true,
): QuoteTotals {
  if (!lines.length) throw new Error("line_items_required");
  if (lines.length > 50) throw new Error("too_many_line_items");
  if (deliveryMinor < 0) throw new Error("invalid_delivery_amount");
  let sub = 0n, cgst = 0n, sgst = 0n, igst = 0n, tax = 0n;
  let maxRate = 0;
  for (const l of lines) {
    const rate = country === "IN" ? (l.tax_rate_bp ?? 0) : 0;
    const r = gstLineTax(l.qty, BigInt(l.unit_price_minor), rate, intraState);
    sub += r.base_minor;
    if (country === "IN") {
      cgst += r.cgst_minor;
      sgst += r.sgst_minor;
      igst += r.igst_minor;
      tax += r.tax_minor;
      maxRate = Math.max(maxRate, rate);
    }
  }
  let breakdown: TaxBreakdown;
  if (country === "IN") {
    breakdown = {
      kind: "gst",
      mode: intraState ? "intra" : "inter",
      rate_bp: maxRate,
      cgst: Number(cgst),
      sgst: Number(sgst),
      igst: Number(igst),
    };
  } else {
    tax = usSalesTax(sub, salesTaxRatePpm);
    breakdown = {
      kind: "sales_tax",
      rate_ppm: salesTaxRatePpm,
      rate_bp: ppmToLegacyBp(salesTaxRatePpm),
      amount: Number(tax),
    };
  }
  const delivery = BigInt(deliveryMinor);
  return {
    subtotal_minor: Number(sub),
    tax_minor: Number(tax),
    delivery_minor: Number(delivery),
    total_minor: Number(sub + tax + delivery),
    tax_breakdown: breakdown,
  };
}

/** Display helper for emails / push texts (not for arithmetic). */
export function formatMinor(minor: number, currency: string, locale?: string): string {
  const loc = locale ?? (currency === "INR" ? "en-IN" : "en-US");
  return new Intl.NumberFormat(loc, { style: "currency", currency, maximumFractionDigits: 2 }).format(minor / 100);
}
