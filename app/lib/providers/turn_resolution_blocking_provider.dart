import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart' show appNavigatorKey;

/// True while isolate turn resolution is active from the map or Flame canvas
/// game screen (#2160, Refs #2277).
/// [AppEventHandler] and shell session listeners consume this flag to suppress
/// disallowed navigation/panels/commands; only pause-menu opens remain allowed at
/// handler level unless otherwise documented in SPEC/program/app-event-bus.md.
class TurnResolutionBlockingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setBlocking(bool value) => state = value;
}

final turnResolutionBlockingProvider =
    NotifierProvider<TurnResolutionBlockingNotifier, bool>(
      TurnResolutionBlockingNotifier.new,
    );

/// Clears blocking using the root navigator context (survives [GameMapArea] dispose during async completion).
bool clearTurnResolutionBlockingFlag() {
  final ctx = appNavigatorKey.currentContext;
  if (ctx == null) return false;
  try {
    ProviderScope.containerOf(
      ctx,
      listen: false,
    ).read(turnResolutionBlockingProvider.notifier).setBlocking(false);
    return true;
  } catch (_) {
    return false;
  }
}
