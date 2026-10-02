import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../state/app_state.dart';

/// Resolves `https://<domain>/r/<id>`: the buyer who owns the request sees
/// its quotes; anyone else in seller mode sees it as a lead.
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
    } else if (ref.read(myProfileProvider).value?.isSeller ?? false) {
      context.go('/seller/leads/${widget.requestId}');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
