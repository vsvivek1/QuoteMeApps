// Money helpers must match the SQL (02_money.test.sql) and the Dart client on
// the shared fixtures in supabase/tests/fixtures/money_rounding_cases.json.
import { assertEquals, assertThrows } from "@std/assert";
import { computeQuoteTotals, gstLineTax, qtyToMilli, roundHalfUp, usSalesTax } from "../_shared/money.ts";

const fixtures = JSON.parse(
  await Deno.readTextFile(new URL("../../tests/fixtures/money_rounding_cases.json", import.meta.url)),
);

Deno.test("round_half_up fixtures", () => {
  for (const c of fixtures.round_half_up) {
    assertEquals(roundHalfUp(BigInt(c.n), BigInt(c.d)), BigInt(c.expected), `${c.n}/${c.d}`);
  }
});

Deno.test("round_half_up is half up, not banker's", () => {
  assertEquals(roundHalfUp(25n, 10n), 3n);
  assertEquals(roundHalfUp(35n, 10n), 4n);
  assertThrows(() => roundHalfUp(-1n, 10n));
  assertThrows(() => roundHalfUp(1n, 0n));
});

Deno.test("GST per line fixtures (intra CGST+SGST, inter IGST)", () => {
  for (const c of fixtures.gst_line) {
    const r = gstLineTax(c.qty, BigInt(c.unit_price_minor), c.rate_bp, c.intra);
    const label = `${c.qty} x ${c.unit_price_minor} @${c.rate_bp} ${c.intra ? "intra" : "inter"}`;
    assertEquals(Number(r.cgst_minor), c.cgst, `${label} cgst`);
    assertEquals(Number(r.sgst_minor), c.sgst, `${label} sgst`);
    assertEquals(Number(r.igst_minor), c.igst, `${label} igst`);
    assertEquals(Number(r.tax_minor), c.tax, `${label} tax`);
    if (c.base !== undefined) assertEquals(Number(r.base_minor), c.base, `${label} base`);
  }
});

Deno.test("required contract cases", () => {
  assertEquals(gstLineTax(1, 99999n, 1800, true).cgst_minor, 9000n);
  assertEquals(gstLineTax(1, 99999n, 1800, true).sgst_minor, 9000n);
  assertEquals(gstLineTax(1, 99999n, 1800, false).igst_minor, 18000n);
  assertEquals(gstLineTax(1, 333n, 500, true).cgst_minor, 8n);
  assertEquals(usSalesTax(1999n, 825), 165n);
  assertEquals(usSalesTax(10n, 500), 1n);
  assertEquals(usSalesTax(0n, 825), 0n);
});

Deno.test("US sales tax fixtures", () => {
  for (const c of fixtures.us_sales_tax) {
    assertEquals(Number(usSalesTax(BigInt(c.subtotal_minor), c.rate_bp)), c.expected, `${c.subtotal_minor} @${c.rate_bp}`);
  }
});

Deno.test("quote totals fixtures (total = subtotal + tax + delivery)", () => {
  for (const c of fixtures.quotes) {
    const r = computeQuoteTotals(c.country, c.lines, c.delivery_minor, c.sales_tax_rate_bp, c.intra);
    assertEquals(r.subtotal_minor, c.subtotal_minor);
    assertEquals(r.tax_minor, c.tax_minor);
    assertEquals(r.total_minor, c.total_minor);
    assertEquals(r.tax_breakdown, c.tax_breakdown);
    assertEquals(r.total_minor, r.subtotal_minor + r.tax_minor + r.delivery_minor);
  }
});

Deno.test("quantities are exact decimals and validated", () => {
  assertEquals(qtyToMilli("2.5"), 2500n);
  assertEquals(qtyToMilli(0.1), 100n);
  assertEquals(qtyToMilli("3"), 3000n);
  assertThrows(() => qtyToMilli("-1"));
  assertThrows(() => qtyToMilli("1.2345"));
  assertThrows(() => gstLineTax(0, 100n, 1800, true));
  assertThrows(() => gstLineTax(1, 100n, 10001, true));
  assertThrows(() => computeQuoteTotals("IN", []));
});
