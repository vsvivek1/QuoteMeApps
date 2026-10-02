import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/context_x.dart';
import '../domain/category.dart';

/// Renders a category's `field_schema` as form fields. Used by both the
/// request wizard and the quote form.
class DynamicFields extends StatelessWidget {
  const DynamicFields({
    super.key,
    required this.fields,
    required this.values,
    required this.onChanged,
  });

  final List<FieldDef> fields;
  final Map<String, Object?> values;
  final void Function(String key, Object? value) onChanged;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    return Column(
      children: [
        for (final f in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _field(context, f, lang),
          ),
      ],
    );
  }

  Widget _field(BuildContext context, FieldDef f, String lang) {
    final label = f.required ? f.label(lang) : '${f.label(lang)} (${context.l10n.optional})';
    String? requiredValidator(Object? v) =>
        f.required && (v == null || v.toString().trim().isEmpty) ? context.l10n.required : null;
    switch (f.type) {
      case FieldType.select:
        return DropdownButtonFormField<String>(
          initialValue: values[f.key]?.toString(),
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final o in f.options) DropdownMenuItem(value: o.value, child: Text(o.label(lang))),
          ],
          validator: requiredValidator,
          onChanged: (v) => onChanged(f.key, v),
        );
      case FieldType.multiselect:
        final selected = (values[f.key] as List?)?.cast<String>() ?? const <String>[];
        return InputDecorator(
          decoration: InputDecoration(labelText: label, border: InputBorder.none),
          child: Wrap(spacing: 8, children: [
            for (final o in f.options)
              FilterChip(
                label: Text(o.label(lang)),
                selected: selected.contains(o.value),
                onSelected: (on) => onChanged(
                  f.key,
                  on ? [...selected, o.value] : selected.where((s) => s != o.value).toList(),
                ),
              ),
          ]),
        );
      case FieldType.boolean:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label(lang)),
          value: values[f.key] == true,
          onChanged: (v) => onChanged(f.key, v),
        );
      case FieldType.number:
        return TextFormField(
          initialValue: values[f.key]?.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: InputDecoration(labelText: label, suffixText: f.unit),
          validator: requiredValidator,
          onChanged: (v) => onChanged(f.key, num.tryParse(v) ?? v),
        );
      case FieldType.date:
        final v = values[f.key] is String ? DateTime.tryParse(values[f.key] as String) : null;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: Text(v == null ? context.l10n.postPickDate : context.date(v)),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
                context: context, firstDate: now, lastDate: now.add(const Duration(days: 730)), initialDate: v ?? now);
            if (picked != null) onChanged(f.key, picked.toIso8601String());
          },
        );
      case FieldType.text:
        return TextFormField(
          initialValue: values[f.key]?.toString(),
          decoration: InputDecoration(labelText: label, suffixText: f.unit),
          textCapitalization: TextCapitalization.sentences,
          validator: requiredValidator,
          onChanged: (v) => onChanged(f.key, v),
        );
    }
  }
}

/// Read-only display of filled fields: "Capacity: 300 L".
class FieldSummary extends StatelessWidget {
  const FieldSummary({super.key, required this.fields, required this.values});
  final List<FieldDef> fields;
  final Map<String, Object?> values;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final rows = <(String, String)>[];
    for (final f in fields) {
      final v = values[f.key];
      if (v == null || v.toString().isEmpty) continue;
      String text;
      if (v is List) {
        text = v.join(', ');
      } else if (v is bool) {
        text = v ? context.l10n.yes : context.l10n.no;
      } else {
        final opt = f.options.where((o) => o.value == v.toString()).firstOrNull;
        text = opt?.label(lang) ?? v.toString();
      }
      rows.add((f.label(lang), f.unit == null ? text : '$text ${f.unit}'));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final (k, v) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 140, child: Text(k, style: context.text.bodySmall)),
              Expanded(child: Text(v, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
            ]),
          ),
      ],
    );
  }
}
