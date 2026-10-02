import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/utils/context_x.dart';
import '../domain/trends_models.dart';
import 'trends_widgets.dart';

/// Edits one `trend_settings` value. Object settings: one field per scalar
/// (one level of nesting, e.g. `ramp.health`), only changed fields are sent
/// (the server merges). Word lists: one per line. `app_links`: JSON.
/// The brief's floors are checked live (Save stays disabled), and a server
/// refusal is shown in the dialog.
class TrendSettingDialog extends StatefulWidget {
  const TrendSettingDialog({
    super.key,
    required this.settingKey,
    required this.value,
    this.description,
    required this.onSave,
  });

  final String settingKey;
  final Object? value;
  final String? description;
  final Future<void> Function(Object value) onSave;

  @override
  State<TrendSettingDialog> createState() => _TrendSettingDialogState();
}

enum _Kind { number, text, boolean, numberList, textList }

class _Field {
  _Field(this.path, this.kind, Object? initial)
      : ctrl = TextEditingController(
            text: switch (kind) {
              _Kind.numberList || _Kind.textList => (initial as List).join(', '),
              _Kind.boolean => '',
              _ => '${initial ?? ''}',
            }),
        flag = initial == true;
  final String path;
  final _Kind kind;
  final TextEditingController ctrl;
  bool flag;
}

class _TrendSettingDialogState extends State<TrendSettingDialog> {
  final _fields = <_Field>[];
  TextEditingController? _whole;
  bool _wholeIsJson = false;
  String? _serverError;
  bool _saving = false;

  Map<String, dynamic> get _old => widget.value is Map ? Map<String, dynamic>.from(widget.value as Map) : const {};

  static _Kind? _kindOf(Object? v) => switch (v) {
        bool() => _Kind.boolean,
        num() => _Kind.number,
        String() => _Kind.text,
        List() when v.every((e) => e is num) && v.isNotEmpty => _Kind.numberList,
        List() when v.every((e) => e is String) => _Kind.textList,
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    final v = widget.value;
    if (v is List) {
      _wholeIsJson = !v.every((e) => e is String);
      _whole = TextEditingController(
          text: _wholeIsJson ? const JsonEncoder.withIndent('  ').convert(v) : v.join('\n'));
      return;
    }
    for (final e in _old.entries) {
      if (widget.settingKey == 'ramp' && (e.key == 'usa' || e.key == 'india')) continue;
      final k = _kindOf(e.value);
      if (k != null) {
        _fields.add(_Field(e.key, k, e.value));
      } else if (e.value is Map) {
        for (final n in (e.value as Map).entries) {
          final nk = _kindOf(n.value);
          if (nk != null) _fields.add(_Field('${e.key}.${n.key}', nk, n.value));
        }
      }
    }
  }

  @override
  void dispose() {
    _whole?.dispose();
    for (final f in _fields) {
      f.ctrl.dispose();
    }
    super.dispose();
  }

  Object? _readField(_Field f) => switch (f.kind) {
        _Kind.boolean => f.flag,
        _Kind.number => num.tryParse(f.ctrl.text.trim()),
        _Kind.text => f.ctrl.text.trim(),
        _Kind.numberList => parseNumberList(f.ctrl.text),
        _Kind.textList => parseStringList(f.ctrl.text),
      };

  /// (value to send, parse errors). Objects: only the changed top-level keys.
  (Object?, List<String>) _build() {
    final errors = <String>[];
    if (_whole != null) {
      if (!_wholeIsJson) return (parseStringList(_whole!.text), errors);
      try {
        final v = jsonDecode(_whole!.text);
        if (v is! List) return (null, ['JSON array expected']);
        return (v, errors);
      } on FormatException catch (e) {
        return (null, ['JSON: ${e.message}']);
      }
    }
    final old = _old;
    final patch = <String, dynamic>{};
    for (final f in _fields) {
      final v = _readField(f);
      if (v == null) {
        errors.add(f.path);
        continue;
      }
      final parts = f.path.split('.');
      if (parts.length == 1) {
        if (jsonEncode(v) != jsonEncode(old[f.path])) patch[f.path] = v;
      } else {
        final parentOld = Map<String, dynamic>.from(old[parts[0]] as Map);
        if (jsonEncode(v) != jsonEncode(parentOld[parts[1]])) {
          final parent = Map<String, dynamic>.from(patch[parts[0]] as Map? ?? parentOld);
          parent[parts[1]] = v;
          patch[parts[0]] = parent;
        }
      }
    }
    return (patch, errors);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (value, parseErrors) = _build();
    final changed = value is Map ? value.isNotEmpty : (value != null && jsonEncode(value) != jsonEncode(widget.value));
    final problems = value == null
        ? const <String>[]
        : trendSettingProblems(widget.settingKey, widget.value, mergeSetting(widget.settingKey, widget.value, value));
    final canSave = !_saving && changed && parseErrors.isEmpty && problems.isEmpty && value != null;
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      title: Text(l.trendsEditSetting(widget.settingKey)),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.description != null && widget.description!.isNotEmpty) ...[
              Text(widget.description!, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
            ],
            if (_whole != null)
              TextField(
                key: ValueKey('trends-setting-${widget.settingKey}'),
                controller: _whole,
                minLines: 6,
                maxLines: 16,
                onChanged: (_) => setState(() => _serverError = null),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  helperText: _wholeIsJson ? l.trendsJsonHelp : l.trendsListHelp,
                ),
              )
            else
              for (final f in _fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: f.kind == _Kind.boolean
                      ? SwitchListTile(
                          key: ValueKey('trends-setting-${f.path}'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(f.path),
                          value: f.flag,
                          onChanged: (v) => setState(() {
                            f.flag = v;
                            _serverError = null;
                          }),
                        )
                      : TextField(
                          key: ValueKey('trends-setting-${f.path}'),
                          controller: f.ctrl,
                          keyboardType: f.kind == _Kind.number ? TextInputType.number : TextInputType.text,
                          onChanged: (_) => setState(() => _serverError = null),
                          decoration: InputDecoration(
                            labelText: f.path,
                            helperText: f.kind == _Kind.numberList || f.kind == _Kind.textList ? l.trendsCommaHelp : null,
                            errorText: parseErrors.contains(f.path) ? l.trendsInvalidNumber : null,
                          ),
                        ),
                ),
            for (final p in [...parseErrors.where((e) => _whole != null), ...problems])
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(l.trendsFloor(p), style: TextStyle(color: error)),
              ),
            if (_serverError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l.trendsServerRefused(_serverError!), key: const ValueKey('trends-setting-server-error'),
                    style: TextStyle(color: error, fontWeight: FontWeight.w600)),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(
          onPressed: canSave
              ? () async {
                  setState(() => _saving = true);
                  try {
                    await widget.onSave(value);
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    if (mounted) setState(() => _serverError = trendsErrorText(context, e));
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                }
              : null,
          child: Text(l.save),
        ),
      ],
    );
  }
}
