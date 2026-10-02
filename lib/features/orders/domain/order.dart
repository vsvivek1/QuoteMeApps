import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/money/money.dart';

part 'order.freezed.dart';

enum OrderStatus { accepted, scheduled, dispatched, delivered, completed, cancelled }

@freezed
abstract class OrderEvent with _$OrderEvent {
  const factory OrderEvent({required OrderStatus status, required DateTime at, String? note}) = _OrderEvent;
}

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    required String requestId,
    required String quoteId,
    required String buyerId,
    required String sellerId,
    required String title,
    required String sellerName,
    String? buyerName,
    String? sellerPhone,
    String? buyerPhone,
    String? fullAddress,
    required Money total,
    @Default(OrderStatus.accepted) OrderStatus status,
    String? paymentMethod,
    Money? paymentAmount,
    DateTime? paymentRecordedAt,
    @Default([]) List<OrderEvent> events,
    required DateTime createdAt,
    @Default(false) bool buyerReviewed,
    @Default(false) bool sellerReviewed,
  }) = _Order;

  const Order._();

  bool get isCompleted => status == OrderStatus.completed || status == OrderStatus.delivered;
}
