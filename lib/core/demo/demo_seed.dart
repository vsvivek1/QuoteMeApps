import '../../features/requests/domain/category.dart';
import '../config/country_config.dart';

/// Category tree used by demo mode (no backend configured) and tests.
/// The real trees live in `supabase/seed/<country>.sql`.
List<Category> demoCategories(Country country) {
  final india = country == Country.india;
  var id = 0;
  final out = <Category>[];

  Map<String, String> n(String en, String hi, String es) =>
      india ? {'en': en, 'hi': hi} : {'en': en, 'es': es};

  FieldDef select(String key, String en, String hi, String es, List<String> options,
          {bool required = false}) =>
      FieldDef(
        key: key,
        type: FieldType.select,
        labels: n(en, hi, es),
        options: [for (final o in options) FieldOption(value: o, labels: {'en': o})],
        required: required,
      );
  FieldDef number(String key, String en, String hi, String es, {String? unit, bool required = false}) =>
      FieldDef(key: key, type: FieldType.number, labels: n(en, hi, es), unit: unit, required: required);
  FieldDef text(String key, String en, String hi, String es) =>
      FieldDef(key: key, type: FieldType.text, labels: n(en, hi, es));

  int parent(String en, String hi, String es, String icon,
      {CategoryPolicy policy = CategoryPolicy.allowed, Map<String, String> disclaimer = const {}}) {
    final pid = ++id;
    out.add(Category(id: pid, names: n(en, hi, es), icon: icon, policy: policy, disclaimer: disclaimer, sort: pid));
    return pid;
  }

  void leaf(int p, String en, String hi, String es, List<FieldDef> fields,
      {List<String> keywords = const [],
      CategoryPolicy policy = CategoryPolicy.allowed,
      String? licence,
      Map<String, String> disclaimer = const {}}) {
    out.add(Category(
      id: ++id,
      parentId: p,
      names: n(en, hi, es),
      fields: fields,
      keywords: [en.toLowerCase(), ...keywords],
      policy: policy,
      requiredLicenceType: licence,
      disclaimer: disclaimer,
    ));
  }

  final brand = text('brand', 'Preferred brand', 'पसंदीदा ब्रांड', 'Marca preferida');
  final units = number('units', 'Number of units', 'यूनिट की संख्या', 'Número de unidades', required: true);
  final problem = text('problem', 'Describe the problem', 'समस्या बताएं', 'Describa el problema');

  final appliances = parent('Appliances', 'घरेलू उपकरण', 'Electrodomésticos', 'kitchen');
  leaf(appliances, 'Refrigerators', 'फ्रिज', 'Refrigeradores', [
    number('capacity_l', 'Capacity', 'क्षमता', 'Capacidad', unit: 'L', required: true),
    select('door_type', 'Door type', 'दरवाज़े का प्रकार', 'Tipo de puerta',
        ['Single door', 'Double door', 'Side by side', 'French door']),
    brand,
    select('energy_rating', india ? 'Energy rating (BEE stars)' : 'Energy Star', 'ऊर्जा रेटिंग', 'Energy Star',
        india ? ['3 star', '4 star', '5 star'] : ['Energy Star certified', 'Not required']),
  ], keywords: ['fridge', 'refrigerator', 'freezer', 'फ्रिज']);
  leaf(appliances, 'Washing machines', 'वॉशिंग मशीन', 'Lavadoras', [
    number('capacity_kg', 'Capacity', 'क्षमता', 'Capacidad', unit: 'kg'),
    select('load', 'Load type', 'लोड प्रकार', 'Tipo de carga', ['Front load', 'Top load']),
    brand,
  ], keywords: ['washing machine', 'washer']);
  leaf(appliances, india ? 'Air conditioners' : 'Air conditioners', 'एयर कंडीशनर', 'Aires acondicionados', [
    select('ac_type', 'Type', 'प्रकार', 'Tipo', ['Split', 'Window', 'Portable']),
    number('tonnage', 'Capacity (ton)', 'क्षमता (टन)', 'Capacidad (ton)'),
    units,
    brand,
  ], keywords: ['ac', 'air conditioner', 'एसी']);
  leaf(appliances, 'TVs', 'टीवी', 'Televisores', [
    number('size_in', 'Screen size', 'स्क्रीन साइज़', 'Tamaño de pantalla', unit: 'in'),
    brand,
  ], keywords: ['tv', 'television', 'टीवी']);
  if (india) {
    leaf(appliances, 'Water purifiers', 'वॉटर प्यूरीफायर', '', [
      select('tech', 'Technology', 'तकनीक', '', ['RO', 'UV', 'RO+UV']),
      brand,
    ], keywords: ['ro', 'water purifier', 'aquaguard']);
    leaf(appliances, 'Inverters and batteries', 'इन्वर्टर और बैटरी', '', [
      number('va', 'Capacity', 'क्षमता', '', unit: 'VA'),
    ], keywords: ['inverter', 'battery', 'ups']);
  } else {
    leaf(appliances, 'Dishwashers', '', 'Lavavajillas', [brand], keywords: ['dishwasher']);
  }

  final electronics = parent('Electronics', 'इलेक्ट्रॉनिक्स', 'Electrónica', 'devices');
  leaf(electronics, 'Phones', 'फ़ोन', 'Teléfonos', [brand, text('model', 'Model', 'मॉडल', 'Modelo')],
      keywords: ['phone', 'mobile', 'iphone', 'samsung']);
  leaf(electronics, 'Laptops', 'लैपटॉप', 'Portátiles', [brand, text('specs', 'Specs', 'स्पेसिफिकेशन', 'Especificaciones')],
      keywords: ['laptop', 'notebook', 'macbook']);

  final home = parent('Furniture and home', 'फर्नीचर और घर', 'Muebles y hogar', 'chair');
  leaf(home, 'Sofas', 'सोफा', 'Sofás', [number('seats', 'Seats', 'सीटें', 'Plazas')], keywords: ['sofa', 'couch']);
  leaf(home, 'Mattresses', 'गद्दे', 'Colchones', [
    select('size', 'Size', 'साइज़', 'Tamaño', india ? ['Single', 'Double', 'Queen', 'King'] : ['Twin', 'Full', 'Queen', 'King']),
  ], keywords: ['mattress']);

  final services = parent('Home services', 'घरेलू सेवाएं', 'Servicios para el hogar', 'home_repair_service');
  leaf(services, 'AC repair and service', 'एसी रिपेयर और सर्विस', 'Reparación de aire acondicionado',
      [units, problem], keywords: ['ac repair', 'ac service', 'gas refill', 'hvac']);
  leaf(services, 'Plumbing', 'प्लंबिंग', 'Plomería', [problem], keywords: ['plumber', 'leak', 'tap', 'pipe'],
      policy: india ? CategoryPolicy.allowed : CategoryPolicy.restricted,
      licence: india ? null : 'contractor_licence');
  leaf(services, 'Electrical', 'इलेक्ट्रिकल', 'Electricidad', [problem], keywords: ['electrician', 'wiring'],
      policy: india ? CategoryPolicy.allowed : CategoryPolicy.restricted,
      licence: india ? null : 'contractor_licence');
  leaf(services, 'Cleaning', 'सफाई', 'Limpieza', [number('rooms', 'Rooms', 'कमरे', 'Habitaciones')],
      keywords: ['cleaning', 'deep clean', 'maid']);
  leaf(services, 'Pest control', 'पेस्ट कंट्रोल', 'Control de plagas', [problem], keywords: ['pest', 'termite', 'cockroach']);
  leaf(services, india ? 'Packers and movers' : 'Moving', 'पैकर्स और मूवर्स', 'Mudanzas', [
    text('from', 'Moving from', 'कहाँ से', 'Desde'),
    text('to', 'Moving to', 'कहाँ तक', 'Hasta'),
    select('home_size', 'Home size', 'घर का आकार', 'Tamaño', india ? ['1 BHK', '2 BHK', '3 BHK', '4+ BHK'] : ['Studio', '1 bed', '2 bed', '3+ bed']),
  ], keywords: ['movers', 'packers', 'shifting', 'moving']);
  if (!india) {
    leaf(services, 'Roofing', '', 'Techos', [problem], keywords: ['roof', 'roofing', 'shingles'],
        policy: CategoryPolicy.restricted, licence: 'contractor_licence');
    leaf(services, 'Handyman', '', 'Manitas', [problem], keywords: ['handyman', 'fix', 'mount tv']);
  }

  final vehicles = parent('Vehicles', 'वाहन', 'Vehículos', 'directions_car');
  leaf(vehicles, 'New car', 'नई कार', 'Auto nuevo', [brand, text('model', 'Model', 'मॉडल', 'Modelo')], keywords: ['car', 'suv']);
  leaf(vehicles, 'Servicing', 'सर्विसिंग', 'Servicio', [text('vehicle', 'Vehicle', 'वाहन', 'Vehículo')], keywords: ['car service', 'bike service']);
  leaf(vehicles, 'Tyres', 'टायर', 'Llantas', [text('size', 'Tyre size', 'टायर साइज़', 'Medida')], keywords: ['tyre', 'tire']);

  final events = parent('Events', 'इवेंट', 'Eventos', 'celebration');
  leaf(events, 'Catering', 'कैटरिंग', 'Catering', [number('guests', 'Guests', 'मेहमान', 'Invitados', required: true)], keywords: ['catering', 'food']);
  leaf(events, 'Photography', 'फोटोग्राफी', 'Fotografía', [number('hours', 'Hours', 'घंटे', 'Horas')], keywords: ['photographer', 'photography']);

  final business = parent('Business supplies', 'व्यापार सामग्री', 'Suministros para empresas', 'inventory_2');
  leaf(business, 'Printing', 'प्रिंटिंग', 'Impresión', [number('qty', 'Quantity', 'मात्रा', 'Cantidad', required: true), text('item', 'Item', 'आइटम', 'Artículo')],
      keywords: ['printing', 't-shirts', 'visiting cards', 'flyers']);
  leaf(business, 'Uniforms', 'यूनिफॉर्म', 'Uniformes', [number('qty', 'Quantity', 'मात्रा', 'Cantidad')], keywords: ['uniform']);

  final regulated = parent('Regulated services', 'विनियमित सेवाएं', 'Servicios regulados', 'gavel');
  leaf(regulated, 'Insurance', 'बीमा', 'Seguros', [], keywords: ['insurance', 'policy', 'बीमा', 'seguro'],
      policy: CategoryPolicy.blocked);
  leaf(regulated, 'Loans and credit', 'ऋण और क्रेडिट', 'Préstamos y crédito', [],
      keywords: ['loan', 'credit card', 'emi', 'mortgage'], policy: CategoryPolicy.blocked);
  leaf(regulated, 'Medicines', 'दवाइयाँ', 'Medicamentos', [], keywords: ['medicine', 'pharmacy', 'tablets'],
      policy: CategoryPolicy.blocked);
  leaf(regulated, india ? 'Legal services' : 'Legal services', 'कानूनी सेवाएं', 'Servicios legales', [problem],
      keywords: ['lawyer', 'advocate', 'attorney'],
      policy: india ? CategoryPolicy.blocked : CategoryPolicy.restricted,
      licence: india ? null : 'state_bar',
      disclaimer: india
          ? const {}
          : const {'en': 'Attorney advertising. Prior results do not guarantee a similar outcome.', 'es': 'Publicidad de abogados. Los resultados previos no garantizan un resultado similar.'});
  leaf(regulated, 'Real estate', 'रियल एस्टेट', 'Bienes raíces', [problem],
      keywords: ['flat', 'apartment', 'house for sale', 'rent'],
      policy: CategoryPolicy.restricted, licence: india ? 'rera' : 'real_estate_licence');

  final other = parent('Other', 'अन्य', 'Otro', 'more_horiz');
  leaf(other, 'Something else', 'कुछ और', 'Otra cosa', [], keywords: []);
  return out;
}
