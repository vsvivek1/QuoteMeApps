import 'review.dart';

abstract interface class ReviewRepository {
  Future<void> submitReview({
    required String orderId,
    required int stars,
    List<String> tags,
    String text,
    List<String> photoPaths,
  });
  Future<List<Review>> reviewsFor(String userId);
  Future<void> reply(String reviewId, String text);
}
