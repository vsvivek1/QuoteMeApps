import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../application/request_providers.dart';
import '../domain/buyer_request.dart';
import '../domain/category.dart';

String requestStatusLabel(BuildContext context, RequestStatus s) => switch (s) {
      RequestStatus.open => context.l10n.statusOpen,
      RequestStatus.awarded => context.l10n.statusAwarded,
      RequestStatus.closed => context.l10n.statusClosed,
      RequestStatus.expired => context.l10n.statusExpired,
      RequestStatus.cancelled => context.l10n.statusCancelled,
    };

Color requestStatusColor(BuildContext context, RequestStatus s) => switch (s) {
      RequestStatus.open => context.colors.primary,
      RequestStatus.awarded => Colors.green.shade700,
      _ => context.colors.outline,
    };

IconData categoryIcon(String? name) => switch (name) {
      'kitchen' => Icons.kitchen_rounded,
      'devices' => Icons.devices_rounded,
      'chair' => Icons.chair_rounded,
      'home_repair_service' => Icons.home_repair_service_rounded,
      'directions_car' => Icons.directions_car_rounded,
      'celebration' => Icons.celebration_rounded,
      'inventory_2' => Icons.inventory_2_rounded,
      'gavel' => Icons.gavel_rounded,
      _ => Icons.category_rounded,
    };

class RequestCard extends ConsumerWidget {
  const RequestCard({super.key, required this.request});
  final BuyerRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoryMapProvider).value ?? const <int, Category>{};
    final cat = cats[request.categoryId];
    final parent = cat?.parentId == null ? null : cats[cat!.parentId];
    final l10n = context.l10n;
    final ends = request.quoteWindowEndsAt;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/requests/${request.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: context.colors.primaryContainer,
                child: Icon(categoryIcon(parent?.icon ?? cat?.icon), color: context.colors.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (cat != null) cat.name(context.lang),
                        if (request.isOpen && ends != null && ends.isAfter(DateTime.now()))
                          l10n.closesIn(context.shortDuration(ends.difference(DateTime.now()))),
                      ].join(' · '),
                      style: context.text.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusChip(requestStatusLabel(context, request.status),
                            color: requestStatusColor(context, request.status)),
                        const SizedBox(width: 8),
                        Text(l10n.quotesCount(request.quoteCount), style: context.text.labelLarge),
                        if (request.unreadQuotes > 0) ...[
                          const SizedBox(width: 6),
                          Badge(label: Text('${request.unreadQuotes}')),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
