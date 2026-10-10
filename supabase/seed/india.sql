-- =============================================================================
-- I Want India: country settings, two-level category tree (en + hi),
-- field schemas, category policy (Section 3.1), blocked-keyword classifier,
-- demo-city postal codes and the priority metro list.
-- Requires seed.sql first. Safe to re-run (upserts).
-- POLICY IS A STARTING POINT ONLY: a lawyer must confirm before launch.
-- =============================================================================

update public.app_settings set value = '"IN"' where key = 'country';
update public.app_settings set value = '"INR"' where key = 'currency';
update public.app_settings set value = '"Asia/Kolkata"' where key = 'default_timezone';
update public.app_settings set value = '10' where key = 'free_quotes_per_month';
update public.app_settings set value = '["en","hi"]' where key = 'languages';
update public.app_settings set value = '249900' where key = 'onboarding_fee_minor';

-- Shared option sets ---------------------------------------------------------------
create or replace function seed_tools.in_energy() returns jsonb language sql stable as $$
  select seed_tools.field('energy_rating', 'select', seed_tools.l('Energy rating (BEE)', 'ऊर्जा रेटिंग (BEE)'), false, 'both',
    array[seed_tools.opt('3', '3 star', '3 स्टार'), seed_tools.opt('4', '4 star', '4 स्टार'),
          seed_tools.opt('5', '5 star', '5 स्टार'), seed_tools.opt('any', 'Any', 'कोई भी')]) $$;
create or replace function seed_tools.in_bis() returns jsonb language sql stable as $$
  select seed_tools.field('bis_isi_mark', 'boolean', seed_tools.l('BIS / ISI certified', 'BIS / ISI प्रमाणित'), true, 'quote') $$;
create or replace function seed_tools.in_qty() returns jsonb language sql stable as $$
  select seed_tools.field('quantity', 'number', seed_tools.l('Quantity', 'मात्रा'), false, 'request', null, '{"min":1,"max":10000,"default":1}') $$;
create or replace function seed_tools.in_install() returns jsonb language sql stable as $$
  select seed_tools.field('installation', 'boolean', seed_tools.l('Installation needed', 'इंस्टॉलेशन चाहिए')) $$;
create or replace function seed_tools.in_exchange() returns jsonb language sql stable as $$
  select seed_tools.field('exchange_old', 'boolean', seed_tools.l('Exchange my old one', 'पुराना बदलना है')) $$;
create or replace function seed_tools.in_brands(variadic p text[]) returns jsonb language sql stable as $$
  select seed_tools.field('brand_preference', 'multiselect', seed_tools.l('Preferred brands', 'पसंदीदा ब्रांड'), false, 'request',
    array(select seed_tools.opt(lower(regexp_replace(b, '[^A-Za-z0-9]+', '_', 'g')), b, b) from unnest(p) b)
      || array[seed_tools.opt('any', 'Any brand', 'कोई भी ब्रांड')]) $$;
create or replace function seed_tools.in_problem(p_required boolean default true) returns jsonb language sql stable as $$
  select seed_tools.field('problem', 'text', seed_tools.l('Describe the problem', 'समस्या बताइए'), p_required, 'request', null, '{"multiline":true}') $$;
create or replace function seed_tools.in_units() returns jsonb language sql stable as $$
  select seed_tools.field('units', 'number', seed_tools.l('Number of units', 'यूनिट की संख्या'), true, 'request', null, '{"min":1,"max":50,"default":1}') $$;
create or replace function seed_tools.in_property() returns jsonb language sql stable as $$
  select seed_tools.field('property_type', 'select', seed_tools.l('Property type', 'प्रॉपर्टी का प्रकार'), false, 'request',
    array[seed_tools.opt('1rk', '1 RK', '1 RK'), seed_tools.opt('1bhk', '1 BHK', '1 BHK'), seed_tools.opt('2bhk', '2 BHK', '2 BHK'),
          seed_tools.opt('3bhk', '3 BHK', '3 BHK'), seed_tools.opt('4bhk_plus', '4+ BHK / villa', '4+ BHK / विला'),
          seed_tools.opt('office', 'Office / shop', 'ऑफिस / दुकान')]) $$;
create or replace function seed_tools.in_area() returns jsonb language sql stable as $$
  select seed_tools.field('area_sqft', 'number', seed_tools.l('Area (sq ft)', 'क्षेत्रफल (वर्ग फुट)'), false, 'request', null, '{"min":50,"max":100000}') $$;
create or replace function seed_tools.in_event_date() returns jsonb language sql stable as $$
  select seed_tools.field('event_date', 'date', seed_tools.l('Event date', 'कार्यक्रम की तारीख'), true) $$;
create or replace function seed_tools.in_guests() returns jsonb language sql stable as $$
  select seed_tools.field('guests', 'number', seed_tools.l('Number of guests', 'मेहमानों की संख्या'), true, 'request', null, '{"min":1,"max":20000}') $$;

-- Roots ------------------------------------------------------------------------------------------------
select seed_tools.cat('appliances', null, seed_tools.l('Appliances', 'घरेलू उपकरण'), p_icon => 'kitchen', p_sort => 10);
select seed_tools.cat('electronics', null, seed_tools.l('Electronics', 'इलेक्ट्रॉनिक्स'), p_icon => 'devices', p_sort => 20);
select seed_tools.cat('furniture-home', null, seed_tools.l('Furniture and home', 'फ़र्नीचर और घर'), p_icon => 'chair', p_sort => 30);
select seed_tools.cat('home-services', null, seed_tools.l('Home services', 'घरेलू सेवाएँ'), p_icon => 'home_repair_service', p_sort => 40);
select seed_tools.cat('vehicles', null, seed_tools.l('Vehicles', 'वाहन'), p_icon => 'directions_car', p_sort => 50);
select seed_tools.cat('events', null, seed_tools.l('Events', 'कार्यक्रम'), p_icon => 'celebration', p_sort => 60);
select seed_tools.cat('business-supplies', null, seed_tools.l('Business supplies', 'व्यापार सामग्री'), p_icon => 'inventory_2', p_sort => 70);
select seed_tools.cat('real-estate', null, seed_tools.l('Property (rent / buy)', 'प्रॉपर्टी (किराया / खरीद)'), 'restricted', 'rera_registration',
  p_icon => 'apartment', p_sort => 80,
  p_disclaimer => seed_tools.l('Only RERA-registered agents and projects can quote. The RERA registration number is shown on every quote.',
                               'केवल RERA-पंजीकृत एजेंट और प्रोजेक्ट ही कोटेशन दे सकते हैं। हर कोटेशन पर RERA पंजीकरण संख्या दिखाई जाती है।'));
select seed_tools.cat('health', null, seed_tools.l('Doctors and clinics', 'डॉक्टर और क्लिनिक'), 'restricted', 'nmc_registration',
  p_icon => 'medical_services', p_sort => 90,
  p_disclaimer => seed_tools.l('Only practitioners registered with the NMC or a State Medical Council can quote. This is not medical advice.',
                               'केवल NMC या राज्य चिकित्सा परिषद में पंजीकृत डॉक्टर ही कोटेशन दे सकते हैं। यह चिकित्सा सलाह नहीं है।'));
select seed_tools.cat('insurance', null, seed_tools.l('Insurance', 'बीमा'), 'blocked', 'irdai_registration',
  p_icon => 'shield', p_sort => 100,
  p_disclaimer => seed_tools.l('Insurance is the subject matter of solicitation. Quotes only from IRDAI-registered insurers, brokers, corporate agents or web aggregators; IRDAI registration number shown.',
                               'बीमा आग्रह की विषय वस्तु है। केवल IRDAI-पंजीकृत बीमाकर्ता, ब्रोकर, कॉर्पोरेट एजेंट या वेब एग्रीगेटर ही कोटेशन दे सकते हैं।'),
  p_policy_reason => seed_tools.l('Insurance quotes are not available in I Want India yet.', 'I Want India में अभी बीमा कोटेशन उपलब्ध नहीं हैं।'));
select seed_tools.cat('finance', null, seed_tools.l('Loans, credit and investments', 'लोन, क्रेडिट और निवेश'), 'blocked',
  p_icon => 'account_balance', p_sort => 110,
  p_policy_reason => seed_tools.l('Loans, credit cards and investment products cannot be requested in this app (RBI digital lending and SEBI rules).',
                                  'इस ऐप में लोन, क्रेडिट कार्ड और निवेश उत्पाद नहीं माँगे जा सकते (RBI डिजिटल लेंडिंग और SEBI नियम)।'));
select seed_tools.cat('legal-services', null, seed_tools.l('Legal services', 'कानूनी सेवाएँ'), 'blocked',
  p_icon => 'gavel', p_sort => 120,
  p_policy_reason => seed_tools.l('Bar Council of India rules restrict advocates from soliciting work, so legal services are not available.',
                                  'बार काउंसिल ऑफ इंडिया के नियमों के कारण कानूनी सेवाएँ उपलब्ध नहीं हैं।'));
select seed_tools.cat('pharmacy', null, seed_tools.l('Medicines and pharmacy', 'दवाइयाँ और फ़ार्मेसी'), 'blocked',
  p_icon => 'medication', p_sort => 130,
  p_policy_reason => seed_tools.l('Medicines cannot be requested in this app.', 'इस ऐप में दवाइयाँ नहीं माँगी जा सकतीं।'));
select seed_tools.cat('alcohol-tobacco', null, seed_tools.l('Alcohol, tobacco and vapes', 'शराब, तंबाकू और वेप'), 'blocked',
  p_icon => 'no_drinks', p_sort => 140,
  p_policy_reason => seed_tools.l('Alcohol, tobacco and vapes cannot be requested in this app.', 'इस ऐप में शराब, तंबाकू और वेप नहीं माँगे जा सकते।'));
select seed_tools.cat('weapons', null, seed_tools.l('Firearms and weapons', 'हथियार'), 'blocked',
  p_icon => 'block', p_sort => 150,
  p_policy_reason => seed_tools.l('Firearms, ammunition and weapons cannot be requested.', 'हथियार और गोला-बारूद नहीं माँगे जा सकते।'));
select seed_tools.cat('other', null, seed_tools.l('Something else', 'कुछ और'), p_icon => 'more_horiz', p_sort => 999,
  p_keywords => array['other','anything']);

-- Appliances ---------------------------------------------------------------------------------------------
select seed_tools.cat('refrigerators', 'appliances', seed_tools.l('Refrigerators', 'रेफ्रिजरेटर'),
  p_keywords => array['fridge','refrigerator','freezer','फ्रिज','रेफ्रिजरेटर'], p_icon => 'kitchen', p_sort => 1,
  p_field_schema => seed_tools.schema(
    seed_tools.field('capacity_l', 'number', seed_tools.l('Capacity (litres)', 'क्षमता (लीटर)'), false, 'both', null, '{"min":50,"max":1200,"unit":"L"}'),
    seed_tools.field('door_type', 'select', seed_tools.l('Door type', 'दरवाज़े का प्रकार'), true, 'both',
      array[seed_tools.opt('single', 'Single door', 'सिंगल डोर'), seed_tools.opt('double', 'Double door', 'डबल डोर'),
            seed_tools.opt('triple', 'Triple door', 'ट्रिपल डोर'), seed_tools.opt('side_by_side', 'Side by side', 'साइड बाय साइड'),
            seed_tools.opt('french', 'French door', 'फ्रेंच डोर')]),
    seed_tools.in_brands('Samsung', 'LG', 'Whirlpool', 'Godrej', 'Haier', 'Bosch'),
    seed_tools.in_energy(), seed_tools.in_exchange(), seed_tools.in_qty(), seed_tools.in_bis()));
select seed_tools.cat('washing-machines', 'appliances', seed_tools.l('Washing machines', 'वॉशिंग मशीन'),
  p_keywords => array['washing machine','washer','वॉशिंग मशीन'], p_icon => 'local_laundry_service', p_sort => 2,
  p_field_schema => seed_tools.schema(
    seed_tools.field('capacity_kg', 'number', seed_tools.l('Capacity (kg)', 'क्षमता (किलो)'), false, 'both', null, '{"min":4,"max":20,"unit":"kg"}'),
    seed_tools.field('load_type', 'select', seed_tools.l('Type', 'प्रकार'), true, 'both',
      array[seed_tools.opt('front', 'Front load', 'फ्रंट लोड'), seed_tools.opt('top', 'Top load', 'टॉप लोड'),
            seed_tools.opt('semi', 'Semi-automatic', 'सेमी-ऑटोमैटिक')]),
    seed_tools.in_brands('LG', 'Samsung', 'IFB', 'Whirlpool', 'Bosch'), seed_tools.in_energy(), seed_tools.in_exchange(), seed_tools.in_bis()));
select seed_tools.cat('air-conditioners', 'appliances', seed_tools.l('Air conditioners', 'एयर कंडीशनर'),
  p_keywords => array['ac','air conditioner','split ac','window ac','एसी'], p_icon => 'ac_unit', p_sort => 3,
  p_field_schema => seed_tools.schema(
    seed_tools.field('tonnage', 'select', seed_tools.l('Capacity (ton)', 'क्षमता (टन)'), true, 'both',
      array[seed_tools.opt('0.75', '0.75 ton', '0.75 टन'), seed_tools.opt('1', '1 ton', '1 टन'),
            seed_tools.opt('1.5', '1.5 ton', '1.5 टन'), seed_tools.opt('2', '2 ton', '2 टन')]),
    seed_tools.field('ac_type', 'select', seed_tools.l('Type', 'प्रकार'), true, 'both',
      array[seed_tools.opt('split_inverter', 'Inverter split', 'इन्वर्टर स्प्लिट'), seed_tools.opt('split', 'Split', 'स्प्लिट'),
            seed_tools.opt('window', 'Window', 'विंडो')]),
    seed_tools.in_units(), seed_tools.in_brands('Voltas', 'LG', 'Daikin', 'Blue Star', 'Samsung', 'Lloyd'),
    seed_tools.in_energy(), seed_tools.in_install(), seed_tools.in_bis()));
select seed_tools.cat('televisions', 'appliances', seed_tools.l('Televisions', 'टेलीविज़न'),
  p_keywords => array['tv','television','smart tv','टीवी'], p_icon => 'tv', p_sort => 4,
  p_field_schema => seed_tools.schema(
    seed_tools.field('screen_in', 'number', seed_tools.l('Screen size (inches)', 'स्क्रीन (इंच)'), true, 'both', null, '{"min":19,"max":100,"unit":"in"}'),
    seed_tools.field('panel', 'select', seed_tools.l('Panel', 'पैनल'), false, 'both',
      array[seed_tools.opt('led', 'LED', 'LED'), seed_tools.opt('qled', 'QLED', 'QLED'), seed_tools.opt('oled', 'OLED', 'OLED')]),
    seed_tools.in_brands('Sony', 'Samsung', 'LG', 'Mi', 'TCL'), seed_tools.in_install(), seed_tools.in_bis()));
select seed_tools.cat('microwaves', 'appliances', seed_tools.l('Microwave ovens', 'माइक्रोवेव ओवन'),
  p_keywords => array['microwave','oven','ओवन'], p_icon => 'microwave', p_sort => 5,
  p_field_schema => seed_tools.schema(
    seed_tools.field('capacity_l', 'number', seed_tools.l('Capacity (litres)', 'क्षमता (लीटर)'), false, 'both', null, '{"min":10,"max":60,"unit":"L"}'),
    seed_tools.field('mw_type', 'select', seed_tools.l('Type', 'प्रकार'), true, 'both',
      array[seed_tools.opt('solo', 'Solo', 'सोलो'), seed_tools.opt('grill', 'Grill', 'ग्रिल'), seed_tools.opt('convection', 'Convection', 'कन्वेक्शन')]),
    seed_tools.in_brands('LG', 'Samsung', 'IFB', 'Panasonic'), seed_tools.in_bis()));
select seed_tools.cat('water-purifiers', 'appliances', seed_tools.l('Water purifiers', 'वॉटर प्यूरीफायर'),
  p_keywords => array['water purifier','ro','aquaguard','purifier','वॉटर प्यूरीफायर'], p_icon => 'water_drop', p_sort => 6,
  p_field_schema => seed_tools.schema(
    seed_tools.field('technology', 'select', seed_tools.l('Technology', 'तकनीक'), true, 'both',
      array[seed_tools.opt('ro', 'RO', 'RO'), seed_tools.opt('ro_uv', 'RO + UV', 'RO + UV'), seed_tools.opt('uv', 'UV', 'UV'), seed_tools.opt('uf', 'UF / gravity', 'UF / ग्रैविटी')]),
    seed_tools.field('water_source', 'select', seed_tools.l('Water source', 'पानी का स्रोत'), false, 'request',
      array[seed_tools.opt('municipal', 'Municipal', 'नगर निगम'), seed_tools.opt('borewell', 'Borewell', 'बोरवेल'), seed_tools.opt('tanker', 'Tanker', 'टैंकर')]),
    seed_tools.in_brands('Kent', 'Aquaguard', 'Livpure', 'Pureit'), seed_tools.in_install(), seed_tools.in_bis()));
select seed_tools.cat('dishwashers', 'appliances', seed_tools.l('Dishwashers', 'डिशवॉशर'),
  p_keywords => array['dishwasher','डिशवॉशर'], p_icon => 'countertops', p_sort => 7,
  p_field_schema => seed_tools.schema(
    seed_tools.field('place_settings', 'number', seed_tools.l('Place settings', 'प्लेस सेटिंग'), false, 'both', null, '{"min":4,"max":16}'),
    seed_tools.field('dw_type', 'select', seed_tools.l('Type', 'प्रकार'), false, 'both',
      array[seed_tools.opt('freestanding', 'Freestanding', 'फ्रीस्टैंडिंग'), seed_tools.opt('built_in', 'Built-in', 'बिल्ट-इन')]),
    seed_tools.in_brands('Bosch', 'IFB', 'LG', 'Faber'), seed_tools.in_install()));
select seed_tools.cat('inverters', 'appliances', seed_tools.l('Inverters and batteries', 'इन्वर्टर और बैटरी'),
  p_keywords => array['inverter','ups','battery','इन्वर्टर'], p_icon => 'battery_charging_full', p_sort => 8,
  p_field_schema => seed_tools.schema(
    seed_tools.field('capacity_va', 'number', seed_tools.l('Capacity (VA)', 'क्षमता (VA)'), false, 'both', null, '{"min":300,"max":10000,"unit":"VA"}'),
    seed_tools.field('battery_ah', 'number', seed_tools.l('Battery (Ah)', 'बैटरी (Ah)'), false, 'both', null, '{"min":40,"max":300,"unit":"Ah"}'),
    seed_tools.field('backup_hours', 'number', seed_tools.l('Backup needed (hours)', 'बैकअप (घंटे)'), false, 'request', null, '{"min":1,"max":24}'),
    seed_tools.in_brands('Luminous', 'Microtek', 'Exide', 'Amaron'), seed_tools.in_install()));

-- Electronics -------------------------------------------------------------------------------------------
select seed_tools.cat('phones', 'electronics', seed_tools.l('Mobile phones', 'मोबाइल फ़ोन'),
  p_keywords => array['phone','mobile','smartphone','iphone','मोबाइल'], p_icon => 'smartphone', p_sort => 1,
  p_field_schema => seed_tools.schema(
    seed_tools.field('model', 'text', seed_tools.l('Model wanted', 'मॉडल'), false, 'both'),
    seed_tools.field('storage_gb', 'select', seed_tools.l('Storage', 'स्टोरेज'), false, 'both',
      array[seed_tools.opt('64', '64 GB', '64 GB'), seed_tools.opt('128', '128 GB', '128 GB'), seed_tools.opt('256', '256 GB', '256 GB'), seed_tools.opt('512', '512 GB+', '512 GB+')]),
    seed_tools.in_brands('Apple', 'Samsung', 'OnePlus', 'Xiaomi', 'Vivo', 'Oppo'), seed_tools.in_qty()));
select seed_tools.cat('laptops', 'electronics', seed_tools.l('Laptops', 'लैपटॉप'),
  p_keywords => array['laptop','notebook','macbook','लैपटॉप'], p_icon => 'laptop', p_sort => 2,
  p_field_schema => seed_tools.schema(
    seed_tools.field('use', 'select', seed_tools.l('Main use', 'मुख्य उपयोग'), false, 'request',
      array[seed_tools.opt('office', 'Office / study', 'ऑफिस / पढ़ाई'), seed_tools.opt('gaming', 'Gaming', 'गेमिंग'), seed_tools.opt('design', 'Design / video', 'डिज़ाइन / वीडियो')]),
    seed_tools.field('ram_gb', 'select', seed_tools.l('RAM', 'RAM'), false, 'both',
      array[seed_tools.opt('8', '8 GB', '8 GB'), seed_tools.opt('16', '16 GB', '16 GB'), seed_tools.opt('32', '32 GB+', '32 GB+')]),
    seed_tools.in_brands('HP', 'Dell', 'Lenovo', 'Asus', 'Apple', 'Acer'), seed_tools.in_qty()));
select seed_tools.cat('cameras', 'electronics', seed_tools.l('Cameras and CCTV', 'कैमरा और CCTV'),
  p_keywords => array['camera','dslr','cctv','कैमरा'], p_icon => 'photo_camera', p_sort => 3,
  p_field_schema => seed_tools.schema(
    seed_tools.field('camera_type', 'select', seed_tools.l('Type', 'प्रकार'), true, 'both',
      array[seed_tools.opt('dslr', 'DSLR', 'DSLR'), seed_tools.opt('mirrorless', 'Mirrorless', 'मिररलेस'), seed_tools.opt('action', 'Action camera', 'एक्शन कैमरा'), seed_tools.opt('cctv', 'CCTV system', 'CCTV सिस्टम')]),
    seed_tools.in_qty(), seed_tools.in_install()));
select seed_tools.cat('accessories', 'electronics', seed_tools.l('Accessories', 'एक्सेसरीज़'),
  p_keywords => array['charger','headphones','earbuds','cable','printer'], p_icon => 'headphones', p_sort => 4,
  p_field_schema => seed_tools.schema(seed_tools.field('item', 'text', seed_tools.l('Item', 'सामान'), true), seed_tools.in_qty()));

-- Furniture and home -------------------------------------------------------------------------------------------
select seed_tools.cat('sofas', 'furniture-home', seed_tools.l('Sofas', 'सोफ़ा'),
  p_keywords => array['sofa','couch','सोफ़ा'], p_icon => 'weekend', p_sort => 1,
  p_field_schema => seed_tools.schema(
    seed_tools.field('seats', 'number', seed_tools.l('Seats', 'सीटें'), true, 'both', null, '{"min":1,"max":12}'),
    seed_tools.field('material', 'select', seed_tools.l('Material', 'मटेरियल'), false, 'both',
      array[seed_tools.opt('fabric', 'Fabric', 'फ़ैब्रिक'), seed_tools.opt('leather', 'Leather', 'लेदर'), seed_tools.opt('leatherette', 'Leatherette', 'लेदरेट')])));
select seed_tools.cat('beds', 'furniture-home', seed_tools.l('Beds', 'बेड'),
  p_keywords => array['bed','cot','पलंग','बेड'], p_icon => 'bed', p_sort => 2,
  p_field_schema => seed_tools.schema(
    seed_tools.field('size', 'select', seed_tools.l('Size', 'साइज़'), true, 'both',
      array[seed_tools.opt('single', 'Single', 'सिंगल'), seed_tools.opt('double', 'Double', 'डबल'), seed_tools.opt('queen', 'Queen', 'क्वीन'), seed_tools.opt('king', 'King', 'किंग')]),
    seed_tools.field('storage', 'boolean', seed_tools.l('With storage', 'स्टोरेज के साथ'))));
select seed_tools.cat('mattresses', 'furniture-home', seed_tools.l('Mattresses', 'गद्दे'),
  p_keywords => array['mattress','गद्दा'], p_icon => 'king_bed', p_sort => 3,
  p_field_schema => seed_tools.schema(
    seed_tools.field('size', 'select', seed_tools.l('Size', 'साइज़'), true, 'both',
      array[seed_tools.opt('single', 'Single', 'सिंगल'), seed_tools.opt('double', 'Double', 'डबल'), seed_tools.opt('queen', 'Queen', 'क्वीन'), seed_tools.opt('king', 'King', 'किंग')]),
    seed_tools.field('mattress_type', 'select', seed_tools.l('Type', 'प्रकार'), false, 'both',
      array[seed_tools.opt('foam', 'Foam', 'फोम'), seed_tools.opt('spring', 'Spring', 'स्प्रिंग'), seed_tools.opt('coir', 'Coir', 'कॉयर'), seed_tools.opt('latex', 'Latex', 'लेटेक्स')])));
select seed_tools.cat('modular-kitchens', 'furniture-home', seed_tools.l('Modular kitchens', 'मॉड्यूलर किचन'),
  p_keywords => array['modular kitchen','kitchen','मॉड्यूलर किचन'], p_icon => 'countertops', p_sort => 4,
  p_field_schema => seed_tools.schema(
    seed_tools.field('shape', 'select', seed_tools.l('Layout', 'लेआउट'), true, 'both',
      array[seed_tools.opt('straight', 'Straight', 'सीधा'), seed_tools.opt('l_shape', 'L-shape', 'L-आकार'), seed_tools.opt('u_shape', 'U-shape', 'U-आकार'), seed_tools.opt('parallel', 'Parallel', 'पैरेलल')]),
    seed_tools.field('length_ft', 'number', seed_tools.l('Total length (ft)', 'कुल लंबाई (फीट)'), false, 'both', null, '{"min":4,"max":60}')));
select seed_tools.cat('interiors', 'furniture-home', seed_tools.l('Interior design', 'इंटीरियर डिज़ाइन'),
  p_keywords => array['interior','interiors','false ceiling','wardrobe','इंटीरियर'], p_icon => 'design_services', p_sort => 5,
  p_field_schema => seed_tools.schema(seed_tools.in_property(), seed_tools.in_area(),
    seed_tools.field('scope', 'multiselect', seed_tools.l('Rooms', 'कमरे'), false, 'request',
      array[seed_tools.opt('full', 'Full home', 'पूरा घर'), seed_tools.opt('living', 'Living room', 'लिविंग रूम'), seed_tools.opt('bedroom', 'Bedroom', 'बेडरूम'), seed_tools.opt('kitchen', 'Kitchen', 'किचन')])));

-- Home services --------------------------------------------------------------------------------------------------
select seed_tools.cat('ac-repair', 'home-services', seed_tools.l('AC repair and service', 'एसी रिपेयर और सर्विस'),
  p_keywords => array['ac repair','ac service','gas refill','ac servicing','एसी सर्विस','एसी रिपेयर'], p_icon => 'ac_unit', p_sort => 1,
  p_field_schema => seed_tools.schema(seed_tools.in_units(),
    seed_tools.field('ac_type', 'select', seed_tools.l('AC type', 'एसी का प्रकार'), false, 'request',
      array[seed_tools.opt('split', 'Split', 'स्प्लिट'), seed_tools.opt('window', 'Window', 'विंडो'), seed_tools.opt('cassette', 'Cassette', 'कैसेट')]),
    seed_tools.field('service_type', 'select', seed_tools.l('Service', 'सेवा'), true, 'request',
      array[seed_tools.opt('service', 'General service', 'सामान्य सर्विस'), seed_tools.opt('gas_refill', 'Gas refill', 'गैस रिफिल'),
            seed_tools.opt('repair', 'Repair', 'रिपेयर'), seed_tools.opt('install', 'Installation', 'इंस्टॉलेशन'), seed_tools.opt('uninstall', 'Uninstall', 'अनइंस्टॉल')]),
    seed_tools.in_problem(false)));
select seed_tools.cat('plumbing', 'home-services', seed_tools.l('Plumbing', 'प्लंबिंग'),
  p_keywords => array['plumber','plumbing','leak','tap','pipe','प्लंबर'], p_icon => 'plumbing', p_sort => 2,
  p_field_schema => seed_tools.schema(seed_tools.in_problem()));
select seed_tools.cat('electrical', 'home-services', seed_tools.l('Electrician', 'इलेक्ट्रीशियन'),
  p_keywords => array['electrician','wiring','switch','fan installation','इलेक्ट्रीशियन'], p_icon => 'electrical_services', p_sort => 3,
  p_field_schema => seed_tools.schema(seed_tools.in_problem(), seed_tools.in_units()));
select seed_tools.cat('cleaning', 'home-services', seed_tools.l('Cleaning', 'सफ़ाई'),
  p_keywords => array['cleaning','deep cleaning','sofa cleaning','सफ़ाई'], p_icon => 'cleaning_services', p_sort => 4,
  p_field_schema => seed_tools.schema(seed_tools.in_property(),
    seed_tools.field('cleaning_type', 'select', seed_tools.l('Type', 'प्रकार'), true, 'request',
      array[seed_tools.opt('deep', 'Full home deep clean', 'पूरे घर की डीप क्लीनिंग'), seed_tools.opt('kitchen', 'Kitchen', 'किचन'),
            seed_tools.opt('bathroom', 'Bathroom', 'बाथरूम'), seed_tools.opt('sofa', 'Sofa / carpet', 'सोफ़ा / कालीन')])));
select seed_tools.cat('pest-control', 'home-services', seed_tools.l('Pest control', 'पेस्ट कंट्रोल'),
  p_keywords => array['pest control','termite','cockroach','bed bugs','दीमक'], p_icon => 'pest_control', p_sort => 5,
  p_field_schema => seed_tools.schema(seed_tools.in_property(),
    seed_tools.field('pests', 'multiselect', seed_tools.l('Pests', 'कीट'), true, 'request',
      array[seed_tools.opt('cockroach', 'Cockroaches', 'कॉकरोच'), seed_tools.opt('termite', 'Termites', 'दीमक'), seed_tools.opt('bedbug', 'Bed bugs', 'खटमल'),
            seed_tools.opt('rodent', 'Rats', 'चूहे'), seed_tools.opt('mosquito', 'Mosquitoes', 'मच्छर')])));
select seed_tools.cat('painting', 'home-services', seed_tools.l('Painting', 'पेंटिंग'),
  p_keywords => array['painting','painter','wall paint','पेंटर'], p_icon => 'format_paint', p_sort => 6,
  p_field_schema => seed_tools.schema(seed_tools.in_property(), seed_tools.in_area(),
    seed_tools.field('paint_area', 'select', seed_tools.l('Interior or exterior', 'अंदर या बाहर'), false, 'request',
      array[seed_tools.opt('interior', 'Interior', 'अंदर'), seed_tools.opt('exterior', 'Exterior', 'बाहर'), seed_tools.opt('both', 'Both', 'दोनों')])));
select seed_tools.cat('packers-movers', 'home-services', seed_tools.l('Packers and movers', 'पैकर्स और मूवर्स'),
  p_keywords => array['packers','movers','shifting','relocation','पैकर्स','शिफ्टिंग'], p_icon => 'local_shipping', p_sort => 7,
  p_field_schema => seed_tools.schema(
    seed_tools.field('to_pin', 'text', seed_tools.l('Destination PIN code', 'गंतव्य पिन कोड'), true, 'request', null, '{"pattern":"^[1-9][0-9]{5}$"}'),
    seed_tools.in_property(),
    seed_tools.field('floor', 'number', seed_tools.l('Floor', 'मंज़िल'), false, 'request', null, '{"min":0,"max":60}'),
    seed_tools.field('lift', 'boolean', seed_tools.l('Lift available', 'लिफ्ट उपलब्ध'))));
select seed_tools.cat('appliance-repair', 'home-services', seed_tools.l('Appliance repair', 'उपकरण रिपेयर'),
  p_keywords => array['repair','fridge repair','washing machine repair','tv repair','रिपेयर'], p_icon => 'build', p_sort => 8,
  p_field_schema => seed_tools.schema(
    seed_tools.field('appliance', 'select', seed_tools.l('Appliance', 'उपकरण'), true, 'request',
      array[seed_tools.opt('fridge', 'Refrigerator', 'फ्रिज'), seed_tools.opt('washer', 'Washing machine', 'वॉशिंग मशीन'), seed_tools.opt('tv', 'TV', 'टीवी'),
            seed_tools.opt('microwave', 'Microwave', 'माइक्रोवेव'), seed_tools.opt('purifier', 'Water purifier', 'वॉटर प्यूरीफायर'), seed_tools.opt('other', 'Other', 'अन्य')]),
    seed_tools.field('brand', 'text', seed_tools.l('Brand', 'ब्रांड')), seed_tools.in_problem()));
select seed_tools.cat('carpentry', 'home-services', seed_tools.l('Carpentry', 'बढ़ईगीरी'),
  p_keywords => array['carpenter','furniture repair','बढ़ई'], p_icon => 'carpenter', p_sort => 9,
  p_field_schema => seed_tools.schema(seed_tools.in_problem()));

-- Vehicles ----------------------------------------------------------------------------------------------------------
select seed_tools.cat('new-cars', 'vehicles', seed_tools.l('New cars', 'नई कार'),
  p_keywords => array['new car','car','suv','कार'], p_icon => 'directions_car', p_sort => 1,
  p_field_schema => seed_tools.schema(
    seed_tools.field('model', 'text', seed_tools.l('Make and model', 'कंपनी और मॉडल'), true, 'both'),
    seed_tools.field('fuel', 'select', seed_tools.l('Fuel', 'ईंधन'), false, 'both',
      array[seed_tools.opt('petrol', 'Petrol', 'पेट्रोल'), seed_tools.opt('diesel', 'Diesel', 'डीज़ल'), seed_tools.opt('cng', 'CNG', 'CNG'),
            seed_tools.opt('ev', 'Electric', 'इलेक्ट्रिक'), seed_tools.opt('hybrid', 'Hybrid', 'हाइब्रिड')]),
    seed_tools.field('variant', 'text', seed_tools.l('Variant / colour', 'वेरिएंट / रंग')), seed_tools.in_exchange()));
select seed_tools.cat('new-bikes', 'vehicles', seed_tools.l('New bikes and scooters', 'नई बाइक और स्कूटर'),
  p_keywords => array['bike','scooter','motorcycle','scooty','बाइक','स्कूटर'], p_icon => 'two_wheeler', p_sort => 2,
  p_field_schema => seed_tools.schema(
    seed_tools.field('model', 'text', seed_tools.l('Make and model', 'कंपनी और मॉडल'), true, 'both'), seed_tools.in_exchange()));
select seed_tools.cat('vehicle-servicing', 'vehicles', seed_tools.l('Vehicle servicing', 'वाहन सर्विसिंग'),
  p_keywords => array['car service','bike service','servicing','सर्विसिंग'], p_icon => 'car_repair', p_sort => 3,
  p_field_schema => seed_tools.schema(
    seed_tools.field('vehicle_type', 'select', seed_tools.l('Vehicle', 'वाहन'), true, 'request',
      array[seed_tools.opt('car', 'Car', 'कार'), seed_tools.opt('bike', 'Bike / scooter', 'बाइक / स्कूटर')]),
    seed_tools.field('model', 'text', seed_tools.l('Make and model', 'कंपनी और मॉडल'), true),
    seed_tools.field('km', 'number', seed_tools.l('Kilometres driven', 'कितने किलोमीटर चली'), false, 'request', null, '{"min":0,"max":1000000}'),
    seed_tools.in_problem(false)));
select seed_tools.cat('tyres', 'vehicles', seed_tools.l('Tyres', 'टायर'),
  p_keywords => array['tyre','tyres','tire','टायर'], p_icon => 'tire_repair', p_sort => 4,
  p_field_schema => seed_tools.schema(
    seed_tools.field('tyre_size', 'text', seed_tools.l('Tyre size (e.g. 185/65 R15)', 'टायर साइज़ (जैसे 185/65 R15)'), true, 'both'),
    seed_tools.in_qty(), seed_tools.in_brands('MRF', 'Apollo', 'CEAT', 'Bridgestone', 'Michelin')));
select seed_tools.cat('used-vehicles', 'vehicles', seed_tools.l('Used vehicles', 'पुराने वाहन'),
  p_keywords => array['used car','second hand car','pre-owned','सेकंड हैंड'], p_icon => 'garage', p_sort => 5,
  p_field_schema => seed_tools.schema(
    seed_tools.field('model', 'text', seed_tools.l('Make and model', 'कंपनी और मॉडल'), true, 'both'),
    seed_tools.field('year_min', 'number', seed_tools.l('Year (from)', 'साल (से)'), false, 'request', null, '{"min":1990,"max":2100}'),
    seed_tools.field('max_km', 'number', seed_tools.l('Max kilometres', 'अधिकतम किलोमीटर'), false, 'request', null, '{"min":0,"max":1000000}')));

-- Events --------------------------------------------------------------------------------------------------------------
select seed_tools.cat('catering', 'events', seed_tools.l('Catering', 'कैटरिंग'),
  p_keywords => array['catering','caterer','food for party','कैटरर'], p_icon => 'restaurant', p_sort => 1,
  p_field_schema => seed_tools.schema(seed_tools.in_guests(), seed_tools.in_event_date(),
    seed_tools.field('food_pref', 'select', seed_tools.l('Food', 'भोजन'), true, 'request',
      array[seed_tools.opt('veg', 'Veg only', 'केवल शाकाहारी'), seed_tools.opt('non_veg', 'Non-veg', 'मांसाहारी'), seed_tools.opt('both', 'Both', 'दोनों'), seed_tools.opt('jain', 'Jain', 'जैन')]),
    seed_tools.field('cuisines', 'multiselect', seed_tools.l('Cuisines', 'व्यंजन'), false, 'request',
      array[seed_tools.opt('north_indian', 'North Indian', 'उत्तर भारतीय'), seed_tools.opt('south_indian', 'South Indian', 'दक्षिण भारतीय'),
            seed_tools.opt('chinese', 'Chinese', 'चाइनीज़'), seed_tools.opt('continental', 'Continental', 'कॉन्टिनेंटल')]),
    seed_tools.field('fssai_licence', 'text', seed_tools.l('FSSAI licence number', 'FSSAI लाइसेंस संख्या'), false, 'quote')));
select seed_tools.cat('photography', 'events', seed_tools.l('Photography', 'फ़ोटोग्राफ़ी'),
  p_keywords => array['photographer','photography','videography','फ़ोटोग्राफ़र'], p_icon => 'photo_camera', p_sort => 2,
  p_field_schema => seed_tools.schema(seed_tools.in_event_date(),
    seed_tools.field('event_type', 'select', seed_tools.l('Event', 'कार्यक्रम'), true, 'request',
      array[seed_tools.opt('wedding', 'Wedding', 'शादी'), seed_tools.opt('birthday', 'Birthday', 'जन्मदिन'), seed_tools.opt('corporate', 'Corporate', 'कॉर्पोरेट'), seed_tools.opt('product', 'Product shoot', 'प्रोडक्ट शूट')]),
    seed_tools.field('hours', 'number', seed_tools.l('Hours', 'घंटे'), false, 'request', null, '{"min":1,"max":72}'),
    seed_tools.field('video', 'boolean', seed_tools.l('Video too', 'वीडियो भी'))));
select seed_tools.cat('decoration', 'events', seed_tools.l('Decoration', 'सजावट'),
  p_keywords => array['decoration','decorator','balloon','flower decoration','सजावट'], p_icon => 'celebration', p_sort => 3,
  p_field_schema => seed_tools.schema(seed_tools.in_event_date(), seed_tools.field('theme', 'text', seed_tools.l('Theme', 'थीम'))));
select seed_tools.cat('venues', 'events', seed_tools.l('Venues and banquet halls', 'वेन्यू और बैंक्वेट हॉल'),
  p_keywords => array['venue','banquet','hall','marriage hall','बैंक्वेट'], p_icon => 'location_city', p_sort => 4,
  p_field_schema => seed_tools.schema(seed_tools.in_guests(), seed_tools.in_event_date()));

-- Business supplies -------------------------------------------------------------------------------------------------------
select seed_tools.cat('printing', 'business-supplies', seed_tools.l('Printing', 'प्रिंटिंग'),
  p_keywords => array['printing','print','t-shirts','visiting cards','flyers','banner','प्रिंटिंग'], p_icon => 'print', p_sort => 1,
  p_field_schema => seed_tools.schema(
    seed_tools.field('item', 'select', seed_tools.l('What to print', 'क्या प्रिंट करना है'), true, 'both',
      array[seed_tools.opt('tshirts', 'T-shirts', 'टी-शर्ट'), seed_tools.opt('cards', 'Visiting cards', 'विज़िटिंग कार्ड'), seed_tools.opt('flyers', 'Flyers', 'फ़्लायर'),
            seed_tools.opt('banners', 'Banners / flex', 'बैनर / फ्लेक्स'), seed_tools.opt('stickers', 'Stickers', 'स्टिकर'), seed_tools.opt('other', 'Other', 'अन्य')]),
    seed_tools.field('quantity', 'number', seed_tools.l('Quantity', 'मात्रा'), true, 'request', null, '{"min":1,"max":1000000}'),
    seed_tools.field('size', 'text', seed_tools.l('Size / specs', 'साइज़ / विवरण'))));
select seed_tools.cat('packaging', 'business-supplies', seed_tools.l('Packaging', 'पैकेजिंग'),
  p_keywords => array['packaging','boxes','carton','corrugated','पैकेजिंग'], p_icon => 'inventory', p_sort => 2,
  p_field_schema => seed_tools.schema(
    seed_tools.field('pack_type', 'select', seed_tools.l('Type', 'प्रकार'), true, 'both',
      array[seed_tools.opt('boxes', 'Boxes', 'डिब्बे'), seed_tools.opt('bags', 'Bags', 'थैले'), seed_tools.opt('tape', 'Tape', 'टेप'), seed_tools.opt('bubble', 'Bubble wrap', 'बबल रैप')]),
    seed_tools.field('quantity', 'number', seed_tools.l('Quantity', 'मात्रा'), true, 'request', null, '{"min":1,"max":10000000}'),
    seed_tools.field('dimensions', 'text', seed_tools.l('Dimensions', 'माप'))));
select seed_tools.cat('office-supplies', 'business-supplies', seed_tools.l('Bulk office supplies', 'थोक ऑफिस सामान'),
  p_keywords => array['office supplies','stationery','a4 paper','स्टेशनरी'], p_icon => 'business_center', p_sort => 3,
  p_field_schema => seed_tools.schema(seed_tools.field('items', 'text', seed_tools.l('Items and quantities', 'सामान और मात्रा'), true, 'request', null, '{"multiline":true}')));
select seed_tools.cat('uniforms', 'business-supplies', seed_tools.l('Uniforms', 'यूनिफ़ॉर्म'),
  p_keywords => array['uniform','uniforms','school uniform','यूनिफ़ॉर्म'], p_icon => 'checkroom', p_sort => 4,
  p_field_schema => seed_tools.schema(
    seed_tools.field('uniform_type', 'select', seed_tools.l('Type', 'प्रकार'), true, 'request',
      array[seed_tools.opt('school', 'School', 'स्कूल'), seed_tools.opt('corporate', 'Corporate', 'कॉर्पोरेट'), seed_tools.opt('hospitality', 'Hotel / restaurant', 'होटल / रेस्टोरेंट'), seed_tools.opt('medical', 'Medical', 'मेडिकल')]),
    seed_tools.field('quantity', 'number', seed_tools.l('Quantity', 'मात्रा'), true, 'request', null, '{"min":1,"max":100000}'),
    seed_tools.field('sizes', 'text', seed_tools.l('Sizes', 'साइज़'))));

-- Restricted / blocked leaves (children inherit the stricter parent policy) ---------------------------------------------
select seed_tools.cat('property-rent', 'real-estate', seed_tools.l('Rent a home or shop', 'घर या दुकान किराए पर'), 'restricted', 'rera_registration',
  p_keywords => array['flat for rent','rent','rental','किराया'], p_sort => 1,
  p_field_schema => seed_tools.schema(seed_tools.in_property(),
    seed_tools.field('rera_number', 'text', seed_tools.l('RERA registration number', 'RERA पंजीकरण संख्या'), true, 'quote')));
select seed_tools.cat('property-buy', 'real-estate', seed_tools.l('Buy property', 'प्रॉपर्टी ख़रीदें'), 'restricted', 'rera_registration',
  p_keywords => array['buy flat','apartment','plot','property','प्रॉपर्टी'], p_sort => 2,
  p_field_schema => seed_tools.schema(seed_tools.in_property(),
    seed_tools.field('rera_number', 'text', seed_tools.l('RERA registration number', 'RERA पंजीकरण संख्या'), true, 'quote')));
select seed_tools.cat('doctors-clinics', 'health', seed_tools.l('Doctor / clinic visit', 'डॉक्टर / क्लिनिक'), 'restricted', 'nmc_registration',
  p_keywords => array['doctor','clinic','dentist','physiotherapy','डॉक्टर'], p_sort => 1,
  p_field_schema => seed_tools.schema(
    seed_tools.field('specialty', 'text', seed_tools.l('Specialty needed', 'विशेषज्ञता'), true),
    seed_tools.field('registration_number', 'text', seed_tools.l('Medical registration number', 'मेडिकल पंजीकरण संख्या'), true, 'quote')));
select seed_tools.cat('health-insurance', 'insurance', seed_tools.l('Health insurance', 'स्वास्थ्य बीमा'), 'blocked', 'irdai_registration', p_sort => 1);
select seed_tools.cat('motor-insurance', 'insurance', seed_tools.l('Motor insurance', 'वाहन बीमा'), 'blocked', 'irdai_registration', p_sort => 2);
select seed_tools.cat('life-insurance', 'insurance', seed_tools.l('Life insurance', 'जीवन बीमा'), 'blocked', 'irdai_registration', p_sort => 3);
select seed_tools.cat('home-insurance', 'insurance', seed_tools.l('Home insurance', 'गृह बीमा'), 'blocked', 'irdai_registration', p_sort => 4);
select seed_tools.cat('loans', 'finance', seed_tools.l('Loans', 'लोन'), 'blocked', p_sort => 1);
select seed_tools.cat('credit-cards', 'finance', seed_tools.l('Credit cards', 'क्रेडिट कार्ड'), 'blocked', p_sort => 2);
select seed_tools.cat('investments', 'finance', seed_tools.l('Investments, securities and crypto', 'निवेश, शेयर और क्रिप्टो'), 'blocked', p_sort => 3);
select seed_tools.cat('advocates', 'legal-services', seed_tools.l('Advocates', 'वकील'), 'blocked', p_sort => 1);
select seed_tools.cat('medicines', 'pharmacy', seed_tools.l('Medicines', 'दवाइयाँ'), 'blocked', p_sort => 1);
select seed_tools.cat('alcohol', 'alcohol-tobacco', seed_tools.l('Alcohol', 'शराब'), 'blocked', p_sort => 1);
select seed_tools.cat('tobacco-vapes', 'alcohol-tobacco', seed_tools.l('Tobacco and vapes', 'तंबाकू और वेप'), 'blocked', p_sort => 2);
select seed_tools.cat('firearms', 'weapons', seed_tools.l('Firearms and ammunition', 'हथियार और गोला-बारूद'), 'blocked', p_sort => 1);

-- Blocked-keyword classifier (catches blocked items typed into allowed categories) ------------------------------------------
select seed_tools.block_kw('insurance', 'en', 'insurance', 'insurance policy', 'health insurance', 'car insurance',
  'term plan', 'life cover', 'mediclaim');
select seed_tools.block_kw('insurance', 'hi', 'बीमा', 'इंश्योरेंस');
select seed_tools.block_kw('finance', 'en', 'loan', 'personal loan', 'home loan', 'car loan', 'credit card', 'emi finance',
  'mutual fund', 'stock tips', 'share market tips', 'crypto', 'bitcoin', 'forex', 'trading tips');
select seed_tools.block_kw('finance', 'hi', 'लोन', 'कर्ज़', 'क्रेडिट कार्ड', 'म्यूचुअल फंड', 'क्रिप्टो');
select seed_tools.block_kw('legal-services', 'en', 'lawyer', 'advocate', 'legal notice', 'divorce lawyer', 'court case');
select seed_tools.block_kw('legal-services', 'hi', 'वकील', 'अधिवक्ता');
select seed_tools.block_kw('pharmacy', 'en', 'medicine', 'medicines', 'prescription drugs', 'antibiotics', 'painkillers', 'pharmacy');
select seed_tools.block_kw('pharmacy', 'hi', 'दवाई', 'दवाइयाँ', 'दवा');
select seed_tools.block_kw('alcohol-tobacco', 'en', 'alcohol', 'liquor', 'beer', 'whisky', 'vodka', 'rum', 'wine', 'cigarette',
  'cigarettes', 'tobacco', 'gutkha', 'vape', 'e-cigarette', 'hookah flavour');
select seed_tools.block_kw('alcohol-tobacco', 'hi', 'शराब', 'दारू', 'बीयर', 'सिगरेट', 'तंबाकू', 'गुटखा');
select seed_tools.block_kw('weapons', 'en', 'gun', 'pistol', 'revolver', 'rifle', 'firearm', 'ammunition', 'bullets', 'airgun');
select seed_tools.block_kw('weapons', 'hi', 'बंदूक', 'पिस्तौल', 'कारतूस');
-- category-less blocks (always blocked)
insert into public.category_keywords (keyword, lang, action, reason) values
  ('ganja', 'en', 'block', seed_tools.l('Drugs cannot be requested.', 'नशीले पदार्थ नहीं माँगे जा सकते।')),
  ('cannabis', 'en', 'block', seed_tools.l('Drugs cannot be requested.', 'नशीले पदार्थ नहीं माँगे जा सकते।')),
  ('escort', 'en', 'block', seed_tools.l('Adult services cannot be requested.', 'वयस्क सेवाएँ नहीं माँगी जा सकतीं।')),
  ('fake certificate', 'en', 'block', seed_tools.l('Counterfeit documents cannot be requested.', 'नकली दस्तावेज़ नहीं माँगे जा सकते।')),
  ('गांजा', 'hi', 'block', seed_tools.l('Drugs cannot be requested.', 'नशीले पदार्थ नहीं माँगे जा सकते।'))
on conflict (keyword, lang, action) do nothing;

-- Postal codes for the demo cities (full set: tool/data/import_india_post.py) -------------------------------------------------
select seed_tools.pc('560001', 12.9757, 77.6050, 'Bengaluru', 'MG Road', 'Karnataka', 'KA');
select seed_tools.pc('560011', 12.9308, 77.5838, 'Bengaluru', 'Jayanagar', 'Karnataka', 'KA');
select seed_tools.pc('560034', 12.9352, 77.6245, 'Bengaluru', 'Koramangala', 'Karnataka', 'KA');
select seed_tools.pc('560038', 12.9784, 77.6408, 'Bengaluru', 'Indiranagar', 'Karnataka', 'KA');
select seed_tools.pc('560066', 12.9698, 77.7500, 'Bengaluru', 'Whitefield', 'Karnataka', 'KA');
select seed_tools.pc('560076', 12.9166, 77.6101, 'Bengaluru', 'BTM Layout', 'Karnataka', 'KA');
select seed_tools.pc('400001', 18.9388, 72.8354, 'Mumbai', 'Fort', 'Maharashtra', 'MH');
select seed_tools.pc('400050', 19.0596, 72.8295, 'Mumbai', 'Bandra West', 'Maharashtra', 'MH');
select seed_tools.pc('400053', 19.1364, 72.8296, 'Mumbai', 'Andheri West', 'Maharashtra', 'MH');
select seed_tools.pc('400070', 19.0726, 72.8845, 'Mumbai', 'Kurla', 'Maharashtra', 'MH');
select seed_tools.pc('400076', 19.1176, 72.9060, 'Mumbai', 'Powai', 'Maharashtra', 'MH');
select seed_tools.pc('400092', 19.2307, 72.8567, 'Mumbai', 'Borivali West', 'Maharashtra', 'MH');
select seed_tools.pc('110001', 28.6315, 77.2167, 'New Delhi', 'Connaught Place', 'Delhi', 'DL');
select seed_tools.pc('110016', 28.5494, 77.2001, 'New Delhi', 'Hauz Khas', 'Delhi', 'DL');
select seed_tools.pc('110019', 28.5355, 77.2580, 'New Delhi', 'Kalkaji', 'Delhi', 'DL');
select seed_tools.pc('110024', 28.5677, 77.2433, 'New Delhi', 'Lajpat Nagar', 'Delhi', 'DL');
select seed_tools.pc('110075', 28.5921, 77.0460, 'New Delhi', 'Dwarka', 'Delhi', 'DL');
select seed_tools.pc('110085', 28.7158, 77.1170, 'New Delhi', 'Rohini', 'Delhi', 'DL');
select seed_tools.pc('110092', 28.6304, 77.2777, 'New Delhi', 'Laxmi Nagar', 'Delhi', 'DL');

-- Priority metros (outreach ordering only; launch is nationwide) ----------------------------------------------------------------
select seed_tools.city('Bengaluru', 'Karnataka', 'KA', 12.9716, 77.5946, 8443675, 'Asia/Kolkata', 1);
select seed_tools.city('Mumbai', 'Maharashtra', 'MH', 19.0760, 72.8777, 12442373, 'Asia/Kolkata', 2);
select seed_tools.city('New Delhi', 'Delhi', 'DL', 28.6139, 77.2090, 11034555, 'Asia/Kolkata', 3);
select seed_tools.city('Hyderabad', 'Telangana', 'TG', 17.3850, 78.4867, 6809970, 'Asia/Kolkata', 4);
select seed_tools.city('Chennai', 'Tamil Nadu', 'TN', 13.0827, 80.2707, 4646732, 'Asia/Kolkata', 5);
select seed_tools.city('Pune', 'Maharashtra', 'MH', 18.5204, 73.8567, 3124458, 'Asia/Kolkata', 6);
select seed_tools.city('Kolkata', 'West Bengal', 'WB', 22.5726, 88.3639, 4496694, 'Asia/Kolkata', 7);
select seed_tools.city('Ahmedabad', 'Gujarat', 'GJ', 23.0225, 72.5714, 5577940, 'Asia/Kolkata', 8);
