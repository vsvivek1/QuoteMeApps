-- I Want India demo data: Bengaluru, Mumbai, Delhi (5 buyers, 20 sellers,
-- 30 requests with quotes each) + dev test accounts + review accounts.
-- Requires seed.sql, seed/india.sql and seed/demo_generator.sql.
-- Test phones are fictional (+91 0…, an invalid mobile range) and must match
-- [auth.sms.test_otp] in supabase/config.toml.

truncate seed_tools.demo_templates;
insert into seed_tools.demo_templates (slug, title, description, fields, budget_min, budget_max, unit_min, unit_max, tax_rate_bp, brands) values
  ('refrigerators', 'Samsung 300L double-door refrigerator', 'Need delivery and installation, exchange my old single-door fridge.',
   '{"door_type":"double","capacity_l":300,"brand_preference":["samsung"],"energy_rating":"3","exchange_old":true,"quantity":1}',
   2500000, 3500000, 2600000, 3400000, 1800, array['Samsung RT34C','LG GL-T302','Whirlpool IF 305']),
  ('air-conditioners', '1.5 ton inverter split AC x2', 'Two bedrooms, copper piping, installation included please.',
   '{"tonnage":"1.5","ac_type":"split_inverter","units":2,"installation":true,"energy_rating":"5"}',
   7000000, 9000000, 3200000, 4200000, 1800, array['Voltas 183V','Daikin FTKF50','LG RS-Q19']),
  ('washing-machines', 'Front-load washing machine 7 kg', 'Fully automatic, inbuilt heater preferred.',
   '{"load_type":"front","capacity_kg":7,"brand_preference":["lg","ifb"]}',
   2500000, 3500000, 2400000, 3500000, 1800, array['IFB Senator 7kg','LG FHM1207','Bosch Series 4']),
  ('televisions', '55 inch 4K smart TV', 'Wall mount needed. Google TV preferred.',
   '{"screen_in":55,"panel":"led","installation":true}',
   3500000, 5500000, 3500000, 5500000, 1800, array['Sony Bravia 55X75L','Samsung Crystal 55','TCL 55P745']),
  ('water-purifiers', 'RO + UV water purifier', 'Borewell water, TDS around 900.',
   '{"technology":"ro_uv","water_source":"borewell","installation":true}',
   1200000, 2000000, 1200000, 2000000, 1800, array['Kent Grand+','Aquaguard Aura','Livpure Glo']),
  ('ac-repair', 'AC service for 2 split units', 'Cooling is low, need general service and gas check.',
   '{"units":2,"service_type":"service","ac_type":"split"}',
   100000, 250000, 50000, 90000, 1800, array[]::text[]),
  ('plumbing', 'Plumber for kitchen sink leak', null,
   '{"problem":"Kitchen sink leaking and one bathroom tap to replace"}',
   null, null, 30000, 120000, 1800, array[]::text[]),
  ('cleaning', '2BHK full home deep cleaning', 'Moving in next week, need full deep clean incl. kitchen.',
   '{"property_type":"2bhk","cleaning_type":"deep"}',
   300000, 600000, 300000, 650000, 1800, array[]::text[]),
  ('packers-movers', 'Packers and movers for 2BHK shifting', 'Intercity move, 3rd floor with lift.',
   '{"to_pin":"411001","property_type":"2bhk","floor":3,"lift":true}',
   1500000, 3000000, 1200000, 2500000, 1800, array[]::text[]),
  ('catering', 'Veg catering for 150 guests', 'Housewarming lunch, South Indian menu.',
   jsonb_build_object('guests', 150, 'event_date', (current_date + 20)::text, 'food_pref', 'veg', 'cuisines', jsonb_build_array('south_indian')),
   5000000, 9000000, 5000000, 9000000, 500, array[]::text[]),
  ('printing', '100 printed T-shirts', 'Company logo on front, sizes M/L/XL mixed.',
   '{"item":"tshirts","quantity":100,"size":"M/L/XL mixed"}',
   2000000, 3500000, 18000, 35000, 500, array[]::text[]),
  ('laptops', '5 office laptops, 16 GB RAM', 'For a small office, GST invoice needed.',
   '{"use":"office","ram_gb":"16","quantity":5,"brand_preference":["dell","hp","lenovo"]}',
   27500000, 37500000, 5500000, 7500000, 1800, array['Dell Vostro 3520','HP 250 G10','Lenovo V15 G4']),
  ('sofas', '3-seater fabric sofa', 'Grey or beige, sturdy wooden frame.',
   '{"seats":3,"material":"fabric"}',
   2500000, 6000000, 2500000, 6000000, 1800, array[]::text[]),
  ('property-rent', 'Looking for a 2BHK on rent', 'Near metro, semi-furnished, family.',
   '{"property_type":"2bhk"}',
   3000000, 4500000, 2500000, 4000000, 1800, array[]::text[]);

-- Dev test accounts in the first city: buyer / seller / verified seller via
-- generate_city, admin separately.
select seed_tools.generate_city('blr', 'Bengaluru', 'Karnataka', '29', 12.9716, 77.5946,
  array['560001','560011','560034','560038','560066','560076'], 'Maharashtra', 0,
  '{"buyer":"910000000001","seller":"910000000002","verified_seller":"910000000003"}');
select seed_tools.generate_city('bom', 'Mumbai', 'Maharashtra', '27', 19.0760, 72.8777,
  array['400001','400050','400053','400070','400076','400092'], 'Gujarat', 0);
select seed_tools.generate_city('del', 'New Delhi', 'Delhi', '07', 28.6139, 77.2090,
  array['110001','110016','110019','110024','110075','110085','110092'], 'Haryana', 0);
select seed_tools.create_test_admin('910000000004');
select seed_tools.generate_review_data('910000000005', '910000000006', 12.9352, 77.6245, '560034', 0);
