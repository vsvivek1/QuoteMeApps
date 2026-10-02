import 'dart:ui';

import '../../core/config/country_config.dart';
import '../../core/money/tax.dart';
import '../../core/utils/validators.dart';

/// I Want India. Calecute Technologies (OPC) Private Limited.
const indiaConfig = CountryConfig(
  country: Country.india,
  appName: 'I Want India',
  legalEntity: 'Calecute Technologies (OPC) Private Limited',
  currencyCode: 'INR',
  phoneDialCode: '+91',
  phoneHint: '98765 43210',
  phoneValidator: Validators.indiaMobile,
  postalCodeValidator: Validators.indiaPin,
  postalCodeMaxLength: 6,
  supportedLocales: [Locale('en', 'IN'), Locale('hi', 'IN')],
  defaultLocale: Locale('en', 'IN'),
  taxRule: GstTaxRule(),
  verificationDocs: [
    VerificationDocSpec(
      type: 'gstin',
      labelKey: 'docGstin',
      validator: Validators.gstin,
      required: true,
      needsFile: false,
    ),
    VerificationDocSpec(
      type: 'shop_photo',
      labelKey: 'docShopPhoto',
      validator: _any,
      required: true,
    ),
    VerificationDocSpec(
      type: 'udyam',
      labelKey: 'docUdyam',
      validator: Validators.udyam,
      needsFile: false,
    ),
  ],
  paymentProvider: PaymentProvider.razorpay,
  offPlatformPaymentMethods: ['upi', 'cash', 'card', 'bank_transfer', 'seller_link'],
  webDomain: 'iwantindia.app',
  states: _indiaStates,
  demoCities: [
    DemoCity('Bengaluru', 'Karnataka', LatLng(12.9716, 77.5946), '560034'),
    DemoCity('Mumbai', 'Maharashtra', LatLng(19.0760, 72.8777), '400050'),
    DemoCity('Delhi', 'Delhi', LatLng(28.6139, 77.2090), '110001'),
  ],
  defaultRadiusKm: 15,
  distanceUnitMiles: false,
  freeQuotesPerMonth: 10,
  lowEndDeviceMode: true,
  accentSeed: Color(0xFFC2410C),
  minimumAge: 18,
  playStoreUrl: 'https://play.google.com/store/apps/details?id=com.calecute.iwant.india',
  appStoreUrl: 'https://apps.apple.com/in/app/i-want-india/id0000000000',
);

bool _any(String _) => true;

const _indiaStates = [
  'Andaman and Nicobar Islands', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam',
  'Bihar', 'Chandigarh', 'Chhattisgarh', 'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jammu and Kashmir',
  'Jharkhand', 'Karnataka', 'Kerala', 'Ladakh', 'Lakshadweep', 'Madhya Pradesh',
  'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha',
  'Puducherry', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana',
  'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
];
