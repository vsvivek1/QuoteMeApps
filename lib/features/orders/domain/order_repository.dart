import '../../../core/money/money.dart';
import 'order.dart';

abstract interface class OrderRepository {
  Stream<List<Order>> watchMyOrders();
  Stream<Order?> watchOrder(String id);
  Future<void> updateStatus(String orderId, OrderStatus status, {String? note});
  Future<void> recordPayment(String orderId, String method, Money amount);
}
