import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/country_config.dart';
import '../../../core/providers.dart';
import '../../../core/services/device_services.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../application/seller_providers.dart';
import '../domain/seller.dart';

final _docsProvider = FutureProvider.autoDispose<List<SellerDocument>>(
  (ref) => ref.watch(sellerRepositoryProvider).myDocuments(),
);
final _licencesProvider = FutureProvider.autoDispose<List<SellerLicence>>(
  (ref) => ref.watch(sellerRepositoryProvider).myLicences(),
);

String docLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'docGstin' => l10n.docGstin,
    'docUdyam' => l10n.docUdyam,
    'docShopPhoto' => l10n.docShopPhoto,
    'docEin' => l10n.docEin,
    'docStateLicence' => l10n.docStateLicence,
    'docBusinessAddress' => l10n.docBusinessAddress,
    'docWebsite' => l10n.docWebsite,
    _ => key,
  };
}

/// Verification: India GSTIN (+checksum), shop photo, Udyam; USA EIN / state
/// licence, business address, website. Reviewed in the admin queue.
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final seller = ref.watch(mySellerProvider).value;
    final docs = ref.watch(_docsProvider).value ?? const [];
    final licences = ref.watch(_licencesProvider).value ?? const [];
    final status = seller?.verificationStatus ?? VerificationStatus.none;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.verificationTitle)),
      body: MaxWidth(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(l10n.verificationBody),
          const SizedBox(height: 12),
          StatusChip(switch (status) {
            VerificationStatus.none => l10n.verificationStatusNone,
            VerificationStatus.pending => l10n.verificationStatusPending,
            VerificationStatus.verified => l10n.verificationStatusVerified,
            VerificationStatus.rejected => l10n.verificationStatusRejected(''),
          }),
          const SizedBox(height: 16),
          for (final spec in config.verificationDocs)
            _DocTile(spec: spec, existing: docs.where((d) => d.docType == spec.type).firstOrNull),
          const Divider(height: 32),
          Text(l10n.licencesTitle, style: context.text.titleMedium),
          Text(l10n.licencesBody, style: context.text.bodySmall),
          for (final lic in licences)
            ListTile(
              title: Text('${lic.licenceType} · ${lic.number}'),
              subtitle: Text(lic.expiresAt == null ? '' : context.date(lic.expiresAt!)),
              trailing: StatusChip(lic.status.name),
            ),
          TextButton.icon(
            onPressed: () => _addLicence(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.addLicence),
          ),
        ]),
      ),
    );
  }

  Future<void> _addLicence(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final type = TextEditingController();
    final number = TextEditingController();
    final issuer = TextEditingController();
    DateTime? expiry;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(ctx).bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: type, decoration: InputDecoration(labelText: l10n.licenceType)),
            TextField(controller: number, decoration: InputDecoration(labelText: l10n.licenceNumber)),
            TextField(controller: issuer, decoration: InputDecoration(labelText: l10n.licenceIssuer)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.licenceExpiry),
              subtitle: Text(expiry == null ? l10n.postPickDate : ctx.date(expiry!)),
              onTap: () async {
                final now = DateTime.now();
                final d = await showDatePicker(context: ctx, firstDate: now, lastDate: now.add(const Duration(days: 3650)));
                if (d != null) set(() => expiry = d);
              },
            ),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.submitForReview)),
          ]),
        ),
      ),
    );
    if (ok != true || number.text.trim().isEmpty) return;
    await ref.read(sellerRepositoryProvider).submitLicence(SellerLicence(
          id: '',
          licenceType: type.text.trim(),
          number: number.text.trim(),
          issuer: issuer.text.trim(),
          expiresAt: expiry,
        ));
    ref.invalidate(_licencesProvider);
    if (context.mounted) context.toast(l10n.submittedForReview);
  }
}

class _DocTile extends ConsumerStatefulWidget {
  const _DocTile({required this.spec, this.existing});
  final VerificationDocSpec spec;
  final SellerDocument? existing;

  @override
  ConsumerState<_DocTile> createState() => _DocTileState();
}

class _DocTileState extends ConsumerState<_DocTile> {
  late final _number = TextEditingController(text: widget.existing?.docNumber ?? '');
  String? _file;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final spec = widget.spec;
    if (!spec.needsFile && !spec.validator(_number.text)) {
      setState(() => _error = l10n.docInvalid);
      return;
    }
    setState(() => _error = null);
    await ref.read(sellerRepositoryProvider).submitDocument(spec.type,
        number: _number.text.trim().isEmpty ? null : _number.text.trim().toUpperCase(), filePath: _file);
    ref.invalidate(_docsProvider);
    ref.invalidate(mySellerProvider);
    if (mounted) context.toast(l10n.submittedForReview);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spec = widget.spec;
    final label = '${docLabel(context, spec.labelKey)}${spec.required ? '' : ' (${l10n.optional})'}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(label, style: context.text.titleSmall)),
            if (widget.existing != null) StatusChip(widget.existing!.status.name),
          ]),
          const SizedBox(height: 8),
          if (spec.needsFile)
            OutlinedButton.icon(
              onPressed: () async {
                final p = await ref.read(mediaServiceProvider).pickImages(limit: 1);
                if (p.isNotEmpty) setState(() => _file = p.first);
              },
              icon: Icon(_file == null ? Icons.upload_file_outlined : Icons.check_rounded),
              label: Text(l10n.uploadFile),
            )
          else
            TextField(
              controller: _number,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: label, errorText: _error),
            ),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _submit, child: Text(l10n.submitForReview))),
        ]),
      ),
    );
  }
}
