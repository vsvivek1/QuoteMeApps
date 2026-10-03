import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/app_user.dart';
import '../providers.dart';
import '../state/app_state.dart';

/// Resolves `https://<domain>/r/<id>`: the buyer who owns the request sees
/// its quotes; anyone in seller mode sees it as a lead; a buyer sees the
/// community post when the request is on the feed.
class DeepLinkScreen extends ConsumerStatefulWidget {
  const DeepLinkScreen.request(this.requestId, {super.key});
  final String requestId;

  @override
  ConsumerState<DeepLinkScreen> createState() => _DeepLinkScreenState();
}

class _DeepLinkScreenState extends ConsumerState<DeepLinkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final me = ref.read(authSessionProvider).value?.userId;
    final request = await ref.read(requestRepositoryProvider).watchRequest(widget.requestId).first;
    if (!mounted) return;
    if (request != null && request.buyerId == me) {
      context.go('/requests/${widget.requestId}');
    } else if (ref.read(appModeProvider) == AppMode.seller) {
      context.go('/seller/leads/${widget.requestId}');
    } else if (await ref.read(communityRepositoryProvider).watchPost(widget.requestId).first != null) {
      if (mounted) context.go('/feed/${widget.requestId}');
    } else if (ref.read(myProfileProvider).value?.isSeller ?? false) {
      if (mounted) context.go('/seller/leads/${widget.requestId}');
    } else {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
