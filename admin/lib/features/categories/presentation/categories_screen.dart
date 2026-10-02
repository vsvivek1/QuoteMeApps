import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/widgets/async_view.dart';
import '../../audit/application/audit_providers.dart';
import '../application/category_providers.dart';
import '../domain/category_models.dart';

/// Category and policy editor (Section 3.1): allowed / restricted / blocked
/// per country project. Anything uncertain starts as blocked.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  CategoryPolicy? _filter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(countryConfigProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navCategories),
        actions: [
          IconButton(
            tooltip: l.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminCategoriesProvider),
          ),
        ],
      ),
      body: AsyncView(
        value: ref.watch(adminCategoriesProvider),
        onRetry: () => ref.invalidate(adminCategoriesProvider),
        builder: (cats) {
          final byId = {for (final c in cats) c.id: c};
          final shown = cats.where((c) => _filter == null || c.policy == _filter).toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(l.categoriesIntro(config.appName)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              ChoiceChip(label: Text(l.all), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
              for (final p in CategoryPolicy.values)
                ChoiceChip(
                  label: Text(policyLabel(context, p)),
                  selected: _filter == p,
                  onSelected: (_) => setState(() => _filter = p),
                ),
            ]),
            const SizedBox(height: 12),
            Card(
              child: Column(children: [
                for (final c in shown) ...[
                  ListTile(
                    leading: _PolicyDot(c.policy),
                    title: Text(c.parentId == null ? c.name() : '${byId[c.parentId]?.name() ?? ''} › ${c.name()}'),
                    subtitle: Text([
                      c.slug,
                      if (c.requiredLicenceType != null && c.policy == CategoryPolicy.restricted)
                        '${l.licenceType}: ${c.requiredLicenceType}',
                      if (c.policyReason['en'] != null) c.policyReason['en']!,
                      if (!c.active) l.inactive,
                    ].join(' · ')),
                    trailing: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(policyLabel(context, c.policy)),
                      IconButton(
                        tooltip: l.edit,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(c, config.brochureLanguages),
                      ),
                    ]),
                  ),
                  const Divider(height: 1),
                ],
              ]),
            ),
          ]);
        },
      ),
    );
  }

  Future<void> _edit(AdminCategory c, List<String> languages) async {
    final result = await showDialog<AdminCategory>(
      context: context,
      builder: (_) => _CategoryDialog(category: c, languages: {'en', ...languages, ...c.names.keys}.toList()),
    );
    if (result == null || !mounted) return;
    final l = context.l10n;
    final repo = ref.read(categoryAdminRepositoryProvider);
    try {
      if (result.policy != c.policy ||
          result.requiredLicenceType != c.requiredLicenceType ||
          result.disclaimer != c.disclaimer ||
          result.policyReason != c.policyReason) {
        await repo.setPolicy(
          c.id,
          result.policy,
          requiredLicenceType: result.requiredLicenceType,
          disclaimer: result.disclaimer.isEmpty ? null : result.disclaimer,
          policyReason: result.policyReason.isEmpty ? null : result.policyReason,
        );
      }
      if (result.active != c.active || result.names != c.names) {
        await repo.update(c.id, names: result.names, active: result.active);
      }
      ref
        ..invalidate(adminCategoriesProvider)
        ..invalidate(auditLogProvider);
      if (mounted) context.toast(l.saved);
    } catch (e) {
      if (mounted) context.toast('$e', error: true);
    }
  }
}

String policyLabel(BuildContext context, CategoryPolicy p) => switch (p) {
      CategoryPolicy.allowed => context.l10n.policyAllowed,
      CategoryPolicy.restricted => context.l10n.policyRestricted,
      CategoryPolicy.blocked => context.l10n.policyBlocked,
    };

class _PolicyDot extends StatelessWidget {
  const _PolicyDot(this.policy);
  final CategoryPolicy policy;

  @override
  Widget build(BuildContext context) {
    final color = switch (policy) {
      CategoryPolicy.allowed => Colors.green.shade600,
      CategoryPolicy.restricted => Colors.amber.shade700,
      CategoryPolicy.blocked => Theme.of(context).colorScheme.error,
    };
    return Icon(Icons.circle, color: color, size: 14);
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.category, required this.languages});
  final AdminCategory category;
  final List<String> languages;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late CategoryPolicy _policy = widget.category.policy;
  late bool _active = widget.category.active;
  late final _licence = TextEditingController(text: widget.category.requiredLicenceType ?? '');
  late final _disclaimer = TextEditingController(text: widget.category.disclaimer['en'] ?? '');
  late final _reason = TextEditingController(text: widget.category.policyReason['en'] ?? '');
  late final _names = {
    for (final lang in widget.languages) lang: TextEditingController(text: widget.category.names[lang] ?? ''),
  };

  @override
  void dispose() {
    for (final c in [_licence, _disclaimer, _reason, ..._names.values]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid => _policy != CategoryPolicy.restricted || _licence.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.category.slug),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            SegmentedButton<CategoryPolicy>(
              segments: [
                for (final p in CategoryPolicy.values) ButtonSegment(value: p, label: Text(policyLabel(context, p))),
              ],
              selected: {_policy},
              onSelectionChanged: (s) => setState(() => _policy = s.first),
            ),
            const SizedBox(height: 12),
            if (_policy == CategoryPolicy.restricted)
              TextField(
                controller: _licence,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: l.licenceType, helperText: l.licenceTypeHelp),
              ),
            if (_policy != CategoryPolicy.allowed) ...[
              const SizedBox(height: 12),
              TextField(controller: _reason, maxLines: 2, decoration: InputDecoration(labelText: l.policyReasonEn)),
            ],
            const SizedBox(height: 12),
            TextField(controller: _disclaimer, maxLines: 2, decoration: InputDecoration(labelText: l.disclaimerEn)),
            const SizedBox(height: 16),
            Text(l.names, style: Theme.of(context).textTheme.titleSmall),
            for (final e in _names.entries)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(controller: e.value, decoration: InputDecoration(labelText: e.key)),
              ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.activeLabel),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            if (_policy == CategoryPolicy.allowed && widget.category.policy != CategoryPolicy.allowed)
              Text(l.unblockWarning, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: !_valid
              ? null
              : () {
                  Map<String, String> one(TextEditingController c, Map<String, String> old) =>
                      c.text.trim().isEmpty ? old : {...old, 'en': c.text.trim()};
                  final names = {
                    for (final e in _names.entries)
                      if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
                  };
                  final c = widget.category;
                  Navigator.pop(
                    context,
                    c.copyWith(
                      policy: _policy,
                      requiredLicenceType: _licence.text.trim().isEmpty ? null : _licence.text.trim(),
                      disclaimer: one(_disclaimer, c.disclaimer),
                      policyReason: one(_reason, c.policyReason),
                      names: _mapEquals(names, c.names) ? c.names : names,
                      active: _active,
                    ),
                  );
                },
          child: Text(l.save),
        ),
      ],
    );
  }
}

bool _mapEquals(Map<String, String> a, Map<String, String> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
