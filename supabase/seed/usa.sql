-- =============================================================================
-- I Want USA: country settings, two-level category tree (en + es),
-- field schemas, category policy (Section 3.1), blocked-keyword classifier,
-- demo-city ZIP codes and the priority metro list.
-- Requires seed.sql first. Safe to re-run (upserts).
-- POLICY IS A STARTING POINT ONLY: a lawyer must confirm before launch.
-- Contractor trades are 'restricted' everywhere for now (state-by-state
-- licence rules are not modelled yet); anything uncertain stays blocked.
-- =============================================================================

update public.app_settings set value = '"US"' where key = 'country';
update public.app_settings set value = '"USD"' where key = 'currency';
update public.app_settings set value = '"America/New_York"' where key = 'default_timezone';
update public.app_settings set value = '5' where key = 'free_quotes_per_month';
update public.app_settings set value = '["en","es"]' where key = 'languages';

create or replace function seed_tools.us_energy_star() returns jsonb language sql stable as $$
  select seed_tools.field('energy_star', 'boolean', seed_tools.l('ENERGY STAR certified', 'Certificado ENERGY STAR'), false, 'both') $$;
create or replace function seed_tools.us_qty() returns jsonb language sql stable as $$
  select seed_tools.field('quantity', 'number', seed_tools.l('Quantity', 'Cantidad'), false, 'request', null, '{"min":1,"max":10000,"default":1}') $$;
create or replace function seed_tools.us_install() returns jsonb language sql stable as $$
  select seed_tools.field('installation', 'boolean', seed_tools.l('Installation needed', 'Necesito instalación')) $$;
create or replace function seed_tools.us_haul_away() returns jsonb language sql stable as $$
  select seed_tools.field('haul_away', 'boolean', seed_tools.l('Haul away my old one', 'Retirar el aparato viejo')) $$;
create or replace function seed_tools.us_brands(variadic p text[]) returns jsonb language sql stable as $$
  select seed_tools.field('brand_preference', 'multiselect', seed_tools.l('Preferred brands', 'Marcas preferidas'), false, 'request',
    array(select seed_tools.opt(lower(regexp_replace(b, '[^A-Za-z0-9]+', '_', 'g')), b, b) from unnest(p) b)
      || array[seed_tools.opt('any', 'Any brand', 'Cualquier marca')]) $$;
create or replace function seed_tools.us_problem(p_required boolean default true) returns jsonb language sql stable as $$
  select seed_tools.field('problem', 'text', seed_tools.l('Describe the problem', 'Describe el problema'), p_required, 'request', null, '{"multiline":true}') $$;
create or replace function seed_tools.us_units() returns jsonb language sql stable as $$
  select seed_tools.field('units', 'number', seed_tools.l('Number of units', 'Número de unidades'), true, 'request', null, '{"min":1,"max":50,"default":1}') $$;
create or replace function seed_tools.us_property() returns jsonb language sql stable as $$
  select seed_tools.field('property_type', 'select', seed_tools.l('Property type', 'Tipo de propiedad'), false, 'request',
    array[seed_tools.opt('apartment', 'Apartment / condo', 'Apartamento / condominio'), seed_tools.opt('house', 'House', 'Casa'),
          seed_tools.opt('townhouse', 'Townhouse', 'Casa adosada'), seed_tools.opt('office', 'Office / store', 'Oficina / tienda')]) $$;
create or replace function seed_tools.us_bedrooms() returns jsonb language sql stable as $$
  select seed_tools.field('bedrooms', 'number', seed_tools.l('Bedrooms', 'Habitaciones'), false, 'request', null, '{"min":0,"max":20}') $$;
create or replace function seed_tools.us_area() returns jsonb language sql stable as $$
  select seed_tools.field('area_sqft', 'number', seed_tools.l('Area (sq ft)', 'Área (pies²)'), false, 'request', null, '{"min":50,"max":100000}') $$;
create or replace function seed_tools.us_event_date() returns jsonb language sql stable as $$
  select seed_tools.field('event_date', 'date', seed_tools.l('Event date', 'Fecha del evento'), true) $$;
create or replace function seed_tools.us_guests() returns jsonb language sql stable as $$
  select seed_tools.field('guests', 'number', seed_tools.l('Number of guests', 'Número de invitados'), true, 'request', null, '{"min":1,"max":20000}') $$;
create or replace function seed_tools.us_licence_no() returns jsonb language sql stable as $$
  select seed_tools.field('licence_number', 'text', seed_tools.l('State licence number', 'Número de licencia estatal'), true, 'quote') $$;

-- Roots ---------------------------------------------------------------------------------------------------
select seed_tools.cat('appliances', null, seed_tools.l('Appliances', 'Electrodomésticos'), p_icon => 'kitchen', p_sort => 10);
select seed_tools.cat('electronics', null, seed_tools.l('Electronics', 'Electrónica'), p_icon => 'devices', p_sort => 20);
select seed_tools.cat('furniture-home', null, seed_tools.l('Furniture and home', 'Muebles y hogar'), p_icon => 'chair', p_sort => 30);
select seed_tools.cat('home-services', null, seed_tools.l('Home services', 'Servicios para el hogar'), p_icon => 'home_repair_service', p_sort => 40);
select seed_tools.cat('vehicles', null, seed_tools.l('Vehicles', 'Vehículos'), p_icon => 'directions_car', p_sort => 50);
select seed_tools.cat('events', null, seed_tools.l('Events', 'Eventos'), p_icon => 'celebration', p_sort => 60);
select seed_tools.cat('business-supplies', null, seed_tools.l('Business supplies', 'Suministros para negocios'), p_icon => 'inventory_2', p_sort => 70);
select seed_tools.cat('real-estate', null, seed_tools.l('Real estate (rent / buy)', 'Bienes raíces (alquiler / compra)'), 'restricted', 'state_real_estate_licence',
  p_icon => 'apartment', p_sort => 80,
  p_disclaimer => seed_tools.l('Only state-licensed brokers and agents can quote. Equal Housing Opportunity: requests and quotes may not state a preference based on race, color, religion, sex, disability, familial status or national origin.',
                               'Solo corredores y agentes con licencia estatal pueden cotizar. Igualdad de oportunidades de vivienda: no se permiten preferencias por raza, color, religión, sexo, discapacidad, situación familiar u origen nacional.'));
select seed_tools.cat('legal-services', null, seed_tools.l('Legal services', 'Servicios legales'), 'restricted', 'state_bar_admission',
  p_icon => 'gavel', p_sort => 90,
  p_disclaimer => seed_tools.l('Attorney advertising. Quotes come from lawyers with active admission to a state bar. Prior results do not guarantee a similar outcome. This is not legal advice.',
                               'Publicidad de abogados. Las cotizaciones provienen de abogados admitidos en un colegio estatal. Resultados anteriores no garantizan un resultado similar. Esto no es asesoría legal.'));
select seed_tools.cat('health', null, seed_tools.l('Medical providers', 'Proveedores médicos'), 'restricted', 'state_medical_licence',
  p_icon => 'medical_services', p_sort => 100,
  p_disclaimer => seed_tools.l('Only state-licensed providers can quote. No telehealth prescribing through this app. Not medical advice; call 911 in an emergency.',
                               'Solo proveedores con licencia estatal pueden cotizar. No se recetan medicamentos por esta app. No es consejo médico; llame al 911 en una emergencia.'));
select seed_tools.cat('insurance', null, seed_tools.l('Insurance', 'Seguros'), 'blocked', 'state_insurance_producer',
  p_icon => 'shield', p_sort => 110,
  p_disclaimer => seed_tools.l('Quotes only from insurance producers licensed in your state (NIPR lookup). Coverage is subject to policy terms.',
                               'Cotizaciones solo de productores de seguros con licencia en su estado (NIPR). La cobertura depende de los términos de la póliza.'),
  p_policy_reason => seed_tools.l('Insurance quotes are not available in I Want USA yet.', 'Las cotizaciones de seguros aún no están disponibles en I Want USA.'));
select seed_tools.cat('finance', null, seed_tools.l('Loans, credit and investments', 'Préstamos, crédito e inversiones'), 'blocked',
  p_icon => 'account_balance', p_sort => 120,
  p_policy_reason => seed_tools.l('Loans, credit and investment products cannot be requested in this app (state lending licences, federal consumer credit and SEC/FINRA rules).',
                                  'No se pueden solicitar préstamos, crédito ni inversiones en esta app (licencias estatales, reglas federales de crédito y SEC/FINRA).'));
select seed_tools.cat('pharmacy', null, seed_tools.l('Medicines and pharmacy', 'Medicamentos y farmacia'), 'blocked',
  p_icon => 'medication', p_sort => 130,
  p_policy_reason => seed_tools.l('Medicines cannot be requested in this app.', 'No se pueden solicitar medicamentos en esta app.'));
select seed_tools.cat('alcohol-tobacco', null, seed_tools.l('Alcohol, tobacco and vapes', 'Alcohol, tabaco y vapeadores'), 'blocked',
  p_icon => 'no_drinks', p_sort => 140,
  p_policy_reason => seed_tools.l('Alcohol, tobacco and vapes cannot be requested in this app.', 'No se pueden solicitar alcohol, tabaco ni vapeadores.'));
select seed_tools.cat('weapons', null, seed_tools.l('Firearms and weapons', 'Armas'), 'blocked',
  p_icon => 'block', p_sort => 150,
  p_policy_reason => seed_tools.l('Firearms, ammunition and weapons cannot be requested.', 'No se pueden solicitar armas ni municiones.'));
select seed_tools.cat('other', null, seed_tools.l('Something else', 'Otra cosa'), p_icon => 'more_horiz', p_sort => 999,
  p_keywords => array['other','anything']);

-- Appliances --------------------------------------------------------------------------------------------------
select seed_tools.cat('refrigerators', 'appliances', seed_tools.l('Refrigerators', 'Refrigeradores'),
  p_keywords => array['fridge','refrigerator','freezer','refrigerador','nevera'], p_icon => 'kitchen', p_sort => 1,
  p_field_schema => seed_tools.schema(
    seed_tools.field('capacity_cuft', 'number', seed_tools.l('Capacity (cu ft)', 'Capacidad (pies³)'), false, 'both', null, '{"min":2,"max":40,"unit":"cu ft"}'),
    seed_tools.field('door_type', 'select', seed_tools.l('Style', 'Estilo'), true, 'both',
      array[seed_tools.opt('top_freezer', 'Top freezer', 'Congelador arriba'), seed_tools.opt('bottom_freezer', 'Bottom freezer', 'Congelador abajo'),
            seed_tools.opt('side_by_side', 'Side by side', 'Lado a lado'), seed_tools.opt('french', 'French door', 'Puerta francesa')]),
    seed_tools.us_brands('Samsung', 'LG', 'Whirlpool', 'GE', 'Frigidaire', 'KitchenAid'),
    seed_tools.us_energy_star(), seed_tools.us_haul_away(), seed_tools.us_qty()));
select seed_tools.cat('washers-dryers', 'appliances', seed_tools.l('Washers and dryers', 'Lavadoras y secadoras'),
  p_keywords => array['washer','dryer','washing machine','lavadora','secadora'], p_icon => 'local_laundry_service', p_sort => 2,
  p_field_schema => seed_tools.schema(
    seed_tools.field('unit_type', 'select', seed_tools.l('What do you need', 'Qué necesita'), true, 'both',
      array[seed_tools.opt('washer', 'Washer', 'Lavadora'), seed_tools.opt('dryer', 'Dryer', 'Secadora'), seed_tools.opt('pair', 'Washer + dryer', 'Lavadora + secadora'),
            seed_tools.opt('stacked', 'Stacked unit', 'Unidad apilada')]),
    seed_tools.field('fuel', 'select', seed_tools.l('Dryer fuel', 'Tipo de secadora'), false, 'both',
      array[seed_tools.opt('electric', 'Electric', 'Eléctrica'), seed_tools.opt('gas', 'Gas', 'Gas')]),
    seed_tools.us_brands('LG', 'Samsung', 'Whirlpool', 'Maytag', 'GE'), seed_tools.us_energy_star(), seed_tools.us_haul_away()));
select seed_tools.cat('air-conditioners', 'appliances', seed_tools.l('Air conditioners', 'Aires acondicionados'),
  p_keywords => array['air conditioner','window ac','portable ac','mini split','aire acondicionado'], p_icon => 'ac_unit', p_sort => 3,
  p_field_schema => seed_tools.schema(
    seed_tools.field('btu', 'number', seed_tools.l('Cooling capacity (BTU)', 'Capacidad (BTU)'), false, 'both', null, '{"min":5000,"max":60000}'),
    seed_tools.field('ac_type', 'select', seed_tools.l('Type', 'Tipo'), true, 'both',
      array[seed_tools.opt('window', 'Window', 'Ventana'), seed_tools.opt('portable', 'Portable', 'Portátil'), seed_tools.opt('mini_split', 'Ductless mini-split', 'Mini-split sin ductos')]),
    seed_tools.us_units(), seed_tools.us_energy_star(), seed_tools.us_install()));
select seed_tools.cat('televisions', 'appliances', seed_tools.l('TVs', 'Televisores'),
  p_keywords => array['tv','television','oled','televisor','tele'], p_icon => 'tv', p_sort => 4,
  p_field_schema => seed_tools.schema(
    seed_tools.field('screen_in', 'number', seed_tools.l('Screen size (inches)', 'Pantalla (pulgadas)'), true, 'both', null, '{"min":19,"max":100,"unit":"in"}'),
    seed_tools.field('panel', 'select', seed_tools.l('Panel', 'Panel'), false, 'both',
      array[seed_tools.opt('led', 'LED', 'LED'), seed_tools.opt('qled', 'QLED', 'QLED'), seed_tools.opt('oled', 'OLED', 'OLED')]),
    seed_tools.us_brands('Sony', 'Samsung', 'LG', 'TCL', 'Vizio'),
    seed_tools.field('wall_mount', 'boolean', seed_tools.l('Wall mounting', 'Montaje en pared'))));
select seed_tools.cat('microwaves', 'appliances', seed_tools.l('Microwaves', 'Microondas'),
  p_keywords => array['microwave','microondas'], p_icon => 'microwave', p_sort => 5,
  p_field_schema => seed_tools.schema(
    seed_tools.field('mw_type', 'select', seed_tools.l('Type', 'Tipo'), true, 'both',
      array[seed_tools.opt('countertop', 'Countertop', 'De mesa'), seed_tools.opt('over_range', 'Over-the-range', 'Sobre la estufa'), seed_tools.opt('built_in', 'Built-in', 'Empotrado')]),
    seed_tools.us_brands('GE', 'Whirlpool', 'Panasonic', 'Samsung'), seed_tools.us_install()));
select seed_tools.cat('dishwashers', 'appliances', seed_tools.l('Dishwashers', 'Lavavajillas'),
  p_keywords => array['dishwasher','lavavajillas'], p_icon => 'countertops', p_sort => 6,
  p_field_schema => seed_tools.schema(
    seed_tools.field('dw_type', 'select', seed_tools.l('Type', 'Tipo'), false, 'both',
      array[seed_tools.opt('built_in', 'Built-in', 'Empotrado'), seed_tools.opt('portable', 'Portable', 'Portátil')]),
    seed_tools.us_brands('Bosch', 'KitchenAid', 'Whirlpool', 'GE', 'Miele'), seed_tools.us_energy_star(), seed_tools.us_install()));
select seed_tools.cat('water-heaters', 'appliances', seed_tools.l('Water heaters', 'Calentadores de agua'),
  p_keywords => array['water heater','tankless','calentador'], p_icon => 'water_drop', p_sort => 7,
  p_field_schema => seed_tools.schema(
    seed_tools.field('wh_type', 'select', seed_tools.l('Type', 'Tipo'), true, 'both',
      array[seed_tools.opt('tank_gas', 'Tank (gas)', 'Tanque (gas)'), seed_tools.opt('tank_electric', 'Tank (electric)', 'Tanque (eléctrico)'),
            seed_tools.opt('tankless', 'Tankless', 'Sin tanque'), seed_tools.opt('heat_pump', 'Heat pump', 'Bomba de calor')]),
    seed_tools.field('gallons', 'number', seed_tools.l('Size (gallons)', 'Tamaño (galones)'), false, 'both', null, '{"min":10,"max":120}'),
    seed_tools.us_install(), seed_tools.us_energy_star()));

-- Electronics ----------------------------------------------------------------------------------------------------
select seed_tools.cat('phones', 'electronics', seed_tools.l('Phones', 'Teléfonos'),
  p_keywords => array['phone','iphone','smartphone','galaxy','teléfono','celular'], p_icon => 'smartphone', p_sort => 1,
  p_field_schema => seed_tools.schema(
    seed_tools.field('model', 'text', seed_tools.l('Model wanted', 'Modelo'), false, 'both'),
    seed_tools.field('carrier', 'select', seed_tools.l('Carrier', 'Operador'), false, 'both',
      array[seed_tools.opt('unlocked', 'Unlocked', 'Desbloqueado'), seed_tools.opt('verizon', 'Verizon', 'Verizon'), seed_tools.opt('att', 'AT&T', 'AT&T'), seed_tools.opt('tmobile', 'T-Mobile', 'T-Mobile')]),
    seed_tools.us_brands('Apple', 'Samsung', 'Google'), seed_tools.us_qty()));
select seed_tools.cat('laptops', 'electronics', seed_tools.l('Laptops', 'Laptops'),
  p_keywords => array['laptop','notebook','macbook','computadora portátil'], p_icon => 'laptop', p_sort => 2,
  p_field_schema => seed_tools.schema(
    seed_tools.field('use', 'select', seed_tools.l('Main use', 'Uso principal'), false, 'request',
      array[seed_tools.opt('office', 'Office / school', 'Oficina / escuela'), seed_tools.opt('gaming', 'Gaming', 'Videojuegos'), seed_tools.opt('design', 'Design / video', 'Diseño / video')]),
    seed_tools.field('ram_gb', 'select', seed_tools.l('RAM', 'RAM'), false, 'both',
      array[seed_tools.opt('8', '8 GB', '8 GB'), seed_tools.opt('16', '16 GB', '16 GB'), seed_tools.opt('32', '32 GB+', '32 GB+')]),
    seed_tools.us_brands('Apple', 'Dell', 'HP', 'Lenovo', 'Asus'), seed_tools.us_qty()));
select seed_tools.cat('cameras', 'electronics', seed_tools.l('Cameras and security', 'Cámaras y seguridad'),
  p_keywords => array['camera','security camera','doorbell camera','cámara'], p_icon => 'photo_camera', p_sort => 3,
  p_field_schema => seed_tools.schema(
    seed_tools.field('camera_type', 'select', seed_tools.l('Type', 'Tipo'), true, 'both',
      array[seed_tools.opt('mirrorless', 'Mirrorless / DSLR', 'Mirrorless / DSLR'), seed_tools.opt('action', 'Action camera', 'Cámara de acción'), seed_tools.opt('security', 'Home security system', 'Sistema de seguridad')]),
    seed_tools.us_qty(), seed_tools.us_install()));
select seed_tools.cat('accessories', 'electronics', seed_tools.l('Accessories', 'Accesorios'),
  p_keywords => array['charger','headphones','earbuds','printer','monitor','audífonos'], p_icon => 'headphones', p_sort => 4,
  p_field_schema => seed_tools.schema(seed_tools.field('item', 'text', seed_tools.l('Item', 'Artículo'), true), seed_tools.us_qty()));

-- Furniture and home ---------------------------------------------------------------------------------------------------
select seed_tools.cat('sofas', 'furniture-home', seed_tools.l('Sofas', 'Sofás'),
  p_keywords => array['sofa','couch','sectional','sofá'], p_icon => 'weekend', p_sort => 1,
  p_field_schema => seed_tools.schema(
    seed_tools.field('seats', 'number', seed_tools.l('Seats', 'Asientos'), true, 'both', null, '{"min":1,"max":12}'),
    seed_tools.field('material', 'select', seed_tools.l('Material', 'Material'), false, 'both',
      array[seed_tools.opt('fabric', 'Fabric', 'Tela'), seed_tools.opt('leather', 'Leather', 'Cuero'), seed_tools.opt('performance', 'Performance fabric', 'Tela resistente')])));
select seed_tools.cat('beds', 'furniture-home', seed_tools.l('Beds', 'Camas'),
  p_keywords => array['bed','bed frame','cama'], p_icon => 'bed', p_sort => 2,
  p_field_schema => seed_tools.schema(
    seed_tools.field('size', 'select', seed_tools.l('Size', 'Tamaño'), true, 'both',
      array[seed_tools.opt('twin', 'Twin', 'Individual'), seed_tools.opt('full', 'Full', 'Matrimonial'), seed_tools.opt('queen', 'Queen', 'Queen'), seed_tools.opt('king', 'King', 'King')])));
select seed_tools.cat('mattresses', 'furniture-home', seed_tools.l('Mattresses', 'Colchones'),
  p_keywords => array['mattress','colchón'], p_icon => 'king_bed', p_sort => 3,
  p_field_schema => seed_tools.schema(
    seed_tools.field('size', 'select', seed_tools.l('Size', 'Tamaño'), true, 'both',
      array[seed_tools.opt('twin', 'Twin', 'Individual'), seed_tools.opt('full', 'Full', 'Matrimonial'), seed_tools.opt('queen', 'Queen', 'Queen'), seed_tools.opt('king', 'King', 'King')]),
    seed_tools.field('mattress_type', 'select', seed_tools.l('Type', 'Tipo'), false, 'both',
      array[seed_tools.opt('foam', 'Memory foam', 'Espuma viscoelástica'), seed_tools.opt('hybrid', 'Hybrid', 'Híbrido'), seed_tools.opt('innerspring', 'Innerspring', 'Resortes')])));
select seed_tools.cat('kitchen-remodel', 'furniture-home', seed_tools.l('Kitchen cabinets and remodel', 'Gabinetes y remodelación de cocina'),
  p_keywords => array['kitchen remodel','cabinets','countertops','remodelación'], p_icon => 'countertops', p_sort => 4,
  p_field_schema => seed_tools.schema(seed_tools.us_area(),
    seed_tools.field('scope', 'multiselect', seed_tools.l('Scope', 'Alcance'), false, 'request',
      array[seed_tools.opt('cabinets', 'Cabinets', 'Gabinetes'), seed_tools.opt('countertops', 'Countertops', 'Encimeras'), seed_tools.opt('full', 'Full remodel', 'Remodelación completa')]),
    seed_tools.us_licence_no()));
select seed_tools.cat('interior-design', 'furniture-home', seed_tools.l('Interior design', 'Diseño de interiores'),
  p_keywords => array['interior design','interior designer','decorator','diseño de interiores'], p_icon => 'design_services', p_sort => 5,
  p_field_schema => seed_tools.schema(seed_tools.us_property(), seed_tools.us_bedrooms(), seed_tools.us_area()));

-- Home services ----------------------------------------------------------------------------------------------------------
select seed_tools.cat('hvac', 'home-services', seed_tools.l('HVAC repair and install', 'Reparación e instalación de HVAC'), 'restricted', 'state_contractor_licence',
  p_keywords => array['hvac','furnace','ac repair','heat pump','central air','calefacción'], p_icon => 'hvac', p_sort => 1,
  p_disclaimer => seed_tools.l('Contractor licence required where your state requires one; the licence number is shown on the quote.', 'Se requiere licencia de contratista donde su estado lo exija; el número aparece en la cotización.'),
  p_field_schema => seed_tools.schema(seed_tools.us_units(),
    seed_tools.field('service_type', 'select', seed_tools.l('Service', 'Servicio'), true, 'request',
      array[seed_tools.opt('tune_up', 'Tune-up', 'Mantenimiento'), seed_tools.opt('repair', 'Repair', 'Reparación'), seed_tools.opt('replace', 'Replacement', 'Reemplazo'), seed_tools.opt('new_install', 'New install', 'Instalación nueva')]),
    seed_tools.us_problem(false), seed_tools.us_licence_no()));
select seed_tools.cat('roofing', 'home-services', seed_tools.l('Roofing', 'Techos'), 'restricted', 'state_contractor_licence',
  p_keywords => array['roof','roofing','roofer','shingles','techo'], p_icon => 'roofing', p_sort => 2,
  p_disclaimer => seed_tools.l('Contractor licence required where your state requires one; the licence number is shown on the quote.', 'Se requiere licencia de contratista donde su estado lo exija; el número aparece en la cotización.'),
  p_field_schema => seed_tools.schema(seed_tools.us_area(),
    seed_tools.field('roof_job', 'select', seed_tools.l('Job', 'Trabajo'), true, 'request',
      array[seed_tools.opt('repair', 'Repair / leak', 'Reparación / gotera'), seed_tools.opt('replace', 'Full replacement', 'Reemplazo completo'), seed_tools.opt('inspection', 'Inspection', 'Inspección')]),
    seed_tools.us_licence_no()));
select seed_tools.cat('plumbing', 'home-services', seed_tools.l('Plumbing', 'Plomería'), 'restricted', 'state_contractor_licence',
  p_keywords => array['plumber','plumbing','leak','clogged drain','plomero'], p_icon => 'plumbing', p_sort => 3,
  p_disclaimer => seed_tools.l('Contractor licence required where your state requires one; the licence number is shown on the quote.', 'Se requiere licencia de contratista donde su estado lo exija; el número aparece en la cotización.'),
  p_field_schema => seed_tools.schema(seed_tools.us_problem(), seed_tools.us_licence_no()));
select seed_tools.cat('electrical', 'home-services', seed_tools.l('Electrical', 'Electricidad'), 'restricted', 'state_contractor_licence',
  p_keywords => array['electrician','wiring','outlet','panel upgrade','electricista'], p_icon => 'electrical_services', p_sort => 4,
  p_disclaimer => seed_tools.l('Contractor licence required where your state requires one; the licence number is shown on the quote.', 'Se requiere licencia de contratista donde su estado lo exija; el número aparece en la cotización.'),
  p_field_schema => seed_tools.schema(seed_tools.us_problem(), seed_tools.us_licence_no()));
select seed_tools.cat('handyman', 'home-services', seed_tools.l('Handyman', 'Mantenimiento general'),
  p_keywords => array['handyman','mount tv','assemble furniture','drywall','manitas'], p_icon => 'handyman', p_sort => 5,
  p_field_schema => seed_tools.schema(seed_tools.us_problem(),
    seed_tools.field('hours_estimate', 'number', seed_tools.l('Estimated hours', 'Horas estimadas'), false, 'request', null, '{"min":1,"max":80}')));
select seed_tools.cat('cleaning', 'home-services', seed_tools.l('House cleaning', 'Limpieza del hogar'),
  p_keywords => array['cleaning','house cleaning','maid','deep clean','limpieza'], p_icon => 'cleaning_services', p_sort => 6,
  p_field_schema => seed_tools.schema(seed_tools.us_property(), seed_tools.us_bedrooms(),
    seed_tools.field('frequency', 'select', seed_tools.l('How often', 'Frecuencia'), true, 'request',
      array[seed_tools.opt('once', 'One time', 'Una vez'), seed_tools.opt('weekly', 'Weekly', 'Semanal'), seed_tools.opt('biweekly', 'Every 2 weeks', 'Cada 2 semanas'), seed_tools.opt('move_out', 'Move-out clean', 'Limpieza de mudanza')])));
select seed_tools.cat('pest-control', 'home-services', seed_tools.l('Pest control', 'Control de plagas'),
  p_keywords => array['pest control','exterminator','termites','roaches','bed bugs','fumigación'], p_icon => 'pest_control', p_sort => 7,
  p_field_schema => seed_tools.schema(seed_tools.us_property(),
    seed_tools.field('pests', 'multiselect', seed_tools.l('Pests', 'Plagas'), true, 'request',
      array[seed_tools.opt('roaches', 'Roaches', 'Cucarachas'), seed_tools.opt('termites', 'Termites', 'Termitas'), seed_tools.opt('bedbugs', 'Bed bugs', 'Chinches'),
            seed_tools.opt('rodents', 'Rodents', 'Roedores'), seed_tools.opt('ants', 'Ants', 'Hormigas')])));
select seed_tools.cat('painting', 'home-services', seed_tools.l('Painting', 'Pintura'),
  p_keywords => array['painting','painter','paint','pintor'], p_icon => 'format_paint', p_sort => 8,
  p_field_schema => seed_tools.schema(seed_tools.us_property(), seed_tools.us_area(),
    seed_tools.field('paint_area', 'select', seed_tools.l('Interior or exterior', 'Interior o exterior'), false, 'request',
      array[seed_tools.opt('interior', 'Interior', 'Interior'), seed_tools.opt('exterior', 'Exterior', 'Exterior'), seed_tools.opt('both', 'Both', 'Ambos')])));
select seed_tools.cat('moving', 'home-services', seed_tools.l('Movers', 'Mudanzas'),
  p_keywords => array['movers','moving','moving company','mudanza'], p_icon => 'local_shipping', p_sort => 9,
  p_disclaimer => seed_tools.l('Interstate movers must show a USDOT number (FMCSA).', 'Las mudanzas interestatales deben mostrar un número USDOT (FMCSA).'),
  p_field_schema => seed_tools.schema(
    seed_tools.field('to_zip', 'text', seed_tools.l('Destination ZIP code', 'Código postal de destino'), true, 'request', null, '{"pattern":"^[0-9]{5}$"}'),
    seed_tools.us_property(), seed_tools.us_bedrooms(),
    seed_tools.field('usdot_number', 'text', seed_tools.l('USDOT number (interstate moves)', 'Número USDOT (mudanzas interestatales)'), false, 'quote')));
select seed_tools.cat('appliance-repair', 'home-services', seed_tools.l('Appliance repair', 'Reparación de electrodomésticos'),
  p_keywords => array['appliance repair','fridge repair','washer repair','dryer repair','reparación'], p_icon => 'build', p_sort => 10,
  p_field_schema => seed_tools.schema(
    seed_tools.field('appliance', 'select', seed_tools.l('Appliance', 'Electrodoméstico'), true, 'request',
      array[seed_tools.opt('fridge', 'Refrigerator', 'Refrigerador'), seed_tools.opt('washer', 'Washer', 'Lavadora'), seed_tools.opt('dryer', 'Dryer', 'Secadora'),
            seed_tools.opt('dishwasher', 'Dishwasher', 'Lavavajillas'), seed_tools.opt('oven', 'Oven / range', 'Horno / estufa'), seed_tools.opt('other', 'Other', 'Otro')]),
    seed_tools.field('brand', 'text', seed_tools.l('Brand', 'Marca')), seed_tools.us_problem()));

-- Vehicles ---------------------------------------------------------------------------------------------------------------------
select seed_tools.cat('new-cars', 'vehicles', seed_tools.l('New cars', 'Autos nuevos'),
  p_keywords => array['new car','car','suv','truck','pickup','auto nuevo'], p_icon => 'directions_car', p_sort => 1,
  p_field_schema => seed_tools.schema(
    seed_tools.field('model', 'text', seed_tools.l('Make and model', 'Marca y modelo'), true, 'both'),
    seed_tools.field('trim', 'text', seed_tools.l('Trim / color', 'Versión / color')),
    seed_tools.field('trade_in', 'boolean', seed_tools.l('Trade-in', 'Entregar mi auto'))));
select seed_tools.cat('vehicle-servicing', 'vehicles', seed_tools.l('Auto repair and service', 'Reparación y servicio de autos'),
  p_keywords => array['oil change','brakes','auto repair','car service','mechanic','mecánico'], p_icon => 'car_repair', p_sort => 2,
  p_field_schema => seed_tools.schema(
    seed_tools.field('model', 'text', seed_tools.l('Year, make and model', 'Año, marca y modelo'), true),
    seed_tools.field('mileage', 'number', seed_tools.l('Mileage', 'Millaje'), false, 'request', null, '{"min":0,"max":1000000}'),
    seed_tools.us_problem(false)));
select seed_tools.cat('tires', 'vehicles', seed_tools.l('Tires', 'Llantas'),
  p_keywords => array['tire','tires','tyres','llantas'], p_icon => 'tire_repair', p_sort => 3,
  p_field_schema => seed_tools.schema(
    seed_tools.field('tire_size', 'text', seed_tools.l('Tire size (e.g. 225/65R17)', 'Medida (ej. 225/65R17)'), true, 'both'),
    seed_tools.us_qty(), seed_tools.us_brands('Michelin', 'Goodyear', 'Bridgestone', 'Continental')));
select seed_tools.cat('used-vehicles', 'vehicles', seed_tools.l('Used vehicles', 'Vehículos usados'),
  p_keywords => array['used car','pre-owned','auto usado'], p_icon => 'garage', p_sort => 4,
  p_field_schema => seed_tools.schema(
    seed_tools.field('model', 'text', seed_tools.l('Make and model', 'Marca y modelo'), true, 'both'),
    seed_tools.field('year_min', 'number', seed_tools.l('Year (from)', 'Año (desde)'), false, 'request', null, '{"min":1980,"max":2100}'),
    seed_tools.field('max_miles', 'number', seed_tools.l('Max miles', 'Millas máximas'), false, 'request', null, '{"min":0,"max":1000000}'),
    seed_tools.field('dealer_licence', 'text', seed_tools.l('Dealer licence number', 'Licencia de concesionario'), false, 'quote')));

-- Events -------------------------------------------------------------------------------------------------------------------------
select seed_tools.cat('catering', 'events', seed_tools.l('Catering', 'Catering'),
  p_keywords => array['catering','caterer','banquete'], p_icon => 'restaurant', p_sort => 1,
  p_field_schema => seed_tools.schema(seed_tools.us_guests(), seed_tools.us_event_date(),
    seed_tools.field('service_style', 'select', seed_tools.l('Service style', 'Estilo de servicio'), false, 'request',
      array[seed_tools.opt('buffet', 'Buffet', 'Bufé'), seed_tools.opt('plated', 'Plated', 'Servido a la mesa'), seed_tools.opt('drop_off', 'Drop-off', 'Entrega')]),
    seed_tools.field('dietary', 'text', seed_tools.l('Dietary needs', 'Necesidades alimentarias'))));
select seed_tools.cat('photography', 'events', seed_tools.l('Photography', 'Fotografía'),
  p_keywords => array['photographer','photography','videographer','fotógrafo'], p_icon => 'photo_camera', p_sort => 2,
  p_field_schema => seed_tools.schema(seed_tools.us_event_date(),
    seed_tools.field('event_type', 'select', seed_tools.l('Event', 'Evento'), true, 'request',
      array[seed_tools.opt('wedding', 'Wedding', 'Boda'), seed_tools.opt('birthday', 'Birthday', 'Cumpleaños'), seed_tools.opt('corporate', 'Corporate', 'Corporativo'), seed_tools.opt('headshots', 'Headshots', 'Retratos')]),
    seed_tools.field('hours', 'number', seed_tools.l('Hours', 'Horas'), false, 'request', null, '{"min":1,"max":72}')));
select seed_tools.cat('decoration', 'events', seed_tools.l('Decor and rentals', 'Decoración y alquileres'),
  p_keywords => array['decor','balloons','party rentals','decoración'], p_icon => 'celebration', p_sort => 3,
  p_field_schema => seed_tools.schema(seed_tools.us_event_date(), seed_tools.field('theme', 'text', seed_tools.l('Theme', 'Tema'))));
select seed_tools.cat('venues', 'events', seed_tools.l('Venues', 'Lugares para eventos'),
  p_keywords => array['venue','event space','banquet hall','salón'], p_icon => 'location_city', p_sort => 4,
  p_field_schema => seed_tools.schema(seed_tools.us_guests(), seed_tools.us_event_date()));

-- Business supplies -----------------------------------------------------------------------------------------------------------------
select seed_tools.cat('printing', 'business-supplies', seed_tools.l('Printing', 'Impresión'),
  p_keywords => array['printing','print','t-shirts','business cards','flyers','banners','impresión'], p_icon => 'print', p_sort => 1,
  p_field_schema => seed_tools.schema(
    seed_tools.field('item', 'select', seed_tools.l('What to print', 'Qué imprimir'), true, 'both',
      array[seed_tools.opt('tshirts', 'T-shirts', 'Camisetas'), seed_tools.opt('cards', 'Business cards', 'Tarjetas de presentación'), seed_tools.opt('flyers', 'Flyers', 'Volantes'),
            seed_tools.opt('banners', 'Banners / signs', 'Pancartas / letreros'), seed_tools.opt('stickers', 'Stickers', 'Calcomanías'), seed_tools.opt('other', 'Other', 'Otro')]),
    seed_tools.field('quantity', 'number', seed_tools.l('Quantity', 'Cantidad'), true, 'request', null, '{"min":1,"max":1000000}'),
    seed_tools.field('size', 'text', seed_tools.l('Size / specs', 'Tamaño / especificaciones'))));
select seed_tools.cat('packaging', 'business-supplies', seed_tools.l('Packaging', 'Empaques'),
  p_keywords => array['packaging','boxes','mailers','shipping boxes','cajas'], p_icon => 'inventory', p_sort => 2,
  p_field_schema => seed_tools.schema(
    seed_tools.field('pack_type', 'select', seed_tools.l('Type', 'Tipo'), true, 'both',
      array[seed_tools.opt('boxes', 'Boxes', 'Cajas'), seed_tools.opt('mailers', 'Mailers', 'Sobres'), seed_tools.opt('tape', 'Tape', 'Cinta'), seed_tools.opt('bubble', 'Bubble wrap', 'Plástico de burbujas')]),
    seed_tools.field('quantity', 'number', seed_tools.l('Quantity', 'Cantidad'), true, 'request', null, '{"min":1,"max":10000000}'),
    seed_tools.field('dimensions', 'text', seed_tools.l('Dimensions', 'Dimensiones'))));
select seed_tools.cat('office-supplies', 'business-supplies', seed_tools.l('Bulk office supplies', 'Artículos de oficina al por mayor'),
  p_keywords => array['office supplies','paper','toner','artículos de oficina'], p_icon => 'business_center', p_sort => 3,
  p_field_schema => seed_tools.schema(seed_tools.field('items', 'text', seed_tools.l('Items and quantities', 'Artículos y cantidades'), true, 'request', null, '{"multiline":true}')));
select seed_tools.cat('uniforms', 'business-supplies', seed_tools.l('Uniforms and workwear', 'Uniformes'),
  p_keywords => array['uniform','uniforms','scrubs','workwear','uniformes'], p_icon => 'checkroom', p_sort => 4,
  p_field_schema => seed_tools.schema(
    seed_tools.field('uniform_type', 'select', seed_tools.l('Type', 'Tipo'), true, 'request',
      array[seed_tools.opt('school', 'School', 'Escolar'), seed_tools.opt('corporate', 'Corporate', 'Corporativo'), seed_tools.opt('hospitality', 'Restaurant / hotel', 'Restaurante / hotel'), seed_tools.opt('medical', 'Medical scrubs', 'Uniformes médicos')]),
    seed_tools.field('quantity', 'number', seed_tools.l('Quantity', 'Cantidad'), true, 'request', null, '{"min":1,"max":100000}'),
    seed_tools.field('sizes', 'text', seed_tools.l('Sizes', 'Tallas'))));

-- Restricted / blocked leaves -------------------------------------------------------------------------------------------------------
select seed_tools.cat('rentals', 'real-estate', seed_tools.l('Rent a home', 'Alquilar vivienda'), 'restricted', 'state_real_estate_licence',
  p_keywords => array['apartment for rent','rental','lease','alquiler'], p_sort => 1,
  p_field_schema => seed_tools.schema(seed_tools.us_property(), seed_tools.us_bedrooms(),
    seed_tools.field('licence_number', 'text', seed_tools.l('Real estate licence number', 'Número de licencia inmobiliaria'), true, 'quote')));
select seed_tools.cat('buy-home', 'real-estate', seed_tools.l('Buy a home', 'Comprar vivienda'), 'restricted', 'state_real_estate_licence',
  p_keywords => array['buy a house','realtor','real estate agent','comprar casa'], p_sort => 2,
  p_field_schema => seed_tools.schema(seed_tools.us_property(), seed_tools.us_bedrooms(),
    seed_tools.field('licence_number', 'text', seed_tools.l('Real estate licence number', 'Número de licencia inmobiliaria'), true, 'quote')));
select seed_tools.cat('lawyers', 'legal-services', seed_tools.l('Lawyers', 'Abogados'), 'restricted', 'state_bar_admission',
  p_keywords => array['lawyer','attorney','will','llc formation','abogado'], p_sort => 1,
  p_field_schema => seed_tools.schema(
    seed_tools.field('practice_area', 'select', seed_tools.l('Practice area', 'Área de práctica'), true, 'request',
      array[seed_tools.opt('wills', 'Wills and estates', 'Testamentos'), seed_tools.opt('business', 'Business formation', 'Constitución de empresas'),
            seed_tools.opt('immigration', 'Immigration', 'Inmigración'), seed_tools.opt('real_estate', 'Real estate closing', 'Cierre inmobiliario'), seed_tools.opt('other', 'Other', 'Otro')]),
    seed_tools.field('bar_number', 'text', seed_tools.l('State bar number', 'Número de colegiatura'), true, 'quote')));
select seed_tools.cat('medical-providers', 'health', seed_tools.l('Doctor, dentist or therapist', 'Médico, dentista o terapeuta'), 'restricted', 'state_medical_licence',
  p_keywords => array['doctor','dentist','physical therapy','chiropractor','dentista'], p_sort => 1,
  p_field_schema => seed_tools.schema(
    seed_tools.field('specialty', 'text', seed_tools.l('Specialty needed', 'Especialidad'), true),
    seed_tools.field('npi', 'text', seed_tools.l('NPI / licence number', 'NPI / número de licencia'), true, 'quote')));
select seed_tools.cat('health-insurance', 'insurance', seed_tools.l('Health insurance', 'Seguro médico'), 'blocked', 'state_insurance_producer', p_sort => 1);
select seed_tools.cat('auto-insurance', 'insurance', seed_tools.l('Auto insurance', 'Seguro de auto'), 'blocked', 'state_insurance_producer', p_sort => 2);
select seed_tools.cat('life-insurance', 'insurance', seed_tools.l('Life insurance', 'Seguro de vida'), 'blocked', 'state_insurance_producer', p_sort => 3);
select seed_tools.cat('home-insurance', 'insurance', seed_tools.l('Home insurance', 'Seguro de hogar'), 'blocked', 'state_insurance_producer', p_sort => 4);
select seed_tools.cat('loans', 'finance', seed_tools.l('Loans', 'Préstamos'), 'blocked', p_sort => 1);
select seed_tools.cat('credit-cards', 'finance', seed_tools.l('Credit cards', 'Tarjetas de crédito'), 'blocked', p_sort => 2);
select seed_tools.cat('investments', 'finance', seed_tools.l('Investments, securities and crypto', 'Inversiones, valores y cripto'), 'blocked', p_sort => 3);
select seed_tools.cat('medicines', 'pharmacy', seed_tools.l('Medicines', 'Medicamentos'), 'blocked', p_sort => 1);
select seed_tools.cat('alcohol', 'alcohol-tobacco', seed_tools.l('Alcohol', 'Alcohol'), 'blocked', p_sort => 1);
select seed_tools.cat('tobacco-vapes', 'alcohol-tobacco', seed_tools.l('Tobacco and vapes', 'Tabaco y vapeadores'), 'blocked', p_sort => 2);
select seed_tools.cat('firearms', 'weapons', seed_tools.l('Firearms and ammunition', 'Armas de fuego y municiones'), 'blocked', p_sort => 1);

-- Blocked-keyword classifier -----------------------------------------------------------------------------------------------------------
select seed_tools.block_kw('insurance', 'en', 'insurance', 'insurance quote', 'car insurance', 'auto insurance', 'health insurance',
  'life insurance', 'homeowners insurance', 'renters insurance');
select seed_tools.block_kw('insurance', 'es', 'póliza de seguro', 'seguro de auto', 'seguro médico', 'aseguranza');
select seed_tools.block_kw('finance', 'en', 'loan', 'payday loan', 'personal loan', 'mortgage', 'refinance', 'credit card',
  'debt consolidation', 'credit repair', 'crypto', 'bitcoin', 'stock tips', 'forex');
select seed_tools.block_kw('finance', 'es', 'préstamo', 'prestamo', 'hipoteca', 'tarjeta de crédito', 'criptomoneda');
select seed_tools.block_kw('pharmacy', 'en', 'prescription', 'prescription drugs', 'medication', 'medicine', 'painkillers',
  'antibiotics', 'adderall', 'oxycodone', 'ozempic');
select seed_tools.block_kw('pharmacy', 'es', 'medicamento', 'medicamentos', 'receta médica');
select seed_tools.block_kw('alcohol-tobacco', 'en', 'alcohol', 'liquor', 'beer', 'wine', 'whiskey', 'vodka', 'cigarette',
  'cigarettes', 'tobacco', 'vape', 'e-cigarette', 'juul', 'nicotine pouches');
select seed_tools.block_kw('alcohol-tobacco', 'es', 'cerveza', 'licor', 'cigarrillo', 'cigarrillos', 'tabaco', 'vapeador');
select seed_tools.block_kw('weapons', 'en', 'gun', 'guns', 'pistol', 'handgun', 'rifle', 'shotgun', 'firearm', 'ammo',
  'ammunition', 'ar-15', 'ghost gun', 'suppressor');
select seed_tools.block_kw('weapons', 'es', 'arma', 'armas', 'pistola', 'rifle', 'munición', 'municiones');
insert into public.category_keywords (keyword, lang, action, reason) values
  ('marijuana', 'en', 'block', seed_tools.l('Drugs cannot be requested.', 'No se pueden solicitar drogas.')),
  ('cannabis', 'en', 'block', seed_tools.l('Drugs cannot be requested.', 'No se pueden solicitar drogas.')),
  ('escort', 'en', 'block', seed_tools.l('Adult services cannot be requested.', 'No se pueden solicitar servicios para adultos.')),
  ('fake id', 'en', 'block', seed_tools.l('Counterfeit documents cannot be requested.', 'No se pueden solicitar documentos falsos.')),
  ('marihuana', 'es', 'block', seed_tools.l('Drugs cannot be requested.', 'No se pueden solicitar drogas.'))
on conflict (keyword, lang, action) do nothing;

-- ZIP codes for the demo cities (full set: tool/data/import_us_zcta.py) ------------------------------------------------------------------
select seed_tools.pc('10001', 40.7506, -73.9972, 'New York', 'Chelsea', 'New York', 'NY');
select seed_tools.pc('10011', 40.7418, -74.0002, 'New York', 'West Village', 'New York', 'NY');
select seed_tools.pc('10016', 40.7459, -73.9781, 'New York', 'Murray Hill', 'New York', 'NY');
select seed_tools.pc('10025', 40.7987, -73.9682, 'New York', 'Upper West Side', 'New York', 'NY');
select seed_tools.pc('11201', 40.6955, -73.9893, 'Brooklyn', 'Brooklyn Heights', 'New York', 'NY');
select seed_tools.pc('11215', 40.6627, -73.9860, 'Brooklyn', 'Park Slope', 'New York', 'NY');
select seed_tools.pc('11101', 40.7471, -73.9393, 'Long Island City', 'Queens', 'New York', 'NY');
select seed_tools.pc('07302', 40.7196, -74.0466, 'Jersey City', 'Downtown', 'New Jersey', 'NJ');
select seed_tools.pc('75201', 32.7876, -96.7994, 'Dallas', 'Downtown', 'Texas', 'TX');
select seed_tools.pc('75204', 32.8031, -96.7880, 'Dallas', 'Uptown', 'Texas', 'TX');
select seed_tools.pc('75205', 32.8361, -96.7962, 'Dallas', 'Highland Park', 'Texas', 'TX');
select seed_tools.pc('75206', 32.8311, -96.7703, 'Dallas', 'Lower Greenville', 'Texas', 'TX');
select seed_tools.pc('75214', 32.8244, -96.7489, 'Dallas', 'Lakewood', 'Texas', 'TX');
select seed_tools.pc('75219', 32.8106, -96.8125, 'Dallas', 'Oak Lawn', 'Texas', 'TX');
select seed_tools.pc('75230', 32.8999, -96.7897, 'Dallas', 'North Dallas', 'Texas', 'TX');

-- Priority metros (outreach ordering only; launch is nationwide) ---------------------------------------------------------------------------
select seed_tools.city('New York', 'New York', 'NY', 40.7128, -74.0060, 8335897, 'America/New_York', 1);
select seed_tools.city('Los Angeles', 'California', 'CA', 34.0522, -118.2437, 3822238, 'America/Los_Angeles', 2);
select seed_tools.city('Chicago', 'Illinois', 'IL', 41.8781, -87.6298, 2665039, 'America/Chicago', 3);
select seed_tools.city('Dallas', 'Texas', 'TX', 32.7767, -96.7970, 1299544, 'America/Chicago', 4);
select seed_tools.city('Houston', 'Texas', 'TX', 29.7604, -95.3698, 2302878, 'America/Chicago', 5);
select seed_tools.city('Phoenix', 'Arizona', 'AZ', 33.4484, -112.0740, 1644409, 'America/Phoenix', 6);
select seed_tools.city('Atlanta', 'Georgia', 'GA', 33.7490, -84.3880, 499127, 'America/New_York', 7);
select seed_tools.city('Miami', 'Florida', 'FL', 25.7617, -80.1918, 449514, 'America/New_York', 8);
