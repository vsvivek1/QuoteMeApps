import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../domain/buyer_request.dart';
import '../domain/category.dart';
import '../domain/request_repository.dart';

part 'post_request_controller.g.dart';

class PostRequestState {
  const PostRequestState({
    this.draft = const RequestDraft(),
    this.step = 0,
    this.suggestions = const [],
    this.blocked,
    this.submitting = false,
    this.error,
    this.created,
  });

  final RequestDraft draft;
  final int step;
  final List<Category> suggestions;

  /// Set when the text matches a blocked category.
  final Category? blocked;
  final bool submitting;

  /// RequestFailure code.
  final String? error;
  final BuyerRequest? created;

  PostRequestState copyWith({
    RequestDraft? draft,
    int? step,
    List<Category>? suggestions,
    Category? Function()? blocked,
    bool? submitting,
    String? Function()? error,
    BuyerRequest? created,
  }) =>
      PostRequestState(
        draft: draft ?? this.draft,
        step: step ?? this.step,
        suggestions: suggestions ?? this.suggestions,
        blocked: blocked == null ? this.blocked : blocked(),
        submitting: submitting ?? this.submitting,
        error: error == null ? this.error : error(),
        created: created ?? this.created,
      );
}

@riverpod
class PostRequestController extends _$PostRequestController {
  @override
  PostRequestState build() {
    ref.read(analyticsProvider).log(AnalyticsEvent.requestStarted);
    return const PostRequestState();
  }

  void init({String? text, int? categoryId}) {
    state = state.copyWith(draft: state.draft.copyWith(text: text ?? '', categoryId: categoryId));
    if (text != null && text.isNotEmpty) onTextChanged(text);
  }

  Future<void> onTextChanged(String text) async {
    state = state.copyWith(draft: state.draft.copyWith(text: text));
    final repo = ref.read(categoryRepositoryProvider);
    final blocked = await repo.blockedMatch(text);
    final suggestions = await repo.suggest(text);
    if (state.draft.text != text) return; // stale
    state = state.copyWith(
      suggestions: suggestions,
      blocked: () => blocked,
      draft: state.draft.categoryId == null && suggestions.isNotEmpty && blocked == null
          ? state.draft.copyWith(categoryId: suggestions.first.id)
          : null,
    );
  }

  void setCategory(Category c) => state = state.copyWith(
        draft: state.draft.copyWith(categoryId: c.id, fields: const {}),
        blocked: () => c.isBlocked ? c : null,
      );

  void setField(String key, Object? value) {
    final fields = {...state.draft.fields};
    if (value == null || value == '') {
      fields.remove(key);
    } else {
      fields[key] = value;
    }
    state = state.copyWith(draft: state.draft.copyWith(fields: fields));
  }

  void update(RequestDraft Function(RequestDraft d) f) => state = state.copyWith(draft: f(state.draft));

  void addMedia(List<String> paths) {
    final all = [...state.draft.localMediaPaths, ...paths].take(6).toList();
    state = state.copyWith(draft: state.draft.copyWith(localMediaPaths: all));
  }

  void removeMedia(String path) => state = state.copyWith(
      draft: state.draft.copyWith(
          localMediaPaths: state.draft.localMediaPaths.where((p) => p != path).toList()));

  void setBudget(Money? min, Money? max) =>
      state = state.copyWith(draft: state.draft.copyWith(budgetMin: min, budgetMax: max));

  void goTo(int step) => state = state.copyWith(step: step, error: () => null);

  Future<BuyerRequest?> submit() async {
    state = state.copyWith(submitting: true, error: () => null);
    try {
      final created = await ref.read(requestRepositoryProvider).createRequest(state.draft);
      await ref.read(analyticsProvider).log(AnalyticsEvent.requestPosted, {
        'category_id': created.categoryId,
        'photos': state.draft.localMediaPaths.length,
      });
      state = state.copyWith(submitting: false, created: created);
      return created;
    } on RequestFailure catch (e) {
      state = state.copyWith(submitting: false, error: () => e.code);
    } catch (_) {
      state = state.copyWith(submitting: false, error: () => 'network');
    }
    return null;
  }
}
