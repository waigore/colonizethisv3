import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart' show appNavigatorKey;
import '../../providers/turn_resolution_blocking_provider.dart';

/// Clears [turnResolutionBlockingProvider] via the root navigator context so
/// the flag flips off even when the originating widget (for example
/// `GameMapArea`) has disposed during async completion (#2160, Refs #2277).
///
/// Lives in `core/services/` per `SPEC/program/app-ui-wiring.md`: only
/// `app/lib/core/services/` and `app/lib/app.dart` may access
/// `appNavigatorKey` directly — all other layers must thread a navigator key
/// explicitly or use the bus.
bool clearTurnResolutionBlockingFlag() {
  final ctx = appNavigatorKey.currentContext;
  if (ctx == null) return false;
  try {
    ProviderScope.containerOf(
      ctx,
      listen: false,
    ).read(turnResolutionBlockingProvider.notifier).set(false);
    return true;
  } catch (_) {
    return false;
  }
}
