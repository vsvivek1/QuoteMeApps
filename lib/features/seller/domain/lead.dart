import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/money/money.dart';
import '../../requests/domain/buyer_request.dart';

part 'lead.freezed.dart';

/// An open request as a seller sees it in the lead feed. Never contains the
/// buyer's contact details or exact address (only locality).
@freezed
abstract class Lead with _$Lead {
  const factory Lead({
    required String requestId,
    required int categoryId,
    required String title,
    @Default('') String description,
    @Default({}) Map<String, Object?> fields,
    Money? budgetMin,
    Money? budgetMax,
    DateTime? neededBy,
    String? locality,
    String? locationCode,
    String? state,
    double? distanceKm,
    @Default(Audience.both) Audience audience,
    @Default(0) int quoteCount,
    @Default(10) int maxQuotes,
    DateTime? quoteWindowEndsAt,
    required DateTime createdAt,
    @Default([]) List<RequestMedia> media,
    @Default(false) bool seen,
    @Default(false) bool alreadyQuoted,
    String? buyerFirstName,
  }) = _Lead;

  const Lead._();

  bool get isFull => quoteCount >= maxQuotes;
}

@freezed
abstract class LeadFilters with _$LeadFilters {
  const factory LeadFilters({
    int? categoryId,
    int? maxDistanceKm,
    Money? minBudget,
    DateTime? neededBefore,
  }) = _LeadFilters;
}

@freezed
abstract class LeadPage with _$LeadPage {
  const factory LeadPage({
    required List<Lead> leads,
    String? nextCursor,
  }) = _LeadPage;
}
