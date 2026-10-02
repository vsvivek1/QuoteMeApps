import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/utils/save_file.dart';
import '../../../core/widgets/async_view.dart';
import '../../audit/application/audit_providers.dart';
import '../../categories/application/category_providers.dart';
import '../../categories/domain/category_models.dart';
import '../../flags/application/settings_providers.dart';
import '../application/brochure_pdf.dart';
import '../application/brochure_providers.dart';

/// Brochure generator (Section 21.4): one branded PDF per city x category x
/// language, a 1080x1350 image for WhatsApp/Instagram and an A5 one-pager,
/// each with a QR code to the signup link with UTM tags.
class BrochureScreen extends ConsumerStatefulWidget {
  const BrochureScreen({super.key});

  @override
  ConsumerState<BrochureScreen> createState() => _BrochureScreenState();
}

class _BrochureScreenState extends ConsumerState<BrochureScreen> {
  final _city = TextEditingController();
  String? _state;
  AdminCategory? _category;
  String _language = 'en';
  BrochureFormat _format = BrochureFormat.pdf;
  DateTime? _foundingUntil;
  bool _dateFromSetting = false;
  Uint8List? _logo;
  int _rev = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(countryConfigProvider);
    final first = config.priorityCities.first;
    _city.text = first.name;
    _state = first.state;
    rootBundle.load(config.logoAsset).then((d) {
      if (mounted) setState(() => _logo = d.buffer.asUint8List());
    }, onError: (_) {});
    ref.read(appSettingsProvider.future).then((settings) {
      final v = settings.where((s) => s.key == 'early_partner_free_until').firstOrNull?.value;
      final d = v is String ? DateTime.tryParse(v) : null;
      if (d != null && mounted) {
        setState(() {
          _foundingUntil = d;
          _dateFromSetting = true;
        });
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  BrochureSpec? _spec() {
    final config = ref.read(countryConfigProvider);
    final cat = _category;
    if (cat == null || _foundingUntil == null || _city.text.trim().isEmpty) return null;
    return BrochureSpec(
      config: config,
      city: _city.text.trim(),
      state: _state,
      categoryName: cat.name(_language),
      language: _language,
      foundingUntil: fmtDate(_foundingUntil),
      signupUrl: config.signupUrl(
        source: 'brochure',
        medium: _format == BrochureFormat.image ? 'social' : 'print',
        campaign: _utmCampaign(cat),
        city: _city.text.trim(),
        category: cat.slug,
      ),
      format: _format,
      logoPng: _logo,
    );
  }

  String _utmCampaign(AdminCategory cat) =>
      '${_city.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-${cat.slug}-$_language';

  Future<Uint8List> _bytes(BrochureSpec spec) async {
    final pdf = await buildBrochurePdf(spec);
    if (spec.format != BrochureFormat.image) return pdf;
    // 1080x1350 pt page at 72 dpi = 1080x1350 px.
    await for (final page in Printing.raster(pdf, dpi: 72)) {
      return page.toPng();
    }
    throw StateError('raster_failed');
  }

  Future<void> _download() async {
    final spec = _spec();
    if (spec == null) return;
    final bytes = await _bytes(spec);
    final ext = spec.format == BrochureFormat.image ? 'png' : 'pdf';
    await saveBytes('brochure_${_utmCampaign(_category!)}_${spec.format.name}.$ext', bytes,
        ext == 'png' ? 'image/png' : 'application/pdf');
  }

  Future<void> _save() async {
    final l = context.l10n;
    final spec = _spec();
    final cat = _category;
    if (spec == null || cat == null) return;
    setState(() => _saving = true);
    try {
      final bytes = await _bytes(spec);
      final rec = await ref.read(brochureRepositoryProvider).save(
        cityName: spec.city,
        state: spec.state,
        categoryId: cat.id,
        categorySlug: cat.slug,
        language: spec.language,
        format: spec.format.name,
        bytes: bytes,
        signupUrl: spec.signupUrl.toString(),
        utm: Map.fromEntries(spec.signupUrl.queryParameters.entries.where((e) => e.key.startsWith('utm_'))),
      );
      ref
        ..invalidate(brochureListProvider)
        ..invalidate(auditLogProvider);
      if (mounted) context.toast(l.brochureSaved(rec.storagePath));
    } catch (e) {
      if (mounted) context.toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final cats = (ref.watch(adminCategoriesProvider).value ?? const <AdminCategory>[])
        .where((c) => c.policy != CategoryPolicy.blocked && c.active)
        .toList();
    _category ??= cats.where((c) => c.parentId != null).firstOrNull;
    final spec = _spec();
    final form = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Autocomplete<String>(
        initialValue: _city.value,
        optionsBuilder: (v) => config.priorityCities
            .map((c) => c.name)
            .where((n) => n.toLowerCase().contains(v.text.toLowerCase())),
        onSelected: (v) => setState(() {
          _city.text = v;
          _state = config.priorityCities.firstWhere((c) => c.name == v).state;
          _rev++;
        }),
        fieldViewBuilder: (context, ctrl, focus, _) => TextField(
          controller: ctrl,
          focusNode: focus,
          decoration: InputDecoration(labelText: l.city, helperText: l.anyCityHelp),
          onChanged: (v) => setState(() {
            _city.text = v;
            _rev++;
          }),
        ),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _state,
        isExpanded: true,
        decoration: InputDecoration(labelText: l.state),
        items: [for (final s in config.states) DropdownMenuItem(value: s, child: Text(s))],
        onChanged: (v) => setState(() => _state = v),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<AdminCategory>(
        initialValue: _category,
        isExpanded: true,
        decoration: InputDecoration(labelText: l.category),
        items: [for (final c in cats) DropdownMenuItem(value: c, child: Text(c.name()))],
        onChanged: (v) => setState(() {
          _category = v;
          _rev++;
        }),
      ),
      const SizedBox(height: 12),
      SegmentedButton<String>(
        segments: [for (final lang in config.brochureLanguages) ButtonSegment(value: lang, label: Text(lang.toUpperCase()))],
        selected: {_language},
        onSelectionChanged: (s) => setState(() {
          _language = s.first;
          _rev++;
        }),
      ),
      const SizedBox(height: 12),
      SegmentedButton<BrochureFormat>(
        segments: [
          ButtonSegment(value: BrochureFormat.pdf, label: Text(l.formatA4)),
          ButtonSegment(value: BrochureFormat.onepager, label: Text(l.formatA5)),
          ButtonSegment(value: BrochureFormat.image, label: Text(l.formatImage)),
        ],
        selected: {_format},
        onSelectionChanged: (s) => setState(() {
          _format = s.first;
          _rev++;
        }),
      ),
      const SizedBox(height: 12),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l.foundingUntil),
        subtitle: Text(_foundingUntil == null
            ? l.foundingUntilRequired
            : '${fmtDate(_foundingUntil)}${_dateFromSetting ? ' (${l.fromSettings})' : ''}'),
        trailing: OutlinedButton(
          onPressed: () async {
            final now = DateTime.now();
            final d = await showDatePicker(
              context: context,
              firstDate: now,
              lastDate: now.add(const Duration(days: 365 * 2)),
              initialDate: _foundingUntil ?? now.add(const Duration(days: 182)),
            );
            if (d != null) {
              setState(() {
                _foundingUntil = d;
                _dateFromSetting = false;
                _rev++;
              });
            }
          },
          child: Text(l.changeDate),
        ),
      ),
      if (spec != null) ...[
        const SizedBox(height: 8),
        SelectableText(spec.signupUrl.toString(), style: Theme.of(context).textTheme.bodySmall),
      ],
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        FilledButton.icon(
          onPressed: spec == null ? null : _download,
          icon: const Icon(Icons.download),
          label: Text(l.download),
        ),
        if (_format != BrochureFormat.image)
          OutlinedButton.icon(
            onPressed: spec == null ? null : () => Printing.layoutPdf(onLayout: (_) => buildBrochurePdf(spec)),
            icon: const Icon(Icons.print),
            label: Text(l.print),
          ),
        OutlinedButton.icon(
          onPressed: spec == null || _saving ? null : _save,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: Text(l.saveToStorage),
        ),
      ]),
      const SizedBox(height: 24),
      Text(l.savedBrochures, style: Theme.of(context).textTheme.titleSmall),
      AsyncView(
        value: ref.watch(brochureListProvider),
        builder: (list) => list.isEmpty
            ? Padding(padding: const EdgeInsets.all(12), child: Text(l.noBrochures))
            : Column(children: [
                for (final b in list)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(b.format == 'image' ? Icons.image_outlined : Icons.picture_as_pdf_outlined),
                    title: Text('${b.cityName} · ${b.language} · ${b.format} · v${b.version}'),
                    subtitle: Text(b.storagePath),
                    trailing: b.publicUrl == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => launchUrl(Uri.parse(b.publicUrl!), webOnlyWindowName: '_blank'),
                          ),
                  ),
              ]),
      ),
    ]);

    final preview = spec == null
        ? EmptyState(l.brochureIncomplete, icon: Icons.picture_as_pdf_outlined)
        : _format == BrochureFormat.image
            ? FutureBuilder<Uint8List>(
                key: ValueKey(_rev),
                future: _bytes(spec),
                builder: (_, snap) => snap.hasData
                    ? InteractiveViewer(child: Center(child: Image.memory(snap.data!)))
                    : snap.hasError
                        ? Center(child: Text('${snap.error}'))
                        : const Center(child: CircularProgressIndicator()),
              )
            : PdfPreview(
                key: ValueKey(_rev),
                build: (_) => buildBrochurePdf(spec),
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                allowPrinting: false,
                allowSharing: false,
                initialPageFormat: _format.pageFormat,
              );

    return Scaffold(
      appBar: AppBar(title: Text(l.navBrochures)),
      body: LayoutBuilder(
        builder: (context, box) => box.maxWidth < 1000
            ? ListView(padding: const EdgeInsets.all(16), children: [form, SizedBox(height: 600, child: preview)])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 420, child: ListView(padding: const EdgeInsets.all(16), children: [form])),
                const VerticalDivider(width: 1),
                Expanded(child: preview),
              ]),
      ),
    );
  }
}
