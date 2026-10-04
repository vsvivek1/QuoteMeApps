import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../domain/auth_repository.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Email sign-in: the address, then the 6-digit code Supabase emails.
/// Back from the code step returns to the address.
class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({super.key});

  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  Timer? _timer;
  int _seconds = 30;
  String? _error;

  /// The address the code went to; null while on the address step.
  String? _sentTo;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) t.cancel();
      if (mounted) setState(() => _seconds--);
    });
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final email = _email.text.trim().toLowerCase();
    try {
      await ref.read(authRepositoryProvider).sendEmailOtp(email);
      if (!mounted) return;
      setState(() {
        _sentTo = email;
        _error = null;
        _code.clear();
      });
      _startTimer();
    } on AuthFailure catch (e) {
      if (mounted) {
        context.toast(e.code == 'rate_limited' ? context.l10n.otpRateLimited : context.l10n.authFailed);
      }
    }
  }

  Future<void> _verify() async {
    setState(() => _error = null);
    try {
      await ref.read(authRepositoryProvider).verifyEmailOtp(_sentTo!, _code.text.trim());
      // The router redirect takes it from here.
    } on AuthFailure {
      if (mounted) setState(() => _error = context.l10n.otpInvalid);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).sendEmailOtp(_sentTo!);
      _startTimer();
    } on AuthFailure {
      if (mounted) context.toast(context.l10n.otpRateLimited);
    }
  }

  void _back() {
    _timer?.cancel();
    setState(() => _sentTo = null);
  }

  @override
  Widget build(BuildContext context) {
    final sentTo = _sentTo;
    return PopScope(
      canPop: sentTo == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(child: MaxWidth(child: sentTo == null ? _emailStep(context) : _codeStep(context, sentTo))),
      ),
    );
  }

  Widget _emailStep(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.emailTitle, style: context.text.headlineSmall),
          const SizedBox(height: 8),
          Text(l10n.emailSubtitle),
          const SizedBox(height: 24),
          TextFormField(
            controller: _email,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textInputAction: TextInputAction.send,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s')), LengthLimitingTextInputFormatter(254)],
            decoration: InputDecoration(labelText: l10n.emailLabel),
            validator: (v) => _emailPattern.hasMatch((v ?? '').trim()) ? null : l10n.emailInvalid,
            onFieldSubmitted: (_) => _send(),
          ),
          const SizedBox(height: 24),
          BusyButton(label: l10n.sendCode, onPressed: _send),
        ],
      ),
    );
  }

  Widget _codeStep(BuildContext context, String sentTo) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.otpTitle, style: context.text.headlineSmall),
        const SizedBox(height: 8),
        Text(l10n.emailOtpSubtitle(sentTo)),
        const SizedBox(height: 24),
        TextField(
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: context.text.headlineSmall?.copyWith(letterSpacing: 8),
          decoration: InputDecoration(labelText: l10n.otpLabel, errorText: _error, counterText: ''),
          onChanged: (v) {
            if (v.length == 6) _verify();
          },
        ),
        const SizedBox(height: 24),
        BusyButton(label: l10n.verify, onPressed: _verify),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _seconds > 0 ? null : _resend,
          child: Text(_seconds > 0 ? l10n.resendIn(_seconds) : l10n.resendCode),
        ),
      ],
    );
  }
}
