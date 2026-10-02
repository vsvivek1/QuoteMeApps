import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/category_models.dart';

part 'category_providers.g.dart';

@Riverpod(keepAlive: true)
Future<List<AdminCategory>> adminCategories(Ref ref) => ref.watch(categoryAdminRepositoryProvider).list();

/// id -> category, for labels in other screens.
@Riverpod(keepAlive: true)
Future<Map<int, AdminCategory>> categoryIndex(Ref ref) async =>
    {for (final c in await ref.watch(adminCategoriesProvider.future)) c.id: c};
