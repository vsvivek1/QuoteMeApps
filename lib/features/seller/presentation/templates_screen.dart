import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../application/seller_providers.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final templates = ref.watch(quoteTemplatesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.templatesTitle)),
      body: AsyncView(
        value: templates,
        data: (list) => list.isEmpty
            ? EmptyState(icon: Icons.bookmarks_outlined, message: l10n.templatesEmpty)
            : ListView(
                children: [
                  for (final t in list)
                    ListTile(
                      leading: const Icon(Icons.bookmark_outline),
                      title: Text(t.name),
                      subtitle: Text('${(t.payload['lines'] as List?)?.length ?? 0} × ${l10n.quoteItem}'),
                      trailing: IconButton(
                        tooltip: l10n.delete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref.read(sellerRepositoryProvider).deleteTemplate(t.id);
                          ref.invalidate(quoteTemplatesProvider);
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
