import 'package:colonizethis_app/core/utils/state_toggle_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while isolate turn resolution is active from the map or Flame canvas
/// game screen (#2160, Refs #2277).
/// [AppEventHandler] and shell session listeners consume this flag to suppress
/// disallowed navigation/panels/commands; only pause-menu opens remain allowed at
/// handler level unless otherwise documented in SPEC/program/app-event-bus.md.
///
/// Backed by the shared [StateToggleNotifier]; use `.set(bool)` to flip the
/// blocking flag (default false).
///
/// Cross-cutting cleanup that needs to flip this flag off even when the
/// originating widget has disposed lives in
/// `core/services/turn_resolution_blocking_service.dart`
/// (`clearTurnResolutionBlockingFlag`); the navigator-key choke point belongs
/// in `core/services/` per `SPEC/program/app-ui-wiring.md`.
final turnResolutionBlockingProvider =
    NotifierProvider<StateToggleNotifier, bool>(
      () => StateToggleNotifier(false),
    );
