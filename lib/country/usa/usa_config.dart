import 'dart:ui';

import '../../core/config/country_config.dart';
import '../../core/money/tax.dart';
import '../../core/utils/validators.dart';

/// I Want USA. Calecute Technologies LLC.
const usaConfig = CountryConfig(
  country: Country.usa,
  appName: 'I Want USA',
  legalEntity: 'Calecute Technologies LLC',
  currencyCode: 'USD',
  phoneDialCode: '+1',
  phoneHint: '(212) 555-0123',
  phoneValidator: Validators.usPhone,
  postalCodeValidator: Validators.usZip,
  postalCodeMaxLength: 10,
  supportedLocales: [Locale('en', 'US'), Locale('es', 'US')],
  defaultLocale: Locale('en', 'US'),
  taxRule: SalesTaxRule(),
  verificationDocs: [
    VerificationDocSpec(
      type: 'ein',
      labelKey: 'docEin',
      validator: Validators.ein,
      needsFile: false,
    ),
    VerificationDocSpec(
      type: 'state_licence',
      labelKey: 'docStateLicence',
      validator: Validators.licenceNumber,
    ),
    VerificationDocSpec(
      type: 'business_address',
      labelKey: 'docBusinessAddress',
      validator: _nonEmpty,
      required: true,
      needsFile: false,
    ),
    VerificationDocSpec(
      type: 'website',
      labelKey: 'docWebsite',
      validator: _nonEmpty,
      needsFile: false,
    ),
  ],
  paymentProvider: PaymentProvider.stripe,
  offPlatformPaymentMethods: ['card', 'cash', 'zelle', 'check', 'seller_link'],
  webDomain: 'iwantusa.app',
  states: _usStates,
  demoCities: [
    DemoCity('New York', 'New York', LatLng(40.7128, -74.0060), '10001'),
    DemoCity('Dallas', 'Texas', LatLng(32.7767, -96.7970), '75201'),
  ],
  defaultRadiusKm: 40,
  distanceUnitMiles: true,
  freeQuotesPerMonth: 5,
  lowEndDeviceMode: false,
  accentSeed: Color(0xFF1D4ED8),
  minimumAge: 18,
  playStoreUrl: 'https://play.google.com/store/apps/details?id=com.calecute.iwant.usa',
  appStoreUrl: 'https://apps.apple.com/us/app/i-want-usa/id0000000000',
);

bool _nonEmpty(String v) => v.trim().isNotEmpty;

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
