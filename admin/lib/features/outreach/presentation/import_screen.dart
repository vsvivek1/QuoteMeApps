import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/routing/router.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/csv.dart';
import '../../../core/utils/save_file.dart';
import '../../audit/application/audit_providers.dart';
import '../../categories/application/category_providers.dart';
import '../application/outreach_providers.dart';
import '../domain/lead_import.dart';
import '../domain/outreach_models.dart';

/// CSV import of business leads from compliant sources only (21.1):
/// OpenStreetMap, Google Places API, public registries, the business's own
/// website, inbound, referrals and field visits. Never scraped directories,
/// bought lists or consumer data.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  LeadImportPreview? _preview;
  String? _fileName;
  bool _attested = false;
  bool _busy = false;
  ImportResult? _result;

  Future<void> _pick() async {
    final l = context.l10n;
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['csv']);
    if (files.isEmpty) return;
    final f = files.first;
    final bytes = await f.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) context.toast(l.fileTooLarge, error: true);
      return;
    }
    final cats = await ref.read(adminCategoriesProvider.future);
    final config = ref.read(countryConfigProvider);
    final importer = LeadImporter(
      categoryLookup: {
        for (final c in cats) ...{
          c.slug.toLowerCase(): c.id,
          for (final n in c.names.values) n.toLowerCase(): c.id,
        },
      },
      priorityByCity: {
        for (var i = 0; i < config.priorityCities.length; i++) config.priorityCities[i].name.toLowerCase(): i + 1,
      },
    );
    setState(() {
      _fileName = f.name;
      _preview = importer.preview(utf8.decode(bytes, allowMalformed: true));
      _result = null;
      _attested = false;
    });
  }

  Future<void> _import() async {
    final p = _preview;
    if (p == null || p.drafts.isEmpty) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(outreachRepositoryProvider).importLeads(p.drafts);
      invalidateOutreach(ref);
      ref.invalidate(auditLogProvider);
      setState(() => _result = r);
    } catch (e) {
      if (mounted) context.toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _template() async {
    final csv = toCsv([
      LeadImporter.columns,
      [
        'Example Cooling Services', 'info@example-cooling.example', 'https://example-cooling.example/contact',
        '', 'https://example-cooling.example', '1 Example Road', 'Example City', 'Example State', '00000',
        'ac-repair;hvac', 'osm', 'node/123', '', 'Tagged craft=hvac in Example City', '', 'node/123', '4.5', '120',
        '', 'business',
      ],
    ]);
    await saveBytes('lead_import_template.csv', utf8.encode(csv), 'text/csv');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = _preview;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(Routes.outreach)),
        title: Text(l.importCsv),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.importRulesTitle, style: t.titleMedium),
              const SizedBox(height: 8),
              Text(l.importRules),
              const SizedBox(height: 12),
              Text(l.importColumns(LeadImporter.columns.join(', ')), style: t.bodySmall),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                FilledButton.icon(onPressed: _pick, icon: const Icon(Icons.upload_file), label: Text(l.chooseCsv)),
                OutlinedButton.icon(onPressed: _template, icon: const Icon(Icons.download), label: Text(l.downloadTemplate)),
              ]),
            ]),
          ),
        ),
        if (p != null) ...[
          const SizedBox(height: 16),
          Text('$_fileName', style: t.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 8, children: [
            Chip(label: Text(l.importReady(p.drafts.length))),
            Chip(label: Text(l.importRejected(p.rejected.length))),
            Chip(label: Text(l.importDuplicates(p.duplicatesInFile))),
            if (p.withoutCategory > 0) Chip(label: Text(l.importNoCategory(p.withoutCategory))),
          ]),
          if (p.rejected.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(l.rejectedRows),
              children: [
                for (final r in p.rejected.take(200)) ListTile(dense: true, title: Text(l.rowReason(r.line, r.reason))),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (p.drafts.isNotEmpty)
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(columns: [
                  DataColumn(label: Text(l.businessName)),
                  DataColumn(label: Text(l.city)),
                  DataColumn(label: Text(l.email)),
                  DataColumn(label: Text(l.source)),
                  DataColumn(label: Text(l.lawfulBasis)),
                  DataColumn(label: Text(l.categories)),
                ], rows: [
                  for (final d in p.drafts.take(50))
                    DataRow(cells: [
                      DataCell(Text(d.businessName)),
                      DataCell(Text(d.city ?? '')),
                      DataCell(Text(d.email ?? '')),
                      DataCell(Text(d.source.name)),
                      DataCell(Text(d.lawfulBasis.wire)),
                      DataCell(Text(d.matchedCategoryIds.join(', '))),
                    ]),
                ]),
              ),
            ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _attested,
            onChanged: (v) => setState(() => _attested = v ?? false),
            title: Text(l.importAttestation),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _attested && !_busy && p.drafts.isNotEmpty && _result == null ? _import : null,
              child: Text(l.importNow(p.drafts.length)),
            ),
          ),
        ],
        if (_result case final r?) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(l.importDone(r.inserted, r.duplicates)),
              subtitle: r.rejected.isEmpty ? null : Text(r.rejected.join('\n')),
            ),
          ),
        ],
      ]),
    );
  }
}
