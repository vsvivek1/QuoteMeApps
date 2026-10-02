import 'dart:ui';


import '../money/money.dart';
import '../money/money_formatter.dart';
import '../money/tax.dart';

enum Country { usa, india }

enum PaymentProvider { stripe, razorpay }

/// A seller verification document type (GSTIN, EIN, ...).
class VerificationDocSpec {
  const VerificationDocSpec({
    required this.type,
    required this.labelKey,
    required this.validator,
    this.required = false,
    this.needsFile = true,
  });

  /// Stored in `seller_documents.doc_type`.
  final String type;

  /// l10n key resolved by `docTypeLabel` in the UI.
  final String labelKey;
  final bool Function(String) validator;
  final bool required;
  final bool needsFile;
}

class LatLng {
  const LatLng(this.lat, this.lng);
  final double lat;
  final double lng;
}

class DemoCity {
  const DemoCity(this.name, this.state, this.center, this.sampleCode);
  final String name;
  final String state;
  final LatLng center;
  final String sampleCode;
}

/// Everything that differs between I Want USA and I Want India.
///
/// Widgets never branch on the country; they read from this object, which the
/// country entry point (`main_usa.dart`, `main_india.dart`) injects.
class CountryConfig {
  const CountryConfig({
    required this.country,
    required this.appName,
    required this.legalEntity,
    required this.currencyCode,
    required this.phoneDialCode,
    required this.phoneHint,
    required this.phoneValidator,
    required this.postalCodeValidator,
    required this.postalCodeMaxLength,
    required this.supportedLocales,
    required this.defaultLocale,
    required this.taxRule,
    required this.verificationDocs,
    required this.paymentProvider,
    required this.offPlatformPaymentMethods,
    required this.webDomain,
    required this.states,
    required this.demoCities,
    required this.defaultRadiusKm,
    required this.distanceUnitMiles,
    required this.freeQuotesPerMonth,
    required this.lowEndDeviceMode,
    required this.accentSeed,
    required this.minimumAge,
    required this.playStoreUrl,
    required this.appStoreUrl,
  });

  final Country country;
  final String appName;
  final String legalEntity;
  final String currencyCode;

  /// e.g. "+91"
  final String phoneDialCode;
  final String phoneHint;
  final bool Function(String nationalNumber) phoneValidator;
  final bool Function(String code) postalCodeValidator;
  final int postalCodeMaxLength;

  final List<Locale> supportedLocales;
  final Locale defaultLocale;

  final TaxRule taxRule;
  final List<VerificationDocSpec> verificationDocs;
  final PaymentProvider paymentProvider;

  /// Keys resolved by `paymentMethodLabel` in l10n (cash, upi, card, zelle...).
  final List<String> offPlatformPaymentMethods;

  /// e.g. iwantindia.app: deep links, legal pages, share links.
  final String webDomain;

  /// State / union territory names used for addresses and GST place of supply.
  final List<String> states;
  final List<DemoCity> demoCities;
  final int defaultRadiusKm;
  final bool distanceUnitMiles;
  final int freeQuotesPerMonth;

  /// Lighter images and animations for 2 GB RAM phones and slow networks.
  final bool lowEndDeviceMode;
  final Color accentSeed;
  final int minimumAge;
  final String playStoreUrl;
  final String appStoreUrl;

  String get countryCode => country == Country.india ? 'IN' : 'US';

  Currency get currency => currencyFor(currencyCode);

  Money money(int minor) => moneyFromMinor(minor, currencyCode);

  Money get zero => zeroMoney(currencyCode);

  MoneyFormatter formatter(Locale locale) =>
      MoneyFormatter(locale.toLanguageTag().replaceAll('-', '_'));

  Uri legalUrl(String slug) => Uri.https(webDomain, '/legal/$slug');

  Uri requestLink(String id) => Uri.https(webDomain, '/r/$id');
  Uri quoteLink(String id) => Uri.https(webDomain, '/q/$id');
  Uri sellerLink(String id) => Uri.https(webDomain, '/s/$id');

  Uri get accountDeletionUrl => legalUrl('account-deletion');

  String formatDistance(double km) {
    if (distanceUnitMiles) {
      final miles = km * 0.621371;
      return miles < 10 ? '${miles.toStringAsFixed(1)} mi' : '${miles.round()} mi';
    }
    return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
  }

  String e164(String national) =>
      '$phoneDialCode${national.replaceAll(RegExp(r'\D'), '')}';
}
