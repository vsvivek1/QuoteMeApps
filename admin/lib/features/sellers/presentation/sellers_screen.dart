import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/router.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/widgets/async_view.dart';
import '../application/seller_providers.dart';
import '../domain/seller_models.dart';

/// Find a seller by business name or phone, then open the seller detail.
class SellersScreen extends ConsumerStatefulWidget {
  const SellersScreen({super.key});

  @override
  ConsumerState<SellersScreen> createState() => _SellersScreenState();
}

class _SellersScreenState extends ConsumerState<SellersScreen> {
  late final _ctrl = TextEditingController(text: ref.read(sellerQueryProvider));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search() => ref.read(sellerQueryProvider.notifier).set(_ctrl.text);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final query = ref.watch(sellerQueryProvider);
    final results = ref.watch(sellerSearchProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.navSellers)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l.sellersSearchHint,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: l.refresh,
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(sellerSearchProvider),
            ),
          ]),
        ),
        Expanded(
          child: query.isEmpty
              ? EmptyState(l.sellersSearchPrompt, icon: Icons.storefront_outlined)
              : AsyncView(
                  value: results,
                  onRetry: () => ref.invalidate(sellerSearchProvider),
                  builder: (list) => list.isEmpty
                      ? EmptyState(l.sellersNone)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) => _SellerTile(list[i]),
                        ),
                ),
        ),
      ]),
    );
  }
}

class _SellerTile extends StatelessWidget {
  const _SellerTile(this.seller);
  final SellerSummary seller;

  @override
  Widget build(BuildContext context) {
    final s = seller;
    final place = [s.city, s.state].whereType<String>().join(', ');
    return ListTile(
      leading: const Icon(Icons.storefront_outlined),
      title: Text(s.businessName),
      subtitle: Text([
        if (s.ownerName != null) s.ownerName!,
        if (s.phone != null) s.phone!,
        if (place.isNotEmpty) place,
        s.verificationStatus,
      ].join(' · ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(Routes.seller(s.id)),
    );
  }
}
