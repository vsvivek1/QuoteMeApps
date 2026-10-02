import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_store.dart';
import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../domain/admin_auth_repository.dart';

/// Separate admin login: email + password, then an admin role check
/// (token claim + profile). Non-admin accounts are signed out again.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final l = context.l10n;
    try {
      await ref.read(adminAuthRepositoryProvider).signIn(email: _email.text, password: _password.text);
      ref.invalidate(adminSessionProvider);
    } on NotAdminException {
      setState(() => _error = l.loginNotAdmin);
    } on InvalidCredentialsException {
      setState(() => _error = l.loginInvalid);
    } catch (e) {
      setState(() => _error = l.loginFailed('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final env = ref.watch(adminEnvProvider);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: AutofillGroup(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Image.asset(config.logoAsset, height: 64, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                      const SizedBox(height: 12),
                      Text(l.adminTitle(config.appName),
                          textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(l.loginSubtitle, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(labelText: l.email),
                        validator: (v) => (v == null || !v.contains('@')) ? l.emailInvalid : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(labelText: l.password),
                        validator: (v) => (v == null || v.isEmpty) ? l.required : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(l.signIn),
                      ),
                      if (env.isDemo) ...[
                        const SizedBox(height: 16),
                        Text(
                          l.demoLoginHint(DemoStore.adminEmail, DemoStore.adminPassword),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
