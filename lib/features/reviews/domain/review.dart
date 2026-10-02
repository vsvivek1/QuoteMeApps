import 'package:freezed_annotation/freezed_annotation.dart';

part 'review.freezed.dart';

@freezed
abstract class Review with _$Review {
  const factory Review({
    required String id,
    required String orderId,
    required String fromId,
    required String toId,
    required String role,
    required int stars,
    @Default([]) List<String> tags,
    @Default('') String text,
    @Default([]) List<String> photos,
    String? sellerReply,
    String? authorName,
    required DateTime createdAt,
  }) = _Review;
}
