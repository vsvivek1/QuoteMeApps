-- Money rounding helper: the same cases as the Dart tests and the Edge
-- Function tests (supabase/tests/fixtures/money_rounding_cases.json).
-- GST rates are integer basis points; US sales tax rates are integer parts per
-- million (88750 = 8.875 %); round_half_up(n, d) = (2n + d) div 2d.
begin;
\ir _helpers.psql
select plan(46);

-- round_half_up
select is(public.money_round_half_up(5, 10), 1::bigint, 'round_half_up 0.5 -> 1');
select is(public.money_round_half_up(4, 10), 0::bigint, 'round_half_up 0.4 -> 0');
select is(public.money_round_half_up(15, 10), 2::bigint, 'round_half_up 1.5 -> 2');
select is(public.money_round_half_up(25, 10), 3::bigint, 'round_half_up 2.5 -> 3 (half up, not banker''s)');
select is(public.money_round_half_up(0, 10000), 0::bigint, 'round_half_up 0 -> 0');
select throws_ok($$ select public.money_round_half_up(-1, 10) $$, 'PT400', 'invalid_money_rounding_input', 'negative input rejected');

-- India GST per line
select is((select cgst_minor from public.gst_line_tax(1, 99999, 1800, true)), 9000::bigint, 'IN intra 99999 @1800: cgst 9000 (8999.91)');
select is((select sgst_minor from public.gst_line_tax(1, 99999, 1800, true)), 9000::bigint, 'IN intra 99999 @1800: sgst 9000');
select is((select tax_minor from public.gst_line_tax(1, 99999, 1800, true)), 18000::bigint, 'IN intra 99999 @1800: tax 18000');
select is((select igst_minor from public.gst_line_tax(1, 99999, 1800, false)), 18000::bigint, 'IN inter 99999 @1800: igst 18000 (17999.82)');
select is((select cgst_minor from public.gst_line_tax(1, 333, 500, true)), 8::bigint, 'IN intra 333 @500: cgst 8 (8.325)');
select is((select igst_minor from public.gst_line_tax(1, 333, 500, false)), 17::bigint, 'IN inter 333 @500: igst 17 (16.65)');
select is((select cgst_minor from public.gst_line_tax(1, 1010, 500, true)), 25::bigint, 'IN intra 1010 @500: cgst 25 (25.25)');
select is((select igst_minor from public.gst_line_tax(1, 1010, 500, false)), 51::bigint, 'IN inter 1010 @500: igst 51 (50.5 half up)');
select is((select tax_minor from public.gst_line_tax(1, 4125, 1200, true)), 496::bigint, 'IN intra 4125 @1200: 248 + 248 (247.5 half up each)');
select is((select tax_minor from public.gst_line_tax(3, 129900, 2800, true)), 109116::bigint, 'IN intra 3 x 129900 @2800: 54558 x 2');
select is((select tax_minor from public.gst_line_tax(1, 1, 1800, false)), 0::bigint, 'IN inter 1 paisa @1800 -> 0');
select is((select tax_minor from public.gst_line_tax(1, 0, 1800, true)), 0::bigint, 'IN zero amount -> 0');

-- USA sales tax on the subtotal, rate in ppm (fixtures: us_sales_tax)
select is(public.us_sales_tax(1999, 82500), 165::bigint, 'US 1999 @82500 ppm -> 165 (164.9175)');
select is(public.us_sales_tax(10, 50000), 1::bigint, 'US 10 @50000 ppm -> 1 (0.5 rounds up)');
select is(public.us_sales_tax(0, 82500), 0::bigint, 'US 0 -> 0');
select is(public.us_sales_tax(1000, 0), 0::bigint, 'US 0 % -> 0');
select is(public.us_sales_tax(200, 102500), 21::bigint, 'US 200 @102500 ppm -> 21 (20.5 half up)');
select is(public.us_sales_tax(10000, 88750), 888::bigint, 'US 10000 @8.875 % -> 888 (887.5 half up)');
select is(public.us_sales_tax(1999, 88750), 177::bigint, 'US 1999 @8.875 % -> 177 (177.41125)');
select is(public.us_sales_tax(249900, 88750), 22179::bigint, 'US 249900 @8.875 % -> 22179 (22178.625)');
select is(public.us_sales_tax(12345, 88750), 1096::bigint, 'US 12345 @8.875 % -> 1096 (1095.61875)');
select is(public.us_sales_tax(8, 62500), 1::bigint, 'US 8 @6.25 % -> 1 (0.5 half up)');
select is(public.us_sales_tax(100, 1), 0::bigint, 'US 100 @1 ppm -> 0');
select is(public.us_sales_tax(500000, 1), 1::bigint, 'US 500000 @1 ppm -> 1 (0.5 half up)');
select is(public.us_sales_tax(999, 1000000), 999::bigint, 'US 999 @100 % -> 999');
select throws_ok($$ select public.us_sales_tax(100, 1000001) $$, 'PT400', 'invalid_sales_tax_input', 'rate above 100 % rejected');
select throws_ok($$ select public.us_sales_tax(100, -1) $$, 'PT400', 'invalid_sales_tax_input', 'negative rate rejected');

-- older apps: basis points, converted exactly (ppm = bp * 100) (fixtures: us_sales_tax_legacy_bp)
select is(public.us_sales_tax(1999, p_rate_bp => 825), 165::bigint, 'legacy bp: 1999 @825 -> 165');
select is(public.us_sales_tax(200, p_rate_bp => 1025), 21::bigint, 'legacy bp: 200 @1025 -> 21');
select is(public.us_sales_tax(10, p_rate_bp => 500), 1::bigint, 'legacy bp: 10 @500 -> 1');
select throws_ok($$ select public.us_sales_tax(100, p_rate_ppm => 88750, p_rate_bp => 888) $$, 'PT400',
  'invalid_sales_tax_input', 'bp and ppm that disagree are rejected');

-- full quote computation
select is(
  public.compute_quote_totals('IN',
    '[{"description":"A","qty":1,"unit_price_minor":99999,"tax_rate_bp":1800},
      {"description":"B","qty":1,"unit_price_minor":333,"tax_rate_bp":500}]', 5000, 0, true) -> 'tax_breakdown',
  '{"kind":"gst","mode":"intra","rate_bp":1800,"cgst":9008,"sgst":9008,"igst":0}'::jsonb,
  'IN quote breakdown sums per-line CGST/SGST');
select is(
  (public.compute_quote_totals('IN', '[{"qty":1,"unit_price_minor":99999,"tax_rate_bp":1800}]', 5000, 0, false) ->> 'total_minor')::bigint,
  122999::bigint, 'IN total = subtotal + tax + delivery (delivery untaxed)');
select is(
  public.compute_quote_totals('US', '[{"qty":1,"unit_price_minor":1999}]', 500, p_sales_tax_rate_ppm => 82500) - 'lines',
  '{"subtotal_minor":1999,"tax_minor":165,"delivery_minor":500,"total_minor":2664,
    "tax_breakdown":{"kind":"sales_tax","rate_ppm":82500,"rate_bp":825,"amount":165}}'::jsonb,
  'US quote: sales tax on subtotal only');
select is(
  public.compute_quote_totals('US', '[{"qty":1,"unit_price_minor":249900}]', 2500, p_sales_tax_rate_ppm => 88750) - 'lines',
  '{"subtotal_minor":249900,"tax_minor":22179,"delivery_minor":2500,"total_minor":274579,
    "tax_breakdown":{"kind":"sales_tax","rate_ppm":88750,"rate_bp":888,"amount":22179}}'::jsonb,
  'US quote at NYC 8.875 % (88750 ppm)');
select is(
  public.compute_quote_totals('US', '[{"qty":2,"unit_price_minor":4999},{"qty":"1.5","unit_price_minor":333}]', 0,
    p_sales_tax_rate_ppm => 88750) - 'lines',
  '{"subtotal_minor":10498,"tax_minor":932,"delivery_minor":0,"total_minor":11430,
    "tax_breakdown":{"kind":"sales_tax","rate_ppm":88750,"rate_bp":888,"amount":932}}'::jsonb,
  'US quote with a fractional quantity at 8.875 %');
select is(
  public.compute_quote_totals('US', '[{"qty":1,"unit_price_minor":1999}]', 500, 825, true) -> 'tax_breakdown',
  '{"kind":"sales_tax","rate_ppm":82500,"rate_bp":825,"amount":165}'::jsonb,
  'older apps: positional p_sales_tax_rate_bp 825 is 82500 ppm');
select is(
  public.compute_quote_totals('US', '[{"qty":1,"unit_price_minor":1999}]') -> 'tax_breakdown',
  '{"kind":"sales_tax","rate_ppm":0,"rate_bp":0,"amount":0}'::jsonb,
  'no rate means 0 %');
select throws_ok($$ select public.compute_quote_totals('US', '[{"qty":1,"unit_price_minor":1}]', 0, 888, true, 88750) $$,
  'PT400', 'invalid_sales_tax_input', 'compute_quote_totals rejects bp and ppm that disagree');
select throws_ok($$ select public.compute_quote_totals('IN', '[]', 0, 0, true) $$, 'PT400', 'line_items_required',
  'empty line items rejected');

select * from finish();
rollback;
