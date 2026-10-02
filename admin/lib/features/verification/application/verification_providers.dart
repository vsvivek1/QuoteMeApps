import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/verification_models.dart';

part 'verification_providers.g.dart';

@riverpod
Future<List<VerificationItem>> verificationQueue(Ref ref) => ref.watch(verificationRepositoryProvider).pending();
