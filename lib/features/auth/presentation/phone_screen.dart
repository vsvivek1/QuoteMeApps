import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../domain/auth_repository.dart';

/// Phone entry. With [link] the number is attached to the signed-in
/// Google/Apple account instead of signing in.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key, this.link = false});
  final bool link;

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final config = ref.read(countryConfigProvider);
    final auth = ref.read(authRepositoryProvider);
    final e164 = config.e164(_phone.text);
    try {
      if (widget.link) {
        await auth.linkPhone(e164);
      } else {
        await auth.sendPhoneOtp(e164);
      }
      if (mounted) {
        context.push('/auth/otp', extra: {'phone': e164, 'link': widget.link});
      }
    } on AuthFailure catch (e) {
      if (mounted) {
        context.toast(e.code == 'rate_limited' ? context.l10n.otpRateLimited : context.l10n.authFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(countryConfigProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: MaxWidth(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(widget.link ? l10n.addPhoneTitle : l10n.phoneTitle, style: context.text.headlineSmall),
                const SizedBox(height: 8),
                Text(widget.link ? l10n.addPhoneBody : l10n.phoneSubtitle),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _phone,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9 ()\-]')),
                    LengthLimitingTextInputFormatter(16),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.phoneLabel,
                    hintText: config.phoneHint,
                    prefixText: '${config.phoneDialCode} ',
                  ),
                  validator: (v) => config.phoneValidator(v ?? '') ? null : l10n.phoneInvalid,
                  onFieldSubmitted: (_) => _send(),
                ),
                const SizedBox(height: 24),
                BusyButton(label: l10n.sendCode, onPressed: _send),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone, this.link = false});
  final String phone;
  final bool link;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  Timer? _timer;
  int _seconds = 30;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) t.cancel();
      if (mounted) setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final auth = ref.read(authRepositoryProvider);
    setState(() => _error = null);
    try {
      if (widget.link) {
        await auth.verifyLinkedPhone(widget.phone, _code.text.trim());
        if (mounted) context.go('/');
      } else {
        await auth.verifyPhoneOtp(widget.phone, _code.text.trim());
        // The router redirect takes it from here.
      }
    } on AuthFailure {
      if (mounted) setState(() => _error = context.l10n.otpInvalid);
    }
  }

  Future<void> _resend() async {
    final auth = ref.read(authRepositoryProvider);
    try {
      widget.link ? await auth.linkPhone(widget.phone) : await auth.sendPhoneOtp(widget.phone);
      _startTimer();
    } on AuthFailure {
      if (mounted) context.toast(context.l10n.otpRateLimited);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: MaxWidth(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(l10n.otpTitle, style: context.text.headlineSmall),
              const SizedBox(height: 8),
              Text(l10n.otpSubtitle(widget.phone)),
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
          ),
        ),
      ),
    );
  }
}
