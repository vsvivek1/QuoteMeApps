import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/providers.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';

/// First-launch consent: Terms + Privacy (versions recorded in `consents`),
/// separate opt-ins for marketing and analytics, and the age confirmation.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _terms = false;
  bool _age = false;
  bool _marketing = false;
  bool _analytics = false;

  Future<void> _accept() async {
    final flags = await ref.read(appFlagsProvider.future);
    await ref.read(profileRepositoryProvider).recordConsents(
      {'terms': flags.termsVersion, 'privacy': flags.privacyVersion},
      marketing: _marketing,
      analytics: _analytics,
    );
    await ref.read(analyticsProvider).setCollectionEnabled(_analytics);
    ref.invalidate(consentAcceptedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(countryConfigProvider);
    final l10n = context.l10n;
    final terms = l10n.termsLink, privacy = l10n.privacyLink;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.consentTitle)),
      body: SafeArea(
        child: MaxWidth(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CheckboxListTile(
                value: _terms,
                onChanged: (v) => setState(() => _terms = v ?? false),
                title: Text(l10n.consentAccept(terms, privacy)),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Wrap(spacing: 8, children: [
                  TextButton(onPressed: () => context.push('/legal/terms'), child: Text(terms)),
                  TextButton(onPressed: () => context.push('/legal/privacy'), child: Text(privacy)),
                ]),
              ),
              CheckboxListTile(
                value: _age,
                onChanged: (v) => setState(() => _age = v ?? false),
                title: Text(l10n.consentAge(config.minimumAge)),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const Divider(),
              SwitchListTile(
                value: _marketing,
                onChanged: (v) => setState(() => _marketing = v),
                title: Text(l10n.consentMarketing),
              ),
              SwitchListTile(
                value: _analytics,
                onChanged: (v) => setState(() => _analytics = v),
                title: Text(l10n.consentAnalytics),
              ),
              const SizedBox(height: 24),
              BusyButton(
                label: l10n.continueLabel,
                onPressed: _terms && _age ? _accept : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
