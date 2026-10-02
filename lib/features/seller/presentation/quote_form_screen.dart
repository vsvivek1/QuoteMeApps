import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/money/money.dart';
import '../../../core/money/tax.dart';
import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../quotes/application/quote_actions.dart';
import '../../quotes/domain/quote.dart';
import '../../quotes/domain/quote_repository.dart';
import '../application/seller_providers.dart';
import '../domain/seller.dart';

class _LineCtl {
  _LineCtl({String desc = '', String qty = '1', String price = ''})
      : desc = TextEditingController(text: desc),
        qty = TextEditingController(text: qty),
        price = TextEditingController(text: price);
  final TextEditingController desc;
  final TextEditingController qty;
  final TextEditingController price;

  void dispose() {
    desc.dispose();
    qty.dispose();
    price.dispose();
  }
}

/// Seller's quote form with live totals (GST split in India, sales tax line in
/// the US), templates, and revise mode.
class QuoteFormScreen extends ConsumerStatefulWidget {
  const QuoteFormScreen({super.key, required this.requestId, this.reviseQuoteId});
  final String requestId;
  final String? reviseQuoteId;

  @override
  ConsumerState<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends ConsumerState<QuoteFormScreen> {
  final _form = GlobalKey<FormState>();
  final _lines = <_LineCtl>[_LineCtl()];
  final _delivery = TextEditingController();
  final _brand = TextEditingController();
  final _warranty = TextEditingController();
  final _notes = TextEditingController();
  final _salesTax = TextEditingController();
  int _rateBp = 0;
  int _validDays = 7;
  DateTime? _deliveryDate;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _rateBp = ref.read(countryConfigProvider).taxRule.defaultRateBp;
    if (widget.reviseQuoteId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final q = await ref.read(quoteRepositoryProvider).getQuote(widget.reviseQuoteId!);
    if (q == null || !mounted) return;
    setState(() {
      for (final l in _lines) {
        l.dispose();
      }
      _lines
        ..clear()
        ..addAll(q.lines.map((l) => _LineCtl(desc: l.description, qty: '${l.qty}', price: _plain(l.unitPrice))));
      _delivery.text = q.delivery.isZeroAmount ? '' : _plain(q.delivery);
      _brand.text = q.offeredBrandModel ?? '';
      _warranty.text = q.warranty ?? '';
      _notes.text = q.notes ?? '';
      _deliveryDate = q.deliveryDate;
      switch (q.taxBreakdown) {
        case GstBreakdown(:final rateBp):
          _rateBp = rateBp;
        case SalesTaxBreakdown(:final rateBp):
          _rateBp = rateBp;
          _salesTax.text = bpToPercent(rateBp);
        case NoTaxBreakdown():
      }
    });
  }

  String _plain(Money m) {
    final minor = m.minorUnits;
    final major = minor ~/ BigInt.from(100);
    final frac = minor.remainder(BigInt.from(100));
    return frac == BigInt.zero ? '$major' : '$major.${frac.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    for (final c in [_delivery, _brand, _warranty, _notes, _salesTax]) {
      c.dispose();
    }
    super.dispose();
  }

  List<QuoteLine> _quoteLines(String iso) => [
        for (final l in _lines)
          if (parseUserAmount(l.price.text, iso) != null)
            QuoteLine(
              description: l.desc.text.trim(),
              qty: int.tryParse(l.qty.text) ?? 1,
              unitPrice: parseUserAmount(l.price.text, iso)!,
            ),
      ];

  QuoteTotals _totals(String iso, TaxRule rule, Seller? seller, String? buyerState) => rule.compute(
        lines: _quoteLines(iso),
        delivery: parseUserAmount(_delivery.text, iso) ?? zeroMoney(iso),
        rateBp: _rateBp,
        sellerState: seller?.state,
        buyerState: buyerState,
      );

  QuoteDraft _draft(String iso) => QuoteDraft(
        requestId: widget.requestId,
        lines: _quoteLines(iso),
        delivery: parseUserAmount(_delivery.text, iso) ?? zeroMoney(iso),
        taxRateBp: _rateBp,
        offeredBrandModel: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        deliveryDate: _deliveryDate,
        warranty: _warranty.text.trim().isEmpty ? null : _warranty.text.trim(),
        validDays: _validDays,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final iso = ref.read(countryConfigProvider).currencyCode;
    final repo = ref.read(quoteRepositoryProvider);
    try {
      if (widget.reviseQuoteId != null) {
        await repo.reviseQuote(widget.reviseQuoteId!, _draft(iso));
      } else {
        await repo.submitQuote(_draft(iso));
        await ref.read(analyticsProvider).log(AnalyticsEvent.quoteSent, {'request_id': widget.requestId});
      }
      if (!mounted) return;
      context.toast(context.l10n.quoteSent);
      ref.invalidate(leadFeedProvider);
      Navigator.of(context).maybePop();
    } on QuoteFailure catch (e) {
      if (mounted) context.toast(quoteFailureText(context, e.code));
    }
  }

  void _applyTemplate(QuoteTemplate t) {
    final p = t.payload;
    setState(() {
      for (final l in _lines) {
        l.dispose();
      }
      _lines
        ..clear()
        ..addAll([
          for (final l in (p['lines'] as List? ?? const []))
            _LineCtl(desc: '${l['description'] ?? ''}', qty: '${l['qty'] ?? 1}', price: '${l['price'] ?? ''}'),
        ]);
      if (_lines.isEmpty) _lines.add(_LineCtl());
      _delivery.text = '${p['delivery'] ?? ''}';
      _brand.text = '${p['brand'] ?? ''}';
      _warranty.text = '${p['warranty'] ?? ''}';
      _notes.text = '${p['notes'] ?? ''}';
      _rateBp = (p['rate_bp'] as num?)?.toInt() ?? _rateBp;
      if (_salesTax.text.isEmpty && _rateBp > 0) _salesTax.text = bpToPercent(_rateBp);
      _validDays = (p['valid_days'] as num?)?.toInt() ?? _validDays;
    });
  }

  Future<void> _saveTemplate() async {
    final l10n = context.l10n;
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.quoteSaveTemplate),
        content: TextField(controller: name, autofocus: true, decoration: InputDecoration(labelText: l10n.quoteTemplateName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.save)),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    await ref.read(sellerRepositoryProvider).saveTemplate(QuoteTemplate(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name.text.trim(),
          payload: {
            'lines': [
              for (final l in _lines) {'description': l.desc.text, 'qty': l.qty.text, 'price': l.price.text},
            ],
            'delivery': _delivery.text,
            'brand': _brand.text,
            'warranty': _warranty.text,
            'notes': _notes.text,
            'rate_bp': _rateBp,
            'valid_days': _validDays,
          },
        ));
    ref.invalidate(quoteTemplatesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final iso = config.currencyCode;
    final rule = config.taxRule;
    final seller = ref.watch(mySellerProvider).value;
    final lead = ref.watch(leadProvider(widget.requestId)).value;
    final templates = ref.watch(quoteTemplatesProvider).value ?? const [];
    if (!_initialised && lead != null) {
      _initialised = true;
      if (_lines.first.desc.text.isEmpty) _lines.first.desc.text = lead.title;
      if (lead.fields['brand'] != null && _brand.text.isEmpty) _brand.text = '${lead.fields['brand']}';
    }
    final totals = _totals(iso, rule, seller, lead?.state);
    final symbol = iso == 'INR' ? '₹ ' : r'$ ';
    final priceFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reviseQuoteId != null ? l10n.quoteRevise : l10n.quoteFormTitle),
        actions: [
          if (templates.isNotEmpty)
            PopupMenuButton<QuoteTemplate>(
              tooltip: l10n.quoteUseTemplate,
              icon: const Icon(Icons.bookmarks_outlined),
              onSelected: _applyTemplate,
              itemBuilder: (_) => [for (final t in templates) PopupMenuItem(value: t, child: Text(t.name))],
            ),
          IconButton(tooltip: l10n.quoteSaveTemplate, onPressed: _saveTemplate, icon: const Icon(Icons.bookmark_add_outlined)),
        ],
      ),
      body: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: MaxWidth(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (lead != null) Text(lead.title, style: context.text.titleMedium),
            const SizedBox(height: 12),
            for (var i = 0; i < _lines.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(children: [
                  TextFormField(
                    controller: _lines[i].desc,
                    decoration: InputDecoration(
                      labelText: l10n.quoteItem,
                      suffixIcon: _lines.length > 1
                          ? IconButton(
                              tooltip: l10n.delete,
                              onPressed: () => setState(() => _lines.removeAt(i).dispose()),
                              icon: const Icon(Icons.remove_circle_outline))
                          : null,
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty ? l10n.required : null,
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    SizedBox(
                      width: 88,
                      child: TextFormField(
                        controller: _lines[i].qty,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(labelText: l10n.quoteQty),
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? l10n.required : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lines[i].price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [priceFormatter],
                        decoration: InputDecoration(labelText: l10n.quoteUnitPrice, prefixText: symbol),
                        validator: (v) => parseUserAmount(v ?? '', iso) == null ? l10n.quotePriceRequired : null,
                      ),
                    ),
                  ]),
                ]),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _lines.add(_LineCtl())),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.quoteAddLine),
              ),
            ),
            const SizedBox(height: 8),
            if (rule.rateOptionsBp.isNotEmpty) ...[
              Text(l10n.quoteTaxRate, style: context.text.labelLarge),
              const SizedBox(height: 4),
              Wrap(spacing: 8, children: [
                for (final bp in rule.rateOptionsBp)
                  ChoiceChip(
                    label: Text('${bpToPercent(bp)}%'),
                    selected: _rateBp == bp,
                    onSelected: (_) => setState(() => _rateBp = bp),
                  ),
              ]),
            ] else
              TextFormField(
                controller: _salesTax,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.quoteSalesTaxRate, suffixText: '%'),
                validator: (v) => (v ?? '').trim().isEmpty || percentToBp(v!) != null ? null : l10n.required,
                onChanged: (v) => setState(() => _rateBp = percentToBp(v) ?? 0),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _delivery,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [priceFormatter],
              decoration: InputDecoration(labelText: l10n.quoteDelivery, prefixText: symbol),
            ),
            const SizedBox(height: 16),
            _TotalsCard(totals: totals),
            const SizedBox(height: 16),
            TextFormField(controller: _brand, decoration: InputDecoration(labelText: l10n.quoteBrandModel)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_shipping_outlined),
              title: Text(l10n.quoteDeliveryDate),
              subtitle: Text(_deliveryDate == null ? l10n.postPickDate : context.date(_deliveryDate!)),
              onTap: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                    context: context, firstDate: now, lastDate: now.add(const Duration(days: 365)), initialDate: _deliveryDate ?? now);
                if (d != null) setState(() => _deliveryDate = d);
              },
            ),
            TextFormField(controller: _warranty, decoration: InputDecoration(labelText: l10n.quoteWarranty)),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _validDays,
              decoration: InputDecoration(labelText: l10n.quoteValidity),
              items: [for (final d in const [1, 3, 7, 14, 30]) DropdownMenuItem(value: d, child: Text(l10n.quoteValidityDays(d)))],
              onChanged: (v) => setState(() => _validDays = v ?? 7),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _notes, minLines: 2, maxLines: 5, decoration: InputDecoration(labelText: l10n.quoteNotes)),
            const SizedBox(height: 80),
          ]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BusyButton(
            label: '${widget.reviseQuoteId != null ? l10n.quoteRevise : l10n.quoteSubmit} · ${totals.total.display}',
            onPressed: _submit,
          ),
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals});
  final QuoteTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final b = totals.breakdown;
    Widget row(String k, String v, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(k, style: bold ? context.text.titleMedium : null)),
            Text(v, style: bold ? context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800) : null),
          ]),
        );
    return Card(
      color: context.colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          row(l10n.quoteSubtotal, totals.subtotal.display),
          if (b is GstBreakdown && b.intraState) ...[
            row('CGST ${bpToPercent(b.rateBp ~/ 2)}%', b.cgst.display),
            row('SGST ${bpToPercent(b.rateBp ~/ 2)}%', b.sgst.display),
          ] else if (b is GstBreakdown)
            row('IGST ${bpToPercent(b.rateBp)}%', b.igst.display)
          else if (b is SalesTaxBreakdown)
            row(l10n.salesTax(bpToPercent(b.rateBp)), b.amount.display),
          row(l10n.quoteDelivery, totals.delivery.display),
          const Divider(),
          row(l10n.quoteTotal, totals.total.display, bold: true),
        ]),
      ),
    );
  }
}
