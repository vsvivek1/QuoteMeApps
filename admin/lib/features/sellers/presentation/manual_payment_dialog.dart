import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/admin_country.dart';
import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../domain/manual_payment.dart';
import '../domain/seller_models.dart';

String manualPlanLabel(AppLocalizations l, ManualPlan p) => switch (p) {
      ManualPlan.proMonthly => l.planProMonthly,
      ManualPlan.proAnnual => l.planProAnnual,
      ManualPlan.credits10 => l.planCredits10,
      ManualPlan.credits50 => l.planCredits50,
    };

String paymentMethodLabel(AppLocalizations l, String wire) => switch (wire) {
      'upi' => l.methodUpi,
      'bank_transfer' => l.methodBankTransfer,
      _ => l.methodOther,
    };

/// Records a payment received by UPI / bank transfer and grants the plan
/// through `admin_grant_entitlement`. Returns the new entitlement row, or null
/// when cancelled.
Future<EntitlementRecord?> showManualPaymentDialog(BuildContext context, SellerSummary seller) =>
    showDialog<EntitlementRecord>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ManualPaymentDialog(seller: seller),
    );

class ManualPaymentDialog extends ConsumerStatefulWidget {
  const ManualPaymentDialog({super.key, required this.seller});
  final SellerSummary seller;

  @override
  ConsumerState<ManualPaymentDialog> createState() => _ManualPaymentDialogState();
}

class _ManualPaymentDialogState extends ConsumerState<ManualPaymentDialog> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _payer = TextEditingController();
  var _plan = ManualPlan.proMonthly;
  PaymentMethod? _method;
  var _checked = false;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _payer.dispose();
    super.dispose();
  }

  List<PaymentMethod> _methods(AdminCountryConfig config) => [
        if (config.country == Country.india) PaymentMethod.upi,
        PaymentMethod.bankTransfer,
        PaymentMethod.other,
      ];

  Future<void> _submit() async {
    final l = context.l10n;
    setState(() => _error = null);
    if (!_form.currentState!.validate() || !_checked) return;
    final config = ref.read(countryConfigProvider);
    final grant = ManualPaymentGrant(
      sellerId: widget.seller.id,
      plan: _plan,
      method: _method ?? _methods(config).first,
      amountMinor: parseAmountToMinor(_amount.text)!,
      currency: config.currencyCode,
      reference: normalizeReference(_reference.text)!,
      payerName: _payer.text,
      now: DateTime.now(),
    );
    setState(() => _busy = true);
    try {
      final repo = ref.read(sellerRepositoryProvider);
      final earlier = await repo.grantsWithReference(grant.reference);
      if (earlier.isNotEmpty) {
        setState(() => _error = l.referenceUsed(fmtDate(earlier.first.createdAt)));
        return;
      }
      final row = await repo.grant(grant);
      if (mounted) Navigator.pop(context, row);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final methods = _methods(config);
    final method = _method ?? methods.first;
    final expiry = manualPlanExpiry(_plan, DateTime.now());
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l.recordPayment),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.seller.businessName, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l.recordPaymentIntro, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              DropdownButtonFormField<ManualPlan>(
                initialValue: _plan,
                decoration: InputDecoration(labelText: l.plan),
                items: [
                  for (final p in ManualPlan.values) DropdownMenuItem(value: p, child: Text(manualPlanLabel(l, p))),
                ],
                onChanged: _busy ? null : (p) => setState(() => _plan = p ?? _plan),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  expiry == null ? l.creditsNoExpiry : l.planValidUntil(fmtDate(expiry.subtract(const Duration(seconds: 1)))),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: method,
                decoration: InputDecoration(labelText: l.paymentMethod),
                items: [
                  for (final m in methods) DropdownMenuItem(value: m, child: Text(paymentMethodLabel(l, m.wire))),
                ],
                onChanged: _busy ? null : (m) => setState(() => _method = m),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.amountReceived(config.currencyCode)),
                validator: (v) => parseAmountToMinor(v ?? '') == null ? l.amountInvalid : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reference,
                enabled: !_busy,
                decoration: InputDecoration(labelText: l.paymentReference),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? l.required
                    : normalizeReference(v!) == null
                        ? l.referenceInvalid
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _payer,
                enabled: !_busy,
                maxLength: 100,
                decoration: InputDecoration(labelText: l.payerName),
              ),
              CheckboxListTile(
                value: _checked,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(l.bankChecked),
                onChanged: _busy ? null : (v) => setState(() => _checked = v ?? false),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: scheme.error)),
              ],
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton.icon(
          onPressed: _busy || !_checked ? null : _submit,
          icon: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.verified_outlined),
          label: Text(l.grantPlan),
        ),
      ],
    );
  }
}
