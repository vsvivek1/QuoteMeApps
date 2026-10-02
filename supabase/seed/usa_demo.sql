-- I Want USA demo data: New York and Dallas (5 buyers, 20 sellers,
-- 30 requests with quotes each) + dev test accounts + review accounts.
-- Requires seed.sql, seed/usa.sql and seed/demo_generator.sql.
-- Test phones use the fictional 555-01xx range and must match
-- [auth.sms.test_otp] in supabase/config.toml.
-- Sales tax (basis points): Dallas 8.25 % = 825. NYC is 8.875 %, which is not
-- an integer number of basis points (see API.md "Money"); the demo uses 888.

truncate seed_tools.demo_templates;
insert into seed_tools.demo_templates (slug, title, description, fields, budget_min, budget_max, unit_min, unit_max, tax_rate_bp, brands) values
  ('refrigerators', 'French-door refrigerator, 26 cu ft', 'Delivery, install and haul-away of the old fridge.',
   '{"door_type":"french","capacity_cuft":26,"brand_preference":["samsung","lg"],"haul_away":true,"energy_star":true}',
   180000, 260000, 179900, 249900, 0, array['Samsung RF26','LG LRFXS2503S','Whirlpool WRF555']),
  ('washers-dryers', 'Front-load washer and dryer pair', 'Stackable preferred, electric dryer.',
   '{"unit_type":"pair","fuel":"electric"}',
   140000, 220000, 140000, 220000, 0, array['LG WM3400 + DLE3400','Samsung WF45 + DVE45','Maytag MHW5630']),
  ('televisions', '65 inch OLED TV with wall mounting', 'Living room, drywall with studs.',
   '{"screen_in":65,"panel":"oled","wall_mount":true}',
   150000, 260000, 150000, 260000, 0, array['LG C3 65"','Sony A80L 65"','Samsung S90C 65"']),
  ('hvac', 'Replace central AC unit (3 ton)', '15-year-old unit, not cooling. Need quote for replacement.',
   '{"units":1,"service_type":"replace"}',
   450000, 850000, 450000, 850000, 0, array['Trane XR14','Carrier Comfort 14','Lennox ML14XC1']),
  ('plumbing', 'Plumber for leaking water heater', null,
   '{"problem":"Water heater tank leaking at the base, 40 gallon gas"}',
   null, null, 25000, 180000, 0, array[]::text[]),
  ('handyman', 'Handyman: TV mount + furniture assembly', 'Mount a 65 inch TV and assemble two bookshelves.',
   '{"problem":"Mount a 65 inch TV and assemble 2 bookshelves","hours_estimate":3}',
   15000, 40000, 15000, 40000, 0, array[]::text[]),
  ('cleaning', 'Deep clean 2-bedroom apartment', 'Move-in clean, includes inside oven and fridge.',
   '{"property_type":"apartment","bedrooms":2,"frequency":"once"}',
   15000, 35000, 15000, 35000, 0, array[]::text[]),
  ('moving', '1-bedroom local move', 'Third floor walk-up, about 40 boxes plus a sofa and bed.',
   '{"to_zip":"10025","property_type":"apartment","bedrooms":1}',
   60000, 150000, 60000, 150000, 0, array[]::text[]),
  ('catering', 'Catering for 60 guests', 'Office party, buffet, some vegetarian options.',
   jsonb_build_object('guests', 60, 'event_date', (current_date + 21)::text, 'service_style', 'buffet'),
   180000, 420000, 180000, 420000, 0, array[]::text[]),
  ('printing', '100 custom printed T-shirts', 'One-color logo front, sizes S-XL.',
   '{"item":"tshirts","quantity":100,"size":"S-XL"}',
   90000, 160000, 900, 1600, 0, array[]::text[]),
  ('laptops', '3 business laptops, 16 GB RAM', 'Windows 11 Pro, 3-year warranty preferred.',
   '{"use":"office","ram_gb":"16","quantity":3,"brand_preference":["dell","lenovo"]}',
   270000, 450000, 89900, 149900, 0, array['Dell Latitude 5450','Lenovo ThinkPad E14','HP ProBook 450']);

select seed_tools.generate_city('nyc', 'New York', 'New York', null, 40.7128, -74.0060,
  array['10001','10011','10016','10025','11201','11215','11101'], 'New Jersey', 888,
  '{"buyer":"15555550100","seller":"15555550101","verified_seller":"15555550102"}');
select seed_tools.generate_city('dfw', 'Dallas', 'Texas', null, 32.7767, -96.7970,
  array['75201','75204','75205','75206','75214','75219','75230'], 'Oklahoma', 825);
select seed_tools.create_test_admin('15555550103');
select seed_tools.generate_review_data('15555550104', '15555550105', 32.7876, -96.7994, '75201', 825);
