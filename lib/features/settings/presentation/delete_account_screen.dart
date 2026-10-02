import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../auth/domain/auth_repository.dart';

/// In-app account deletion (required by Apple and Google Play). The
/// delete-account Edge Function deletes or anonymises data, keeps what the
/// law requires, and revokes the Apple token.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (!mounted) return;
      context.toast(l10n.deleteDone);
      context.go('/welcome');
    } on AuthFailure catch (e) {
      if (!mounted) return;
      context.toast(e.code == 'reauth_required' ? l10n.deleteReauth : l10n.somethingWentWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteTitle)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: context.colors.error),
            const SizedBox(height: 12),
            Text(l10n.deleteBody),
            const SizedBox(height: 24),
            TextField(
              controller: _confirm,
              decoration: InputDecoration(labelText: l10n.deleteConfirmLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.error,
                foregroundColor: context.colors.onError,
              ),
              onPressed: _confirm.text.trim().toUpperCase() == l10n.deleteConfirmWord ? _delete : null,
              child: Text(l10n.deleteButton),
            ),
          ],
        ),
      ),
    );
  }
}
