import 'package:flutter_test/flutter_test.dart';
import 'package:iwant_admin/core/utils/csv.dart';
import 'package:iwant_admin/features/outreach/domain/lead_import.dart';
import 'package:iwant_admin/features/outreach/domain/outreach_models.dart';

void main() {
  final importer = LeadImporter(categoryLookup: {'hvac': 4, 'plumbing': 5}, priorityByCity: {'dallas': 4});

  test('CSV parser handles quotes, commas and newlines', () {
    final rows = parseCsv('a,b\r\n"x, y","he said ""hi""\nthere"\n');
    expect(rows, [
      ['a', 'b'],
      ['x, y', 'he said "hi"\nthere'],
    ]);
    expect(toCsv([['=SUM(A1)', 'a,b']]), "'=SUM(A1),\"a,b\"");
  });

  test('imports compliant business rows and rejects non-compliant ones', () {
    const csv = 'business_name,email,address_source,phone,website,city,state,categories,source,source_ref,type\n'
        'Northside Cooling,info@northside.example,https://northside.example/contact,,https://www.northside.example,Dallas,Texas,hvac,osm,node/1,business\n'
        'Scraped Co,a@scraped.example,https://scraped.example,,,Dallas,Texas,hvac,osm,https://www.yelp.com/biz/x,business\n'
        'Bought List,b@bought.example,https://bought.example,,,Dallas,Texas,hvac,purchased,,business\n'
        'Jane Doe,jane@example.com,https://example.com,,,Dallas,Texas,hvac,manual,,individual\n'
        'No Source Email,c@nosource.example,,,,Dallas,Texas,hvac,osm,,business\n'
        'Temp Mail Biz,d@mailinator.com,https://x.example,,,Dallas,Texas,hvac,osm,,business\n'
        'Northside Again,info@northside.example,https://northside.example/contact,,,Dallas,Texas,hvac,osm,,business\n'
        'Corner Plumbing,,,+1 (555) 010-0101,,Austin,Texas,plumbing;roofing,registry,,business\n';
    final p = importer.preview(csv);
    expect(p.drafts.map((d) => d.businessName), ['Northside Cooling', 'Corner Plumbing']);
    expect(p.rejected.map((r) => r.reason), [
      'scraped_source',
      'non_compliant_source',
      'consumer_record',
      'email_without_address_source',
      'disposable_email',
    ]);
    expect(p.duplicatesInFile, 1);

    final first = p.drafts.first;
    expect(first.businessKey, 'domain:northside.example');
    expect(first.matchedCategoryIds, [4]);
    expect(first.priority, 4);
    expect(first.lawfulBasis, LawfulBasis.legitimateInterest);
    expect(first.chosenReason, contains('osm'));

    final second = p.drafts.last;
    expect(second.businessKey, 'phone:+15550100101');
    expect(second.lawfulBasis, LawfulBasis.publicRegistry);
    expect(second.matchedCategoryIds, [5]);
    expect(second.toRpcJson()['lawful_basis'], 'public_registry');
  });

  test('missing required columns are reported', () {
    final p = importer.preview('name,email\nA,b@c.example\n');
    expect(p.drafts, isEmpty);
    expect(p.rejected.single.reason, 'missing_required_columns');
  });
}
