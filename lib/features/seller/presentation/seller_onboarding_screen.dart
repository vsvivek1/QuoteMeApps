import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/config/country_config.dart';
import '../../../core/providers.dart';
import '../../../core/services/device_services.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../auth/domain/app_user.dart';
import '../../requests/application/request_providers.dart';
import '../../requests/domain/category.dart';
import '../../requests/presentation/widgets.dart';
import '../application/seller_providers.dart';
import '../domain/seller.dart';

/// Business onboarding: profile, categories, service area, alerts.
/// Also used to edit an existing business profile.
class SellerOnboardingScreen extends ConsumerStatefulWidget {
  const SellerOnboardingScreen({super.key});

  @override
  ConsumerState<SellerOnboardingScreen> createState() => _SellerOnboardingScreenState();
}

class _SellerOnboardingScreenState extends ConsumerState<SellerOnboardingScreen> {
  int _step = 0;
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _years = TextEditingController();
  final _brands = TextEditingController();
  final _codes = TextEditingController();
  final _locality = TextEditingController();
  final _businessForm = GlobalKey<FormState>();
  Seller _seller = const Seller(id: '', businessName: '');
  String? _logoPath;
  final _newPhotos = <String>[];
  bool _loaded = false;

  @override
  void dispose() {
    for (final c in [_name, _desc, _years, _brands, _codes, _locality]) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(Seller? existing, CountryConfig config) {
    if (_loaded) return;
    _loaded = true;
    final city = config.demoCities.first;
    _seller =
        existing ??
        Seller(
          id: '',
          businessName: '',
          radiusKm: config.defaultRadiusKm,
          state: city.state,
          lat: city.center.lat,
          lng: city.center.lng,
        );
    _name.text = _seller.businessName;
    _desc.text = _seller.description;
    _years.text = _seller.yearsInBusiness?.toString() ?? '';
    _brands.text = _seller.brands.join(', ');
    _codes.text = _seller.serviceCodes.join(', ');
    _locality.text = _seller.locality ?? '';
  }

  Future<void> _useGps() async {
    final pos = await ref.read(locationServiceProvider).current();
    if (pos != null) setState(() => _seller = _seller.copyWith(lat: pos.lat, lng: pos.lng));
  }

  Future<void> _next() async {
    final l10n = context.l10n;
    switch (_step) {
      case 0:
        if (!_businessForm.currentState!.validate()) return;
        _seller = _seller.copyWith(
          businessName: _name.text.trim(),
          description: _desc.text.trim(),
          yearsInBusiness: int.tryParse(_years.text.trim()),
          brands: _brands.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        );
      case 1:
        if (_seller.categoryIds.isEmpty) {
          context.toast(l10n.categoriesRequired);
          return;
        }
      case 2:
        _seller = _seller.copyWith(
          serviceCodes: _codes.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          locality: _locality.text.trim(),
        );
      case 3:
        await _save();
        return;
    }
    setState(() => _step++);
  }

  Future<void> _save() async {
    final isNew = ref.read(mySellerProvider).value == null;
    await ref.read(sellerRepositoryProvider).upsertSeller(_seller, logoPath: _logoPath, newPhotoPaths: _newPhotos);
    await ref.read(profileRepositoryProvider).setActiveMode(AppMode.seller);
    if (isNew) await ref.read(analyticsProvider).log(AnalyticsEvent.sellerSignup);
    if (!mounted) return;
    context.toast(context.l10n.sellerProfileSaved);
    final profile = ref.read(myProfileProvider).value;
    if (profile?.phone == null) {
      context.go('/auth/link-phone');
    } else {
      context.go('/seller/leads');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final existing = ref.watch(mySellerProvider);
    if (existing.isLoading && !existing.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _load(existing.value, config);
    final steps = [l10n.sellerStepBusiness, l10n.sellerStepCategories, l10n.sellerStepArea, l10n.sellerStepNotify];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sellerOnboardingTitle)),
      body: SafeArea(
        child: MaxWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: i <= _step ? 1 : 0,
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              const SizedBox(height: 4),
                              Text(steps[i], style: context.text.labelSmall, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: switch (_step) {
                  0 => _businessStep(context),
                  1 => _categoriesStep(context),
                  2 => _areaStep(context, config),
                  _ => _notifyStep(context),
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_step > 0) ...[
                OutlinedButton(onPressed: () => setState(() => _step--), child: Text(l10n.back)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: BusyButton(label: _step == 3 ? l10n.save : l10n.next, onPressed: _next),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _businessStep(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _businessForm,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final p = await ref.read(mediaServiceProvider).pickImages(limit: 1);
                  if (p.isNotEmpty) setState(() => _logoPath = p.first);
                },
                child: CircleAvatar(
                  radius: 36,
                  child: Icon(_logoPath == null ? Icons.add_a_photo_outlined : Icons.check_rounded),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(l10n.addLogo)),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.businessName),
            validator: (v) => (v ?? '').trim().length < 2 ? l10n.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _desc,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(labelText: l10n.businessDescription),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _years,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.yearsInBusiness),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _brands,
            decoration: InputDecoration(labelText: l10n.brandsCarried),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final p = await ref.read(mediaServiceProvider).pickImages(limit: 6 - _newPhotos.length);
              setState(() => _newPhotos.addAll(p));
            },
            icon: const Icon(Icons.storefront_outlined),
            label: Text('${l10n.addShopPhotos} (${_seller.photos.length + _newPhotos.length})'),
          ),
        ],
      ),
    );
  }

  Widget _categoriesStep(BuildContext context) {
    final l10n = context.l10n;
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final parents = cats.where((c) => c.parentId == null).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.selectCategories, style: context.text.titleMedium),
        const SizedBox(height: 8),
        for (final p in parents)
          ExpansionTile(
            leading: Icon(categoryIcon(p.icon)),
            title: Text(p.name(context.lang)),
            initiallyExpanded: cats.any((c) => c.parentId == p.id && _seller.categoryIds.contains(c.id)),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in cats.where((c) => c.parentId == p.id && !c.isBlocked))
                    FilterChip(
                      avatar: c.isRestricted ? const Icon(Icons.verified_user_outlined, size: 16) : null,
                      label: Text(c.name(context.lang)),
                      selected: _seller.categoryIds.contains(c.id),
                      onSelected: (on) => setState(
                        () => _seller = _seller.copyWith(
                          categoryIds: on
                              ? [..._seller.categoryIds, c.id]
                              : _seller.categoryIds.where((id) => id != c.id).toList(),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        if (_seller.categoryIds.any((id) => cats.any((c) => c.id == id && c.isRestricted)))
          ListTile(leading: const Icon(Icons.verified_user_outlined), title: Text(l10n.licencesBody)),
      ],
    );
  }

  Widget _areaStep(BuildContext context, CountryConfig config) {
    final l10n = context.l10n;
    final codeLabel = config.country == Country.india ? l10n.postalCodeLabelIndia : l10n.postalCodeLabelUsa;
    final radius = _seller.radiusKm;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        RadioGroup<AreaType>(
          groupValue: _seller.areaType,
          onChanged: (v) => setState(() => _seller = _seller.copyWith(areaType: v!)),
          child: Column(
            children: [
              RadioListTile(value: AreaType.radius, title: Text(l10n.areaRadius)),
              RadioListTile(value: AreaType.codes, title: Text(l10n.areaCodes(codeLabel))),
              RadioListTile(value: AreaType.nationwide, title: Text(l10n.areaNationwide)),
            ],
          ),
        ),
        const Divider(),
        if (_seller.areaType == AreaType.radius) ...[
          ListTile(
            leading: const Icon(Icons.store_mall_directory_outlined),
            title: Text(l10n.shopLocation),
            subtitle: Text(
              _seller.lat == null
                  ? l10n.postUseGps
                  : '${_seller.lat!.toStringAsFixed(4)}, ${_seller.lng!.toStringAsFixed(4)}',
            ),
            trailing: IconButton(
              tooltip: l10n.postUseGps,
              onPressed: _useGps,
              icon: const Icon(Icons.my_location_rounded),
            ),
          ),
          Text(
            config.distanceUnitMiles ? l10n.radiusValueMiles((radius * 0.621371).round()) : l10n.radiusValue(radius),
          ),
          Slider(
            min: 1,
            max: 100,
            divisions: 99,
            value: radius.toDouble().clamp(1, 100),
            label: '$radius',
            onChanged: (v) => setState(() => _seller = _seller.copyWith(radiusKm: v.round())),
          ),
        ],
        if (_seller.areaType == AreaType.codes)
          TextField(
            controller: _codes,
            decoration: InputDecoration(
              labelText: l10n.areaCodes(codeLabel),
              helperText: l10n.serviceCodesHint(config.demoCities.map((c) => c.sampleCode).join(', ')),
            ),
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _seller.state,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.sellerState),
          items: [for (final s in config.states) DropdownMenuItem(value: s, child: Text(s))],
          onChanged: (v) => setState(() => _seller = _seller.copyWith(state: v)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _locality,
          decoration: InputDecoration(labelText: l10n.postLocality),
        ),
      ],
    );
  }

  Widget _notifyStep(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        RadioGroup<NotifyPreference>(
          groupValue: _seller.notifyPreference,
          onChanged: (v) => setState(() => _seller = _seller.copyWith(notifyPreference: v!)),
          child: Column(
            children: [
              RadioListTile(value: NotifyPreference.instant, title: Text(l10n.notifyInstant)),
              RadioListTile(value: NotifyPreference.hourly, title: Text(l10n.notifyHourly)),
              RadioListTile(value: NotifyPreference.quiet, title: Text(l10n.notifyQuiet)),
            ],
          ),
        ),
        if (_seller.notifyPreference == NotifyPreference.quiet)
          Row(
            children: [
              Expanded(
                child: _hourPicker(_seller.quietStartHour ?? 22, (h) => _seller = _seller.copyWith(quietStartHour: h)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _hourPicker(_seller.quietEndHour ?? 7, (h) => _seller = _seller.copyWith(quietEndHour: h)),
              ),
            ],
          ),
        if (_seller.notifyPreference == NotifyPreference.quiet)
          Text(l10n.quietHoursRange('${_seller.quietStartHour ?? 22}:00', '${_seller.quietEndHour ?? 7}:00')),
      ],
    );
  }

  Widget _hourPicker(int value, void Function(int) set) => DropdownButtonFormField<int>(
    initialValue: value,
    items: [for (var h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text('${h.toString().padLeft(2, '0')}:00'))],
    onChanged: (v) => setState(() => set(v!)),
  );
}
