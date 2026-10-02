import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../domain/seller.dart';

/// "Show my business on the {app} website" (Section 21.9 seller directory).
/// Off by default; the public page only ever shows business name, categories,
/// city, rating and response time (never phone or address).
class DirectoryOptInTile extends ConsumerStatefulWidget {
  const DirectoryOptInTile({super.key, required this.seller});
  final Seller seller;

  @override
  ConsumerState<DirectoryOptInTile> createState() => _DirectoryOptInTileState();
}

class _DirectoryOptInTileState extends ConsumerState<DirectoryOptInTile> {
  bool _busy = false;
  bool? _pending;

  Future<void> _set(bool value) async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _pending = value;
    });
    try {
      await ref.read(sellerRepositoryProvider).setDirectoryOptIn(value);
      if (mounted) context.toast(value ? l10n.sellerDirectoryOptInOn : l10n.sellerDirectoryOptInOff);
    } catch (_) {
      if (mounted) {
        setState(() => _pending = null);
        context.toast(l10n.somethingWentWrong);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void didUpdateWidget(DirectoryOptInTile old) {
    super.didUpdateWidget(old);
    if (!_busy && widget.seller.directoryOptIn == _pending) _pending = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appName = ref.watch(countryConfigProvider).appName;
    return SwitchListTile(
      key: const Key('directoryOptIn'),
      secondary: const Icon(Icons.public_outlined),
      title: Text(l10n.sellerDirectoryOptIn(appName)),
      subtitle: Text(l10n.sellerDirectoryOptInBody),
      isThreeLine: true,
      value: _pending ?? widget.seller.directoryOptIn,
      onChanged: _busy ? null : _set,
    );
  }
}
