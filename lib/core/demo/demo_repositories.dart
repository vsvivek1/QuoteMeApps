import 'dart:async';
import 'dart:math' as math;

import '../../features/auth/domain/app_user.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/chat/domain/chat.dart';
import '../../features/chat/domain/chat_repository.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/notifications/domain/notification_repository.dart';
import '../../features/orders/domain/order.dart';
import '../../features/orders/domain/order_repository.dart';
import '../../features/quotes/domain/quote.dart';
import '../../features/quotes/domain/quote_repository.dart';
import '../../features/requests/domain/buyer_request.dart';
import '../../features/requests/domain/category.dart';
import '../../features/requests/domain/request_repository.dart';
import '../../features/reviews/domain/review.dart';
import '../../features/reviews/domain/review_repository.dart';
import '../../features/safety/domain/safety_repository.dart';
import '../../features/seller/domain/lead.dart';
import '../../features/seller/domain/seller.dart';
import '../../features/seller/domain/seller_repository.dart';
import '../../features/settings/domain/app_settings.dart';
import '../money/money.dart';
import 'demo_backend.dart';

String _uid(DemoBackend b) {
  final id = b.currentUserId;
  if (id == null) throw const AuthFailure('not_signed_in');
  return id;
}

class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository(this.b);
  final DemoBackend b;
  final _pending = <String>{};

  @override
  AuthSession? get currentSession => b.session;

  @override
  Stream<AuthSession?> sessionChanges() async* {
    yield b.session;
    yield* b.sessionChanges;
  }

  @override
  Future<void> sendPhoneOtp(String e164, {String? captchaToken}) async {
    _pending.add(e164);
  }

  @override
  Future<void> verifyPhoneOtp(String e164, String code) async {
    if (!_pending.contains(e164) || code != DemoBackend.demoOtp) {
      throw const AuthFailure('invalid_otp');
    }
    b.signInWithPhone(e164);
  }

  @override
  Future<void> signInWithGoogle() async {
    final id = 'google-user';
    b.profiles.putIfAbsent(id, () => Profile(id: id, email: 'demo@example.com', name: 'Demo User'));
    b.signInAs(id);
  }

  @override
  Future<void> signInWithApple() async {
    final id = 'apple-user';
    b.profiles.putIfAbsent(id, () => Profile(id: id, email: 'relay@privaterelay.appleid.com'));
    b.signInAs(id);
  }

  @override
  Future<void> linkPhone(String e164) async => _pending.add(e164);

  @override
  Future<void> verifyLinkedPhone(String e164, String code) async {
    if (code != DemoBackend.demoOtp) throw const AuthFailure('invalid_otp');
    final id = _uid(b);
    b.profiles[id] = b.profiles[id]!.copyWith(phone: e164, phoneVerified: true);
    b.notify();
  }

  @override
  Future<void> signOut() async => b.signOut();

  @override
  Future<void> deleteAccount({String? reason}) async {
    final id = _uid(b);
    b.profiles.remove(id);
    b.sellers.remove(id);
    b.signOut();
  }
}

class DemoProfileRepository implements ProfileRepository {
  DemoProfileRepository(this.b);
  final DemoBackend b;

  @override
  Stream<Profile?> watchMyProfile() => b.watch(() => b.profiles[b.currentUserId]);

  @override
  Future<Profile?> fetchMyProfile() async => b.profiles[b.currentUserId];

  @override
  Future<void> updateProfile({String? name, String? language, String? photoPath}) async {
    final id = _uid(b);
    final p = b.profiles[id]!;
    b.profiles[id] = p.copyWith(
      name: name ?? p.name,
      language: language ?? p.language,
      photoUrl: photoPath ?? p.photoUrl,
    );
    b.notify();
  }

  @override
  Future<void> setActiveMode(AppMode mode) async {
    final id = _uid(b);
    final p = b.profiles[id]!;
    b.profiles[id] = p.copyWith(activeMode: mode);
    b.notify();
  }

  @override
  Future<void> recordConsents(Map<String, String> documentVersions,
      {bool marketing = false, bool analytics = false}) async {
    b.consents[_uid(b)] = {
      ...documentVersions,
      if (marketing) 'marketing': '1',
      if (analytics) 'analytics': '1',
    };
    b.notify();
  }

  @override
  Future<bool> hasAcceptedCurrentTerms(String termsVersion, String privacyVersion) async {
    final c = b.consents[b.currentUserId];
    return c != null && c['terms'] == termsVersion && c['privacy'] == privacyVersion;
  }
}

class DemoCategoryRepository implements CategoryRepository {
  DemoCategoryRepository(this.b);
  final DemoBackend b;

  @override
  Future<List<Category>> fetchAll({bool forceRefresh = false}) async => b.categories;

  @override
  Future<List<Category>> suggest(String text) async => suggestCategories(b.categories, text);

  @override
  Future<Category?> blockedMatch(String text) async {
    final s = suggestCategories(b.categories, text, includeBlocked: true);
    return s.where((c) => c.isBlocked).firstOrNull;
  }
}

/// Keyword matcher shared by the demo and the Supabase repository (which
/// also has the server-side classifier as the source of truth).
List<Category> suggestCategories(List<Category> all, String text, {bool includeBlocked = false}) {
  final t = ' ${text.toLowerCase()} ';
  if (t.trim().isEmpty) return const [];
  final scored = <Category, int>{};
  for (final c in all.where((c) => c.isLeaf)) {
    if (c.isBlocked && !includeBlocked) continue;
    var score = 0;
    for (final k in c.keywords) {
      if (k.isEmpty) continue;
      if (t.contains(' ${k.toLowerCase()}') || t.contains(k.toLowerCase())) score += k.length;
    }
    for (final n in c.names.values) {
      if (n.isNotEmpty && t.contains(n.toLowerCase())) score += n.length;
    }
    if (score > 0) scored[c] = score;
  }
  final list = scored.keys.toList()..sort((a, b) => scored[b]!.compareTo(scored[a]!));
  return list.take(5).toList();
}

class DemoRequestRepository implements RequestRepository {
  DemoRequestRepository(this.b);
  final DemoBackend b;

  @override
  Future<BuyerRequest> createRequest(RequestDraft draft) async {
    try {
      final cat = b.categories.firstWhere((c) => c.id == draft.categoryId);
      final title = draft.text.trim().isEmpty
          ? cat.name('en')
          : draft.text.trim().split('\n').first;
      return b.createRequest(_uid(b), draft, title: title.length > 80 ? '${title.substring(0, 80)}…' : title);
    } on StateError catch (e) {
      throw RequestFailure(e.message);
    }
  }

  @override
  Stream<List<BuyerRequest>> watchMyRequests() => b.watch(() {
        final id = b.currentUserId;
        return b.requests.values.where((r) => r.buyerId == id).toList()
          ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
      });

  @override
  Stream<BuyerRequest?> watchRequest(String id) => b.watch(() => b.requests[id]);

  @override
  Future<void> cancelRequest(String id) async {
    final r = b.requests[id]!;
    b.requests[id] = r.copyWith(status: RequestStatus.cancelled);
    b.notify();
  }

  @override
  Future<int> postalCodeLookupCount(String code) async => 1;
}

class DemoQuoteRepository implements QuoteRepository {
  DemoQuoteRepository(this.b);
  final DemoBackend b;

  T _wrap<T>(T Function() f) {
    try {
      return f();
    } on StateError catch (e) {
      throw QuoteFailure(e.message);
    }
  }

  @override
  Stream<List<Quote>> watchQuotesForRequest(String requestId) => b.watch(() {
        final blocked = b.blocks[b.currentUserId] ?? const {};
        return b.quotes.values
            .where((q) => q.requestId == requestId && !blocked.contains(q.seller.id))
            .toList()
          ..sort((x, y) => x.createdAt.compareTo(y.createdAt));
      });

  @override
  Future<Quote?> getQuote(String quoteId) async => b.quotes[quoteId];

  @override
  Future<Quote> submitQuote(QuoteDraft draft) async => _wrap(() => b.submitQuote(_uid(b), draft));

  @override
  Future<Quote> reviseQuote(String quoteId, QuoteDraft draft) async {
    final q = b.quotes[quoteId]!;
    final seller = b.sellers[b.quoteSellerIds[quoteId]]!;
    final r = b.requests[q.requestId]!;
    final totals = b.config.taxRule.compute(
      lines: draft.lines,
      delivery: draft.delivery,
      rateBp: draft.taxRateBp,
      sellerState: seller.state,
      buyerState: r.state,
    );
    b.updateQuote(
      quoteId,
      (q) => q.copyWith(
        lines: draft.lines,
        subtotal: totals.subtotal,
        tax: totals.tax,
        taxBreakdown: totals.breakdown,
        delivery: totals.delivery,
        total: totals.total,
        offeredBrandModel: draft.offeredBrandModel,
        deliveryDate: draft.deliveryDate,
        warranty: draft.warranty,
        notes: draft.notes,
        status: QuoteStatus.revised,
        updatedAt: DateTime.now(),
      ),
    );
    b.addNotification(r.buyerId, 'quote_revised', {'request_id': r.id, 'quote_id': quoteId});
    return b.quotes[quoteId]!;
  }

  @override
  Future<void> withdrawQuote(String quoteId) async {
    b.updateQuote(quoteId, (q) => q.copyWith(status: QuoteStatus.withdrawn));
    final r = b.requests[b.quotes[quoteId]!.requestId]!;
    b.requests[r.id] = r.copyWith(quoteCount: r.quoteCount - 1);
    b.notify();
  }

  @override
  Stream<List<Quote>> watchMyQuotes(String bucket) => b.watch(() {
        final id = b.currentUserId;
        return b.quotes.values.where((q) {
          if (b.quoteSellerIds[q.id] != id) return false;
          return switch (bucket) {
            'won' => q.status == QuoteStatus.accepted,
            'lost' => q.status == QuoteStatus.declined ||
                q.status == QuoteStatus.expired ||
                q.status == QuoteStatus.withdrawn,
            _ => q.isActive,
          };
        }).toList()
          ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
      });

  @override
  Future<String> acceptQuote(String quoteId) async => _wrap(() => b.acceptQuote(_uid(b), quoteId));

  @override
  Future<void> declineQuote(String quoteId, {String? reason}) async => b.updateQuote(
        quoteId,
        (q) => q.copyWith(status: QuoteStatus.declined, declineReason: reason),
        notifySellerType: 'quote_declined',
      );

  @override
  Future<void> setShortlisted(String quoteId, bool shortlisted) async => b.updateQuote(
        quoteId,
        (q) => q.copyWith(status: shortlisted ? QuoteStatus.shortlisted : QuoteStatus.sent),
        notifySellerType: shortlisted ? 'quote_shortlisted' : null,
      );

  @override
  Future<void> counterOffer(String quoteId, Money target, {String? note}) async => b.updateQuote(
        quoteId,
        (q) => q.copyWith(counterOfferTarget: target, counterOfferNote: note),
        notifySellerType: 'counter_offer',
      );

  @override
  Future<void> markViewed(String quoteId) async {
    final q = b.quotes[quoteId];
    if (q == null || q.viewedByBuyer) return;
    b.quotes[quoteId] = q.copyWith(viewedByBuyer: true);
    final r = b.requests[q.requestId]!;
    b.requests[r.id] = r.copyWith(unreadQuotes: (r.unreadQuotes - 1).clamp(0, 999));
    b.notify();
  }
}

class DemoSellerRepository implements SellerRepository {
  DemoSellerRepository(this.b);
  final DemoBackend b;

  @override
  Stream<Seller?> watchMySeller() => b.watch(() => b.sellers[b.currentUserId]);

  @override
  Future<Seller> upsertSeller(Seller seller, {String? logoPath, List<String> newPhotoPaths = const []}) async {
    final id = _uid(b);
    final s = seller.copyWith(
      id: id,
      logoUrl: logoPath ?? seller.logoUrl,
      photos: [...seller.photos, ...newPhotoPaths],
      earlyPartner: true,
    );
    b.sellers[id] = s;
    final p = b.profiles[id]!;
    if (!p.roles.contains(UserRole.seller)) {
      b.profiles[id] = p.copyWith(roles: [...p.roles, UserRole.seller], activeMode: AppMode.seller);
    }
    b.notify();
    return s;
  }

  @override
  Future<Seller?> getSeller(String id) async => b.sellers[id];

  @override
  Future<SellerStats> stats() async {
    final id = _uid(b);
    final mine = b.quotes.values.where((q) => b.quoteSellerIds[q.id] == id).toList();
    final won = mine.where((q) => q.status == QuoteStatus.accepted).toList();
    final lost = mine.where((q) => q.status == QuoteStatus.declined || q.status == QuoteStatus.expired).length;
    final s = b.sellers[id];
    final revenue = b.orders.values
        .where((o) => o.sellerId == id && o.paymentAmount != null)
        .map((o) => o.paymentAmount!)
        .fold(b.config.zero, (a, c) => a + c);
    return SellerStats(
      activeQuotes: mine.where((q) => q.isActive).length,
      won: won.length,
      lost: lost,
      winRate: mine.isEmpty ? 0 : won.length / mine.length,
      avgResponseMins: s?.avgResponseMins,
      revenueLogged: revenue,
      ratingAvg: s?.ratingAvg ?? 0,
      ratingCount: s?.ratingCount ?? 0,
      quotesThisMonth: mine.where((q) => q.createdAt.month == DateTime.now().month).length,
    );
  }

  @override
  Future<List<SellerDocument>> myDocuments() async => b.documents[b.currentUserId] ?? const [];

  @override
  Future<void> submitDocument(String docType, {String? number, String? filePath}) async {
    final id = _uid(b);
    b.documents.putIfAbsent(id, () => []).removeWhere((d) => d.docType == docType);
    b.documents[id]!.add(SellerDocument(id: b.newId(), docType: docType, docNumber: number, filePath: filePath));
    final s = b.sellers[id];
    if (s != null && s.verificationStatus != VerificationStatus.verified) {
      b.sellers[id] = s.copyWith(verificationStatus: VerificationStatus.pending);
    }
    b.notify();
  }

  @override
  Future<List<SellerLicence>> myLicences() async => b.licences[b.currentUserId] ?? const [];

  @override
  Future<void> submitLicence(SellerLicence licence, {String? filePath}) async {
    b.licences.putIfAbsent(_uid(b), () => []).add(licence.copyWith(id: b.newId()));
    b.notify();
  }

  @override
  Future<List<QuoteTemplate>> templates() async => b.templates[b.currentUserId] ?? const [];

  @override
  Future<void> saveTemplate(QuoteTemplate template) async {
    final list = b.templates.putIfAbsent(_uid(b), () => []);
    list.removeWhere((t) => t.id == template.id);
    list.add(template);
    b.notify();
  }

  @override
  Future<void> deleteTemplate(String id) async {
    b.templates[_uid(b)]?.removeWhere((t) => t.id == id);
    b.notify();
  }
}

class DemoLeadRepository implements LeadRepository {
  DemoLeadRepository(this.b);
  final DemoBackend b;
  final _seen = <String>{};

  Lead _toLead(BuyerRequest r, String sellerId) {
    final s = b.sellers[sellerId];
    double? km;
    if (s?.lat != null && r.lat != null) {
      km = _approxKm(r.lat!, r.lng!, s!.lat!, s.lng!);
    }
    return Lead(
      requestId: r.id,
      categoryId: r.categoryId,
      title: r.title,
      description: r.description,
      fields: r.fields,
      budgetMin: r.budgetVisible ? r.budgetMin : null,
      budgetMax: r.budgetVisible ? r.budgetMax : null,
      neededBy: r.neededBy,
      locality: r.locality,
      locationCode: r.locationCode,
      state: r.state,
      distanceKm: km,
      audience: r.audience,
      quoteCount: r.quoteCount,
      maxQuotes: r.maxQuotes,
      quoteWindowEndsAt: r.quoteWindowEndsAt,
      createdAt: r.createdAt,
      media: r.media,
      seen: _seen.contains(r.id),
      alreadyQuoted: b.quotes.values.any((q) => q.requestId == r.id && b.quoteSellerIds[q.id] == sellerId),
      buyerFirstName: b.profiles[r.buyerId]?.name?.split(' ').first,
    );
  }

  static double _approxKm(double lat1, double lng1, double lat2, double lng2) {
    final dx = (lng2 - lng1) * 111.32 * 0.9;
    final dy = (lat2 - lat1) * 110.57;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  Future<LeadPage> feed(LeadFilters filters, {String? cursor}) async {
    final id = _uid(b);
    final s = b.sellers[id];
    if (s == null) return const LeadPage(leads: []);
    final dismissed = b.dismissedLeads[id] ?? const {};
    final leads = b.requests.values
        .where((r) =>
            r.isOpen &&
            r.buyerId != id &&
            s.categoryIds.contains(r.categoryId) &&
            !dismissed.contains(r.id) &&
            !(b.blocks[r.buyerId]?.contains(id) ?? false) &&
            (s.isVerified || r.priorityUntil == null || DateTime.now().isAfter(r.priorityUntil!)) &&
            (filters.categoryId == null || r.categoryId == filters.categoryId))
        .map((r) => _toLead(r, id))
        .where((l) => filters.maxDistanceKm == null || (l.distanceKm ?? 0) <= filters.maxDistanceKm!)
        .toList()
      ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
    return LeadPage(leads: leads);
  }

  @override
  Future<Lead?> lead(String requestId) async {
    final r = b.requests[requestId];
    return r == null ? null : _toLead(r, _uid(b));
  }

  @override
  Future<void> dismiss(String requestId) async {
    b.dismissedLeads.putIfAbsent(_uid(b), () => {}).add(requestId);
    b.notify();
  }

  @override
  Future<void> markSeen(String requestId) async => _seen.add(requestId);

  @override
  Stream<void> newLeadSignals() => b.changes;
}

class DemoChatRepository implements ChatRepository {
  DemoChatRepository(this.b);
  final DemoBackend b;
  final _typing = StreamController<bool>.broadcast();

  Chat _decorate(Chat c) {
    final me = b.currentUserId;
    final isBuyer = c.buyerId == me;
    final name = isBuyer
        ? b.sellers[c.sellerId]?.businessName ?? ''
        : b.profiles[c.buyerId]?.name ?? '';
    final unread = (b.messages[c.id] ?? const [])
        .where((m) => m.senderId != me && m.readAt == null)
        .length;
    final accepted = b.requests[c.requestId]?.acceptedQuoteId != null &&
        b.quoteSellerIds[b.requests[c.requestId]!.acceptedQuoteId] == c.sellerId;
    return c.copyWith(counterpartName: name, unread: unread, quoteAccepted: accepted);
  }

  @override
  Stream<List<Chat>> watchMyChats() => b.watch(() {
        final me = b.currentUserId;
        return b.chats.values
            .where((c) => c.buyerId == me || c.sellerId == me)
            .map(_decorate)
            .toList()
          ..sort((x, y) => (y.lastMessageAt ?? DateTime(2000)).compareTo(x.lastMessageAt ?? DateTime(2000)));
      });

  @override
  Future<Chat?> getChat(String chatId) async {
    final c = b.chats[chatId];
    return c == null ? null : _decorate(c);
  }

  @override
  Future<String> openChat({required String requestId, required String sellerId}) async =>
      b.openChat(requestId, sellerId);

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) =>
      b.watch(() => List.unmodifiable(b.messages[chatId] ?? const <ChatMessage>[]));

  @override
  Future<List<ChatMessage>> olderMessages(String chatId, DateTime before) async => const [];

  @override
  Future<void> sendText(String chatId, String text) async => b.sendMessage(chatId, _uid(b), text);

  @override
  Future<void> sendImage(String chatId, String localPath) async =>
      b.sendMessage(chatId, _uid(b), '', type: MessageType.image, attachment: localPath);

  @override
  Future<void> markRead(String chatId) async {
    final me = b.currentUserId;
    final list = b.messages[chatId];
    if (list == null) return;
    var changed = false;
    for (var i = 0; i < list.length; i++) {
      if (list[i].senderId != me && list[i].readAt == null) {
        list[i] = list[i].copyWith(readAt: DateTime.now());
        changed = true;
      }
    }
    if (changed) b.notify();
  }

  @override
  Stream<bool> typing(String chatId) => _typing.stream;

  @override
  void setTyping(String chatId, bool typing) {}
}

class DemoOrderRepository implements OrderRepository {
  DemoOrderRepository(this.b);
  final DemoBackend b;

  @override
  Stream<List<Order>> watchMyOrders() => b.watch(() {
        final me = b.currentUserId;
        return b.orders.values.where((o) => o.buyerId == me || o.sellerId == me).toList()
          ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
      });

  @override
  Stream<Order?> watchOrder(String id) => b.watch(() => b.orders[id]);

  @override
  Future<void> updateStatus(String orderId, OrderStatus status, {String? note}) async {
    final o = b.orders[orderId]!;
    b.orders[orderId] = o.copyWith(
      status: status,
      events: [...o.events, OrderEvent(status: status, at: DateTime.now(), note: note)],
    );
    final other = o.buyerId == b.currentUserId ? o.sellerId : o.buyerId;
    b.addNotification(other, 'order_status', {'order_id': orderId, 'status': status.name});
  }

  @override
  Future<void> recordPayment(String orderId, String method, Money amount) async {
    final o = b.orders[orderId]!;
    b.orders[orderId] = o.copyWith(paymentMethod: method, paymentAmount: amount, paymentRecordedAt: DateTime.now());
    b.notify();
  }
}

class DemoReviewRepository implements ReviewRepository {
  DemoReviewRepository(this.b);
  final DemoBackend b;

  @override
  Future<void> submitReview({
    required String orderId,
    required int stars,
    List<String> tags = const [],
    String text = '',
    List<String> photoPaths = const [],
  }) async {
    final me = _uid(b);
    final o = b.orders[orderId]!;
    if (!o.isCompleted) throw StateError('order_not_completed');
    final asBuyer = o.buyerId == me;
    final id = b.newId();
    b.reviews[id] = Review(
      id: id,
      orderId: orderId,
      fromId: me,
      toId: asBuyer ? o.sellerId : o.buyerId,
      role: asBuyer ? 'buyer' : 'seller',
      stars: stars,
      tags: tags,
      text: text,
      photos: photoPaths,
      authorName: b.profiles[me]?.name,
      createdAt: DateTime.now(),
    );
    b.orders[orderId] = asBuyer ? o.copyWith(buyerReviewed: true) : o.copyWith(sellerReviewed: true);
    if (asBuyer) {
      final s = b.sellers[o.sellerId]!;
      final count = s.ratingCount + 1;
      b.sellers[o.sellerId] = s.copyWith(
        ratingCount: count,
        ratingAvg: (s.ratingAvg * s.ratingCount + stars) / count,
      );
    }
    b.notify();
  }

  @override
  Future<List<Review>> reviewsFor(String userId) async =>
      b.reviews.values.where((r) => r.toId == userId).toList()
        ..sort((x, y) => y.createdAt.compareTo(x.createdAt));

  @override
  Future<void> reply(String reviewId, String text) async {
    final r = b.reviews[reviewId]!;
    if (r.sellerReply != null) throw StateError('already_replied');
    b.reviews[reviewId] = r.copyWith(sellerReply: text);
    b.notify();
  }
}

class DemoNotificationRepository implements NotificationRepository {
  DemoNotificationRepository(this.b);
  final DemoBackend b;

  @override
  Stream<List<AppNotification>> watchInbox() =>
      b.watch(() => List.unmodifiable(b.notifications[b.currentUserId] ?? const <AppNotification>[]));

  @override
  Future<void> markRead(String id) async {
    final list = b.notifications[b.currentUserId];
    if (list == null) return;
    final i = list.indexWhere((n) => n.id == id);
    if (i >= 0) list[i] = list[i].copyWith(readAt: DateTime.now());
    b.notify();
  }

  @override
  Future<void> markAllRead() async {
    final list = b.notifications[b.currentUserId];
    if (list == null) return;
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(readAt: list[i].readAt ?? DateTime.now());
    }
    b.notify();
  }

  @override
  Future<void> registerDeviceToken(String token, String platform) async {}

  @override
  Future<void> removeDeviceToken(String token) async {}
}

class DemoSafetyRepository implements SafetyRepository {
  DemoSafetyRepository(this.b);
  final DemoBackend b;

  @override
  Future<void> report(String targetType, String targetId, String reason, {String? details}) async {
    b.reports.add({'type': targetType, 'id': targetId, 'reason': reason, 'details': details ?? ''});
  }

  @override
  Future<void> block(String userId) async {
    b.blocks.putIfAbsent(_uid(b), () => {}).add(userId);
    b.notify();
  }

  @override
  Future<void> unblock(String userId) async {
    b.blocks[_uid(b)]?.remove(userId);
    b.notify();
  }

  @override
  Future<Set<String>> blockedUserIds() async => {...?b.blocks[b.currentUserId]};
}

class DemoFlagsRepository implements FlagsRepository {
  @override
  Future<AppFlags> load() async => AppFlags(
        earlyPartnerFreeUntil: DateTime.now().add(const Duration(days: 180)),
      );
}
