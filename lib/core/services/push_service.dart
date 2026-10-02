import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers.dart';
import '../routing/router.dart';
import '../state/app_state.dart';

part 'push_service.g.dart';

/// FCM: asks for permission (Android 13+ / iOS), stores the token in
/// `device_tokens` through the notification repository, and opens the
/// deep link carried in a tapped push (`data.route`).
@Riverpod(keepAlive: true)
Future<void> pushRegistration(Ref ref) async {
  final env = ref.watch(appEnvProvider);
  final session = ref.watch(authSessionProvider).value;
  if (!env.firebaseEnabled || session == null || kIsWeb) return;
  final fm = FirebaseMessaging.instance;
  final settings = await fm.requestPermission();
  if (settings.authorizationStatus == AuthorizationStatus.denied) return;
  final repo = ref.read(notificationRepositoryProvider);
  final platform = Platform.isIOS ? 'ios' : 'android';
  final token = await fm.getToken();
  if (token != null) await repo.registerDeviceToken(token, platform);
  final subs = <StreamSubscription<Object?>>[
    fm.onTokenRefresh.listen((t) => repo.registerDeviceToken(t, platform)),
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(ref, m)),
  ];
  ref.onDispose(() {
    for (final s in subs) {
      s.cancel();
    }
  });
  final initial = await fm.getInitialMessage();
  if (initial != null) _open(ref, initial);
}

void _open(Ref ref, RemoteMessage m) {
  final route = m.data['route'] as String?;
  if (route != null && route.startsWith('/')) ref.read(routerProvider).push(route);
}
