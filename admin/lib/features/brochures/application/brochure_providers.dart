import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/brochure_models.dart';

part 'brochure_providers.g.dart';

@riverpod
Future<List<BrochureRecord>> brochureList(Ref ref) => ref.watch(brochureRepositoryProvider).list();
