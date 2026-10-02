import 'package:flutter/material.dart';

import '../../../core/utils/context_x.dart';
import '../domain/category.dart';
import 'widgets.dart';

/// Two-level category picker in a bottom sheet. Blocked categories are shown
/// disabled so buyers learn what isn't allowed.
Future<Category?> showCategoryPicker(
  BuildContext context,
  List<Category> all, {
  bool allowBlocked = false,
  Set<int> selected = const {},
}) {
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, scroll) {
        final parents = all.where((c) => c.parentId == null).toList()..sort((a, b) => a.sort.compareTo(b.sort));
        return ListView(
          controller: scroll,
          children: [
            for (final p in parents)
              ExpansionTile(
                leading: Icon(categoryIcon(p.icon)),
                title: Text(p.name(ctx.lang)),
                children: [
                  for (final c in all.where((c) => c.parentId == p.id))
                    ListTile(
                      enabled: allowBlocked || !c.isBlocked,
                      title: Text(c.name(ctx.lang)),
                      trailing: c.isBlocked
                          ? const Icon(Icons.block_rounded, size: 18)
                          : c.isRestricted
                          ? const Icon(Icons.verified_user_outlined, size: 18)
                          : selected.contains(c.id)
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () => Navigator.pop(ctx, c),
                    ),
                ],
              ),
          ],
        );
      },
    ),
  );
}
