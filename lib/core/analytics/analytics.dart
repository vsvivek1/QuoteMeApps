import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers.dart';

part 'analytics.g.dart';

/// Event names from Section 13. Keep them stable: dashboards depend on them.
abstract final class AnalyticsEvent {
  static const requestStarted = 'request_started';
  static const requestPosted = 'request_posted';
  static const quoteReceived = 'quote_received';
  static const quoteViewed = 'quote_viewed';
  static const compareOpened = 'compare_opened';
  static const quoteAccepted = 'quote_accepted';
  static const sellerSignup = 'seller_signup';
  static const sellerVerified = 'seller_verified';
  static const leadViewed = 'lead_viewed';
  static const quoteSent = 'quote_sent';
  static const quoteWon = 'quote_won';
  static const subscriptionStarted = 'subscription_started';
  static const creditPackBought = 'credit_pack_bought';
  static const reviewSubmitted = 'review_submitted';
}

abstract interface class Analytics {
  Future<void> log(String event, [Map<String, Object>? params]);
  Future<void> setUser(String? userId, {String? mode});
  Future<void> setCollectionEnabled(bool enabled);
}

class FirebaseAnalyticsService implements Analytics {
  FirebaseAnalyticsService(this.country);
  final String country;
  FirebaseAnalytics get _fa => FirebaseAnalytics.instance;

  @override
  Future<void> log(String event, [Map<String, Object>? params]) =>
      _fa.logEvent(name: event, parameters: {'country': country, ...?params});

  @override
  Future<void> setUser(String? userId, {String? mode}) async {
    await _fa.setUserId(id: userId);
    if (mode != null) await _fa.setUserProperty(name: 'mode', value: mode);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) => _fa.setAnalyticsCollectionEnabled(enabled);
}

/// Used in demo mode, tests, and before Firebase is configured.
class DebugAnalytics implements Analytics {
  final events = <String>[];

  @override
  Future<void> log(String event, [Map<String, Object>? params]) async {
    events.add(event);
    if (kDebugMode) debugPrint('[analytics] $event ${params ?? {}}');
  }

  @override
  Future<void> setUser(String? userId, {String? mode}) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

@Riverpod(keepAlive: true)
Analytics analytics(Ref ref) {
  final env = ref.watch(appEnvProvider);
  final config = ref.watch(countryConfigProvider);
  return env.firebaseEnabled ? FirebaseAnalyticsService(config.countryCode) : DebugAnalytics();
}
