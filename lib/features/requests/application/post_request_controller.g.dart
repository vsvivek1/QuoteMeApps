// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_request_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PostRequestController)
final postRequestControllerProvider = PostRequestControllerProvider._();

final class PostRequestControllerProvider
    extends $NotifierProvider<PostRequestController, PostRequestState> {
  PostRequestControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postRequestControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postRequestControllerHash();

  @$internal
  @override
  PostRequestController create() => PostRequestController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostRequestState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostRequestState>(value),
    );
  }
}

String _$postRequestControllerHash() =>
    r'bb8f2005c7f9bfc30d2524292ff6c4ea7b3eed7e';

abstract class _$PostRequestController extends $Notifier<PostRequestState> {
  PostRequestState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PostRequestState, PostRequestState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PostRequestState, PostRequestState>,
              PostRequestState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
