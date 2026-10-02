import '../../../core/utils/csv.dart';
import 'anti_spam.dart';
import 'outreach_models.dart';

/// Why a CSV row was not imported.
class RejectedRow {
  const RejectedRow(this.line, this.reason);
  final int line;
  final String reason;
}

class LeadImportPreview {
  const LeadImportPreview({
    required this.drafts,
    required this.rejected,
    required this.duplicatesInFile,
    required this.withoutCategory,
  });
  final List<LeadDraft> drafts;
  final List<RejectedRow> rejected;
  final int duplicatesInFile;

  /// Imported but never contactable until a category matches (rule 1).
  final int withoutCategory;
}

/// Turns a CSV of business leads into [LeadDraft]s, enforcing the compliant
/// source rules of Section 21.1 and the consumer ban of 21.7.
///
/// Expected header (case-insensitive, any order; only `business_name` and
/// `source` are required):
/// `business_name, email, address_source, phone, website, address, city,
/// state, postal_code, categories, source, source_ref, lawful_basis,
/// chosen_reason, place_id, osm_id, rating, rating_count, timezone, type`.
class LeadImporter {
  LeadImporter({required this.categoryLookup, this.priorityByCity = const {}});

  /// Lower-cased category slug or English name -> category id.
  final Map<String, int> categoryLookup;

  /// Lower-cased city -> outreach priority (lower first).
  final Map<String, int> priorityByCity;

  static const columns = [
    'business_name', 'email', 'address_source', 'phone', 'website', 'address', 'city', 'state',
    'postal_code', 'categories', 'source', 'source_ref', 'lawful_basis', 'chosen_reason',
    'place_id', 'osm_id', 'rating', 'rating_count', 'timezone', 'type',
  ];

  /// Sites whose pages must never be scraped (21.1). A row that says it came
  /// from one of them is refused.
  static const bannedSourceHosts = [
    'google.com/maps', 'maps.google.', 'yelp.', 'yellowpages.', 'justdial.', 'indiamart.',
    'sulekha.', 'tradeindia.', 'facebook.com', 'linkedin.com',
  ];

  static const _consumerTypes = {'individual', 'consumer', 'person', 'b2c', 'customer'};

  LeadImportPreview preview(String csvText) {
    final rows = parseCsv(csvText);
    if (rows.isEmpty) {
      return const LeadImportPreview(drafts: [], rejected: [], duplicatesInFile: 0, withoutCategory: 0);
    }
    final header = rows.first.map((h) => h.trim().toLowerCase().replaceAll(' ', '_')).toList();
    final drafts = <LeadDraft>[];
    final rejected = <RejectedRow>[];
    final seenKeys = <String>{};
    var duplicates = 0;
    var withoutCategory = 0;

    if (!header.contains('business_name') || !header.contains('source')) {
      return const LeadImportPreview(
        drafts: [],
        rejected: [RejectedRow(1, 'missing_required_columns')],
        duplicatesInFile: 0,
        withoutCategory: 0,
      );
    }

    for (var i = 1; i < rows.length; i++) {
      final line = i + 1;
      final r = rows[i];
      String? col(String name) {
        final idx = header.indexOf(name);
        if (idx < 0 || idx >= r.length) return null;
        final v = r[idx].trim();
        return v.isEmpty ? null : v;
      }

      final result = parseRow(col);
      if (result.$2 != null) {
        rejected.add(RejectedRow(line, result.$2!));
        continue;
      }
      final d = result.$1!;
      final keys = {
        d.businessKey,
        if (d.email != null) 'email:${d.email!.toLowerCase()}',
        if (d.phone != null) 'phone:${d.phone}',
        if (d.websiteDomain != null) 'domain:${d.websiteDomain}',
      };
      if (keys.any(seenKeys.contains)) {
        duplicates++;
        continue;
      }
      seenKeys.addAll(keys);
      if (d.matchedCategoryIds.isEmpty) withoutCategory++;
      drafts.add(d);
    }
    return LeadImportPreview(
      drafts: drafts,
      rejected: rejected,
      duplicatesInFile: duplicates,
      withoutCategory: withoutCategory,
    );
  }

  /// Returns the draft, or a rejection reason.
  (LeadDraft?, String?) parseRow(String? Function(String) col) {
    final name = col('business_name');
    if (name == null || name.length < 2) return (null, 'missing_business_name');

    final type = col('type')?.toLowerCase();
    if (type != null && _consumerTypes.contains(type)) return (null, 'consumer_record');

    final sourceRaw = col('source');
    final source = sourceRaw == null ? null : LeadSource.tryParse(sourceRaw);
    if (source == null) return (null, 'non_compliant_source');

    final sourceRef = col('source_ref');
    if (sourceRef != null) {
      final ref = sourceRef.toLowerCase();
      if (bannedSourceHosts.any(ref.contains)) return (null, 'scraped_source');
    }

    final email = col('email')?.toLowerCase();
    final addressSource = col('address_source');
    if (email != null) {
      if (!AntiSpam.isValidEmailSyntax(email)) return (null, 'invalid_email');
      final domain = email.split('@').last;
      if (AntiSpam.disposableDomains.contains(domain)) return (null, 'disposable_email');
      if (addressSource == null) return (null, 'email_without_address_source');
      final src = addressSource.toLowerCase();
      if (bannedSourceHosts.any(src.contains)) return (null, 'scraped_source');
    }

    final phone = normalisePhone(col('phone'));
    final website = col('website');
    final websiteDomain = domainOf(website);
    final placeId = col('place_id');
    final osmId = col('osm_id');
    final address = col('address');
    final postal = col('postal_code');
    if (email == null && phone == null && website == null && placeId == null && osmId == null && address == null) {
      return (null, 'no_business_contact');
    }

    final rawCategories = (col('categories') ?? '')
        .split(RegExp('[;|]'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    final matched = <int>{
      for (final c in rawCategories)
        if (categoryLookup[c.toLowerCase()] != null) categoryLookup[c.toLowerCase()]!,
    }.toList();

    final basisRaw = col('lawful_basis');
    final basis = basisRaw != null
        ? LawfulBasis.tryParse(basisRaw)
        : switch (source) {
            LeadSource.inbound || LeadSource.referral => LawfulBasis.inboundRequest,
            LeadSource.registry => LawfulBasis.publicRegistry,
            _ => LawfulBasis.legitimateInterest,
          };
    if (basis == null) return (null, 'invalid_lawful_basis');

    final city = col('city');
    final key = businessKey(
      websiteDomain: websiteDomain,
      phone: phone,
      placeId: placeId,
      osmId: osmId,
      name: name,
      postalCode: postal,
    );
    final reason = col('chosen_reason') ??
        [
          if (rawCategories.isNotEmpty) 'Listed as ${rawCategories.join('/')}',
          if (city != null) 'in $city',
          'via ${source.name}${sourceRef == null ? '' : ' ($sourceRef)'}',
        ].join(' ');

    return (
      LeadDraft(
        businessKey: key,
        businessName: name,
        categoriesSource: rawCategories,
        matchedCategoryIds: matched,
        email: email,
        addressSource: addressSource,
        phone: phone,
        website: website,
        websiteDomain: websiteDomain,
        placeId: placeId,
        osmId: osmId,
        address: address,
        city: city,
        state: col('state'),
        postalCode: postal,
        timezone: col('timezone'),
        rating: double.tryParse(col('rating') ?? ''),
        ratingCount: int.tryParse(col('rating_count') ?? ''),
        source: source,
        sourceRef: sourceRef,
        lawfulBasis: basis,
        chosenReason: reason,
        priority: city == null ? null : priorityByCity[city.toLowerCase()],
      ),
      null,
    );
  }

  static String? normalisePhone(String? raw) {
    if (raw == null) return null;
    final plus = raw.trim().startsWith('+');
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return null;
    return plus ? '+$digits' : digits;
  }

  static String? domainOf(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    var u = url.trim();
    if (!u.contains('://')) u = 'https://$u';
    final host = Uri.tryParse(u)?.host.toLowerCase();
    if (host == null || host.isEmpty) return null;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  /// One business = one key (rule 2): website domain, else phone, else
  /// Places id, else OSM id, else name + postal code.
  static String businessKey({
    String? websiteDomain,
    String? phone,
    String? placeId,
    String? osmId,
    required String name,
    String? postalCode,
  }) {
    if (websiteDomain != null) return 'domain:$websiteDomain';
    if (phone != null) return 'phone:$phone';
    if (placeId != null) return 'place:$placeId';
    if (osmId != null) return 'osm:$osmId';
    final n = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return 'name:$n:${postalCode ?? ''}';
  }

  /// CSV export of leads (bulk action).
  static String export(List<OutreachLead> leads) => toCsv([
        ['business_name', 'stage', 'email', 'phone', 'website', 'city', 'state', 'source', 'lawful_basis', 'touches_sent', 'next_action', 'next_action_due'],
        for (final l in leads)
          [
            l.businessName, l.stage.wire, l.email, l.phone, l.website, l.city, l.state, l.source.name,
            l.lawfulBasis.wire, l.touchesSent, l.nextAction, l.nextActionDue?.toIso8601String().split('T').first,
          ],
      ]);
}
