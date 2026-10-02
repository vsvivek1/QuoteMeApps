import 'dart:ui';

enum Country { usa, india }

/// A city in the outreach priority order (Section 21: processed first, never
/// excluding anywhere else).
class PriorityCity {
  const PriorityCity(this.name, this.state, this.timezone);
  final String name;
  final String state;
  final String timezone;
}

/// Everything country-specific the admin panel needs. Mirrors the main app's
/// `CountryConfig` (lib/core/config/country_config.dart); widgets read from
/// here and never branch on the country themselves.
class AdminCountryConfig {
  const AdminCountryConfig({
    required this.country,
    required this.appName,
    required this.legalEntity,
    required this.currencyCode,
    required this.locale,
    required this.webDomain,
    required this.businessAddress,
    required this.defaultTimezone,
    required this.brochureLanguages,
    required this.outreachChannels,
    required this.manualWhatsAppFirstContact,
    required this.priorityCities,
    required this.states,
    required this.verificationDocTypes,
    required this.optOutLine,
    required this.brandPrimary,
    required this.brandPrimaryDark,
    required this.logoAsset,
  });

  final Country country;
  final String appName;
  final String legalEntity;
  final String currencyCode;
  final Locale locale;
  final String webDomain;

  /// Physical postal address in every outreach email (CAN-SPAM, rule 8).
  /// A placeholder until the real address is configured.
  final String businessAddress;
  final String defaultTimezone;

  /// Languages the PDF generator can render with the built-in fonts.
  final List<String> brochureLanguages;

  /// Channels the outreach engine may automate (after opt-in for WhatsApp).
  final List<String> outreachChannels;

  /// India: first contact is a manual 1:1 wa.me message (21.3).
  final bool manualWhatsAppFirstContact;
  final List<PriorityCity> priorityCities;
  final List<String> states;
  final List<String> verificationDocTypes;

  /// Plain opt-out line required in every outreach message (rule 5).
  final String optOutLine;
  final Color brandPrimary;
  final Color brandPrimaryDark;
  final String logoAsset;

  String get countryCode => country == Country.india ? 'IN' : 'US';

  Uri get privacyUrl => Uri.https(webDomain, '/legal/privacy');
  Uri get websiteUrl => Uri.https(webDomain, '/');

  /// Seller signup link with UTM tags (brochures, email, WhatsApp).
  Uri signupUrl({
    required String source,
    required String medium,
    String? campaign,
    String? city,
    String? category,
    String? token,
  }) =>
      Uri.https(webDomain, '/sell', {
        if (city != null && city.isNotEmpty) 'city': city,
        if (category != null && category.isNotEmpty) 'category': category,
        if (token != null && token.isNotEmpty) 't': token,
        'utm_source': source,
        'utm_medium': medium,
        if (campaign != null && campaign.isNotEmpty) 'utm_campaign': campaign,
      });

  static AdminCountryConfig forCode(String code) =>
      code.toLowerCase() == 'india' || code.toUpperCase() == 'IN' ? india : usa;

  static const usa = AdminCountryConfig(
    country: Country.usa,
    appName: 'I Want USA',
    legalEntity: 'Calecute Technologies LLC',
    currencyCode: 'USD',
    locale: Locale('en', 'US'),
    webDomain: 'iwantusa.app',
    businessAddress: '{{US_BUSINESS_ADDRESS}}',
    defaultTimezone: 'America/New_York',
    brochureLanguages: ['en', 'es'],
    outreachChannels: ['email'],
    manualWhatsAppFirstContact: false,
    priorityCities: [
      PriorityCity('New York', 'New York', 'America/New_York'),
      PriorityCity('Los Angeles', 'California', 'America/Los_Angeles'),
      PriorityCity('Chicago', 'Illinois', 'America/Chicago'),
      PriorityCity('Dallas', 'Texas', 'America/Chicago'),
      PriorityCity('Houston', 'Texas', 'America/Chicago'),
      PriorityCity('Phoenix', 'Arizona', 'America/Phoenix'),
      PriorityCity('Atlanta', 'Georgia', 'America/New_York'),
      PriorityCity('Miami', 'Florida', 'America/New_York'),
    ],
    states: _usStates,
    verificationDocTypes: ['ein', 'state_license', 'business_address', 'website', 'other'],
    optOutLine: "Reply 'no thanks' and we won't contact you again.",
    brandPrimary: Color(0xFF1D4ED8),
    brandPrimaryDark: Color(0xFF93B4FF),
    logoAsset: 'assets/branding/usa/logo_mark_1024.png',
  );

  static const india = AdminCountryConfig(
    country: Country.india,
    appName: 'I Want India',
    legalEntity: 'Calecute Technologies (OPC) Private Limited',
    currencyCode: 'INR',
    locale: Locale('en', 'IN'),
    webDomain: 'iwantindia.app',
    businessAddress: '{{IN_BUSINESS_ADDRESS}}',
    defaultTimezone: 'Asia/Kolkata',
    // Hindi needs complex-script shaping the pdf package does not do yet
    // (see admin/BACKEND_NEEDS.md, "Blockers").
    brochureLanguages: ['en'],
    outreachChannels: ['email', 'whatsapp'],
    manualWhatsAppFirstContact: true,
    priorityCities: [
      PriorityCity('Bengaluru', 'Karnataka', 'Asia/Kolkata'),
      PriorityCity('Mumbai', 'Maharashtra', 'Asia/Kolkata'),
      PriorityCity('Delhi', 'Delhi', 'Asia/Kolkata'),
      PriorityCity('Hyderabad', 'Telangana', 'Asia/Kolkata'),
      PriorityCity('Chennai', 'Tamil Nadu', 'Asia/Kolkata'),
      PriorityCity('Pune', 'Maharashtra', 'Asia/Kolkata'),
      PriorityCity('Kolkata', 'West Bengal', 'Asia/Kolkata'),
      PriorityCity('Ahmedabad', 'Gujarat', 'Asia/Kolkata'),
    ],
    states: _indiaStates,
    verificationDocTypes: ['gstin', 'udyam', 'pan', 'shop_photo', 'business_address', 'other'],
    optOutLine: "Reply STOP or 'no thanks' and we won't contact you again.",
    brandPrimary: Color(0xFFC2410C),
    brandPrimaryDark: Color(0xFFFFB077),
    logoAsset: 'assets/branding/india/logo_mark_1024.png',
  );
}

const _usStates = [
  'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
  'Connecticut', 'Delaware', 'District of Columbia', 'Florida', 'Georgia',
  'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky',
  'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
  'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire',
  'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota',
  'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island',
  'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont',
  'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming',
];

const _indiaStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
  'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
  'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  'Andaman and Nicobar Islands', 'Chandigarh',
  'Dadra and Nagar Haveli and Daman and Diu', 'Delhi', 'Jammu and Kashmir',
  'Ladakh', 'Lakshadweep', 'Puducherry',
];
