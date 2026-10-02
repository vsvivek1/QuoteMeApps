import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../domain/quote.dart';
import '../domain/quote_repository.dart';

/// Buyer actions on a quote, shared by the request detail, quote detail and
/// compare screens.
class QuoteActions {
  QuoteActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;

  QuoteRepository get _repo => ref.read(quoteRepositoryProvider);

  Future<void> accept(Quote q) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.acceptConfirmTitle),
        content: Text('${q.total.display}\n\n${l10n.acceptConfirmBody(q.seller.businessName)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.accept)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final orderId = await _repo.acceptQuote(q.id);
      await ref.read(analyticsProvider).log(AnalyticsEvent.quoteAccepted, {'quote_id': q.id});
      if (!context.mounted) return;
      context.toast(l10n.acceptedBody(q.seller.businessName));
      context.push('/orders/$orderId');
      // Success moment: ask for a store review (the OS rate-limits this).
      final review = InAppReview.instance;
      if (await review.isAvailable()) await review.requestReview();
    } on QuoteFailure catch (e) {
      if (context.mounted) context.toast(quoteFailureText(context, e.code));
    }
  }

  Future<void> decline(Quote q) async {
    final l10n = context.l10n;
    final reasons = [l10n.declineReasonPrice, l10n.declineReasonDelivery, l10n.declineReasonOther];
    String? reason;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.declineTitle, style: ctx.text.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.declineReason),
              RadioGroup<String>(
                groupValue: reason,
                onChanged: (v) => set(() => reason = v),
                child: Column(children: [
                  for (final r in reasons) RadioListTile<String>(value: r, title: Text(r)),
                ]),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.decline)),
              ),
            ]),
          ),
        ),
      ),
    );
    if (ok == true) await _repo.declineQuote(q.id, reason: reason);
  }

  Future<void> toggleShortlist(Quote q) =>
      _repo.setShortlisted(q.id, q.status != QuoteStatus.shortlisted);

  Future<void> counterOffer(Quote q) async {
    final l10n = context.l10n;
    final price = TextEditingController();
    final note = TextEditingController();
    final iso = q.total.isoCode;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(ctx).bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l10n.counterOfferTitle, style: ctx.text.titleLarge),
          const SizedBox(height: 4),
          Text('${q.seller.businessName} · ${q.total.display}'),
          const SizedBox(height: 16),
          TextField(
            controller: price,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(labelText: l10n.counterOfferTarget, prefixText: iso == 'INR' ? '₹ ' : r'$ '),
          ),
          const SizedBox(height: 12),
          TextField(controller: note, decoration: InputDecoration(labelText: l10n.counterOfferNote)),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.send)),
        ]),
      ),
    );
    final target = parseUserAmount(price.text, iso);
    if (ok == true && target != null) {
      await _repo.counterOffer(q.id, target, note: note.text.trim().isEmpty ? null : note.text.trim());
      if (context.mounted) context.toast(l10n.counterOfferSent);
    }
  }

  Future<void> chat(Quote q) async {
    final chatId = await ref.read(chatRepositoryProvider).openChat(requestId: q.requestId, sellerId: q.seller.id);
    if (context.mounted) context.push('/chats/$chatId');
  }
}

String quoteFailureText(BuildContext context, String code) {
  final l10n = context.l10n;
  return switch (code) {
    'cap_reached' => l10n.quoteCapReached,
    'request_closed' => l10n.quoteRequestClosed,
    'licence_required' => l10n.quoteLicenceRequired,
    'no_credits' => l10n.quoteNoCredits,
    'priority_window' => l10n.quotePriorityWindow,
    'already_quoted' => l10n.quoteAlreadySent,
    'not_allowed' => l10n.quoteNotAllowed,
    _ => l10n.somethingWentWrong,
  };
}

String quoteStatusLabel(BuildContext context, QuoteStatus s) {
  final l10n = context.l10n;
  return switch (s) {
    QuoteStatus.sent => l10n.quoteStatusSent,
    QuoteStatus.revised => l10n.quoteStatusRevised,
    QuoteStatus.shortlisted => l10n.quoteStatusShortlisted,
    QuoteStatus.declined => l10n.quoteStatusDeclined,
    QuoteStatus.accepted => l10n.quoteStatusAccepted,
    QuoteStatus.withdrawn => l10n.quoteStatusWithdrawn,
    QuoteStatus.expired => l10n.quoteStatusExpired,
  };
}
