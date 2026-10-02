import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/country_config.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/services/device_services.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../application/post_request_controller.dart';
import '../application/request_providers.dart';
import '../domain/buyer_request.dart';
import '../domain/category.dart';
import 'category_picker.dart';
import 'dynamic_fields.dart';

/// The post-request wizard: 3 steps, built to feel like sending a message.
class PostRequestScreen extends ConsumerStatefulWidget {
  const PostRequestScreen({super.key, this.initialText, this.categoryId});
  final String? initialText;
  final int? categoryId;

  @override
  ConsumerState<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends ConsumerState<PostRequestScreen> {
  final _text = TextEditingController();
  final _link = TextEditingController();
  final _budgetMin = TextEditingController();
  final _budgetMax = TextEditingController();
  final _code = TextEditingController();
  final _locality = TextEditingController();
  final _address = TextEditingController();
  final _detailsForm = GlobalKey<FormState>();
  final _whereForm = GlobalKey<FormState>();
  Timer? _debounce;
  bool _listening = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _text.text = widget.initialText ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(postRequestControllerProvider.notifier);
      c.init(text: widget.initialText, categoryId: widget.categoryId);
      final config = ref.read(countryConfigProvider);
      c.update((d) => d.copyWith(state: d.state ?? config.demoCities.first.state));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_text, _link, _budgetMin, _budgetMax, _code, _locality, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  PostRequestController get _c => ref.read(postRequestControllerProvider.notifier);

  void _onText(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _c.onTextChanged(v));
  }

  Future<void> _toggleMic() async {
    final speech = ref.read(speechServiceProvider);
    if (_listening) {
      await speech.stop();
      setState(() => _listening = false);
      return;
    }
    final base = _text.text;
    final ok = await speech.start(Localizations.localeOf(context).toString(), (words, done) {
      _text.text = [base, words].where((s) => s.isNotEmpty).join(' ');
      _onText(_text.text);
      if (done && mounted) setState(() => _listening = false);
    });
    if (mounted) setState(() => _listening = ok);
  }

  Future<void> _addPhotos() async {
    final current = ref.read(postRequestControllerProvider).draft.localMediaPaths.length;
    final paths = await ref.read(mediaServiceProvider).pickImages(limit: 6 - current);
    _c.addMedia(paths);
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    try {
      final pos = await ref.read(locationServiceProvider).current();
      if (pos != null) _c.update((d) => d.copyWith(lat: pos.lat, lng: pos.lng));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _next() {
    final s = ref.read(postRequestControllerProvider);
    final l10n = context.l10n;
    switch (s.step) {
      case 0:
        if (s.blocked != null) return;
        if (_text.text.trim().isEmpty && s.draft.localMediaPaths.isEmpty) {
          context.toast(l10n.postDescribeRequired);
          return;
        }
        if (s.draft.categoryId == null) {
          context.toast(l10n.postCategoryRequired);
          return;
        }
        _c.goTo(1);
      case 1:
        if (!(_detailsForm.currentState?.validate() ?? true)) return;
        final iso = ref.read(countryConfigProvider).currencyCode;
        _c.setBudget(parseUserAmount(_budgetMin.text, iso), parseUserAmount(_budgetMax.text, iso));
        _c.update((d) => d.copyWith(referenceLink: _link.text.trim().isEmpty ? null : _link.text.trim()));
        _c.goTo(2);
      case 2:
        if (!_whereForm.currentState!.validate()) return;
        _c.update(
          (d) => d.copyWith(
            locationCode: _code.text.trim(),
            locality: _locality.text.trim(),
            fullAddress: _address.text.trim().isEmpty ? null : _address.text.trim(),
          ),
        );
        _submit();
    }
  }

  Future<void> _submit() async {
    final created = await _c.submit();
    if (!mounted || created == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 48),
        title: Text(ctx.l10n.postSuccessTitle),
        content: Text(ctx.l10n.postSuccessBody(created.notifiedSellers)),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.done))],
      ),
    );
    if (mounted) context.pushReplacement('/requests/${created.id}');
  }

  String? _errorText(String? code) => switch (code) {
    null => null,
    'rate_limited' => context.l10n.postRateLimited,
    'duplicate' => context.l10n.postDuplicate,
    'blocked_category' => context.l10n.postBlockedReason,
    _ => context.l10n.somethingWentWrong,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = ref.watch(postRequestControllerProvider);
    final config = ref.watch(countryConfigProvider);
    final cats = ref.watch(categoryMapProvider).value ?? const <int, Category>{};
    final category = cats[s.draft.categoryId];
    final steps = [l10n.postStepWhat, l10n.postStepDetails, l10n.postStepWhere];

    return PopScope(
      canPop: s.step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _c.goTo(s.step - 1);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.postTitle),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(36),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  for (var i = 0; i < steps.length; i++) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: i <= s.step ? 1 : 0,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          const SizedBox(height: 4),
                          Text(steps[i], style: context.text.labelSmall),
                        ],
                      ),
                    ),
                    if (i < steps.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: MaxWidth(
            child: IndexedStack(
              index: s.step,
              children: [
                _whatStep(context, s, category, cats),
                _detailsStep(context, s, category, config),
                _whereStep(context, s, category, config),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (s.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_errorText(s.error)!, style: TextStyle(color: context.colors.error)),
                  ),
                Row(
                  children: [
                    if (s.step > 0) ...[
                      OutlinedButton(onPressed: () => _c.goTo(s.step - 1), child: Text(l10n.back)),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: s.submitting || s.blocked != null ? null : _next,
                        child: s.submitting
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                            : Text(s.step == 2 ? l10n.postSubmit : l10n.next),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _whatStep(BuildContext context, PostRequestState s, Category? category, Map<int, Category> cats) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _text,
          autofocus: widget.initialText == null && widget.categoryId == null,
          minLines: 3,
          maxLines: 8,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          onChanged: _onText,
          decoration: InputDecoration(
            hintText: l10n.postDescribeHint,
            suffixIcon: IconButton(
              tooltip: _listening ? l10n.postListening : l10n.postSpeak,
              onPressed: _toggleMic,
              icon: Icon(
                _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _listening ? context.colors.error : null,
              ),
            ),
          ),
        ),
        if (s.blocked != null)
          Card(
            color: context.colors.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.block_rounded, color: context.colors.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.postBlockedCategory(s.blocked!.name(context.lang), l10n.postBlockedReason),
                      style: TextStyle(color: context.colors.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(category == null ? l10n.postPickCategory : l10n.postSuggestedCategory, style: context.text.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (category != null && !s.suggestions.contains(category))
              ChoiceChip(label: Text(category.name(context.lang)), selected: true, onSelected: (_) {}),
            for (final c in s.suggestions)
              ChoiceChip(
                label: Text(c.name(context.lang)),
                selected: c.id == category?.id,
                onSelected: (_) => _c.setCategory(c),
              ),
            ActionChip(
              avatar: const Icon(Icons.list_rounded, size: 18),
              label: Text(category == null ? l10n.postPickCategory : l10n.postChangeCategory),
              onPressed: () async {
                final picked = await showCategoryPicker(context, cats.values.toList());
                if (picked != null) _c.setCategory(picked);
              },
            ),
          ],
        ),
        if (category?.isRestricted ?? false) ...[
          const SizedBox(height: 12),
          _Notice(icon: Icons.verified_user_outlined, text: l10n.postRestrictedNotice),
        ],
        const SizedBox(height: 20),
        Text(l10n.postAddPhotos, style: context.text.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final p in s.draft.localMediaPaths)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: _thumb(p)),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          iconSize: 16,
                          tooltip: l10n.delete,
                          onPressed: () => _c.removeMedia(p),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              if (s.draft.localMediaPaths.length < 6)
                SizedBox(
                  width: 88,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: _addPhotos,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined),
                        const SizedBox(height: 4),
                        Text(l10n.postPhotosCount(s.draft.localMediaPaths.length), style: context.text.labelSmall),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _thumb(String path) {
    if (kIsWeb || path.startsWith('http')) {
      return Image.network(
        path,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox(width: 88, height: 88, child: Icon(Icons.image)),
      );
    }
    return Image.file(
      File(path),
      width: 88,
      height: 88,
      fit: BoxFit.cover,
      cacheWidth: 176,
      errorBuilder: (_, _, _) => const SizedBox(width: 88, height: 88, child: Icon(Icons.image)),
    );
  }

  Widget _detailsStep(BuildContext context, PostRequestState s, Category? category, CountryConfig config) {
    final l10n = context.l10n;
    final disclaimer = category?.disclaimerText(context.lang);
    return Form(
      key: _detailsForm,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (category != null) ...[
            Text(category.name(context.lang), style: context.text.titleMedium),
            const SizedBox(height: 12),
            DynamicFields(fields: category.fields, values: s.draft.fields, onChanged: _c.setField),
          ],
          if (disclaimer != null) _Notice(icon: Icons.info_outline_rounded, text: disclaimer),
          const SizedBox(height: 8),
          Text('${l10n.postBudget} (${l10n.optional})', style: context.text.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _moneyField(_budgetMin, l10n.postBudgetMin, config)),
              const SizedBox(width: 12),
              Expanded(child: _moneyField(_budgetMax, l10n.postBudgetMax, config)),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: !s.draft.budgetVisible,
            onChanged: (v) => _c.update((d) => d.copyWith(budgetVisible: !v)),
            title: Text(l10n.postBudgetHidden),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_rounded),
            title: Text(l10n.postNeededBy),
            subtitle: Text(s.draft.neededBy == null ? l10n.postPickDate : context.date(s.draft.neededBy!)),
            trailing: s.draft.neededBy == null
                ? null
                : IconButton(
                    tooltip: l10n.delete,
                    onPressed: () => _c.update((d) => d.copyWith(neededBy: null)),
                    icon: const Icon(Icons.close_rounded),
                  ),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
                initialDate: s.draft.neededBy ?? now.add(const Duration(days: 3)),
              );
              if (picked != null) _c.update((d) => d.copyWith(neededBy: picked));
            },
          ),
          TextFormField(
            controller: _link,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(labelText: '${l10n.postReferenceLink} (${l10n.optional})'),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return null;
              final uri = Uri.tryParse(t);
              return uri != null && uri.hasScheme && uri.host.isNotEmpty ? null : l10n.somethingWentWrong;
            },
          ),
        ],
      ),
    );
  }

  Widget _moneyField(TextEditingController c, String label, CountryConfig config) => TextFormField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    decoration: InputDecoration(labelText: label, prefixText: config.currencyCode == 'INR' ? '₹ ' : r'$ '),
    validator: (v) => (v ?? '').trim().isEmpty || parseUserAmount(v!, config.currencyCode) != null
        ? null
        : context.l10n.quotePriceRequired,
  );

  Widget _whereStep(BuildContext context, PostRequestState s, Category? category, CountryConfig config) {
    final l10n = context.l10n;
    final codeLabel = config.country == Country.india ? l10n.postalCodeLabelIndia : l10n.postalCodeLabelUsa;
    final windows = {
      QuoteWindow.h24: l10n.quoteWindow24h,
      QuoteWindow.h48: l10n.quoteWindow48h,
      QuoteWindow.d7: l10n.quoteWindow7d,
    };
    final audiences = {
      Audience.local: l10n.audienceLocal,
      Audience.online: l10n.audienceOnline,
      Audience.both: l10n.audienceBoth,
    };
    return Form(
      key: _whereForm,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.postLocation, style: context.text.titleMedium),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _locating ? null : _useGps,
            icon: _locating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(s.draft.lat != null ? Icons.my_location_rounded : Icons.location_searching_rounded),
            label: Text(
              s.draft.lat != null
                  ? '${s.draft.lat!.toStringAsFixed(3)}, ${s.draft.lng!.toStringAsFixed(3)}'
                  : l10n.postUseGps,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _code,
                  keyboardType: config.country == Country.india ? TextInputType.number : TextInputType.text,
                  maxLength: config.postalCodeMaxLength,
                  decoration: InputDecoration(labelText: codeLabel, counterText: ''),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty && s.draft.lat == null) return l10n.postLocationRequired;
                    if (t.isNotEmpty && !config.postalCodeValidator(t)) return l10n.postCodeInvalid(codeLabel);
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: s.draft.state,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.sellerState),
                  items: [
                    for (final st in config.states)
                      DropdownMenuItem(
                        value: st,
                        child: Text(st, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => _c.update((d) => d.copyWith(state: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locality,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.postLocality),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _address,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(labelText: '${l10n.postFullAddress} (${l10n.optional})'),
          ),
          const SizedBox(height: 20),
          Text(l10n.postQuoteWindow, style: context.text.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<QuoteWindow>(
            segments: [for (final e in windows.entries) ButtonSegment(value: e.key, label: Text(e.value))],
            selected: {s.draft.quoteWindow},
            onSelectionChanged: (v) => _c.update((d) => d.copyWith(quoteWindow: v.first)),
          ),
          const SizedBox(height: 20),
          Text(l10n.postWhoCanQuote, style: context.text.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<Audience>(
            segments: [for (final e in audiences.entries) ButtonSegment(value: e.key, label: Text(e.value))],
            selected: {s.draft.audience},
            onSelectionChanged: (v) => _c.update((d) => d.copyWith(audience: v.first)),
          ),
          const SizedBox(height: 24),
          if (category != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(
                  _text.text.trim().isEmpty ? category.name(context.lang) : _text.text.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    category.name(context.lang),
                    if (s.draft.budgetMin != null || s.draft.budgetMax != null)
                      moneyRange(s.draft.budgetMin, s.draft.budgetMax),
                    if (s.draft.neededBy != null) context.date(s.draft.neededBy!),
                  ].join(' · '),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: context.colors.secondaryContainer, borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        Icon(icon, size: 20, color: context.colors.onSecondaryContainer),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: context.colors.onSecondaryContainer)),
        ),
      ],
    ),
  );
}
