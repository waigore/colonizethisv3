// Shared panel-navigation helper for the AppEventBus. Lives in `app/` because
// it depends on Flutter's `WidgetsBinding`. SPEC/program/app-ui-wiring.md
// (ClosePanelEvent → follow-up ordering), SPEC/program/app-event-bus.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/widgets.dart';

/// Panel-navigation convenience built on top of [AppEventBus].
///
/// Centralizes the "close the active handler-owned panel, then emit a
/// follow-up event after the current frame" idiom that game unit panels would
/// otherwise re-implement inline at every call site.
extension AppEventBusPanelNav on AppEventBus {
  /// Closes the active handler-owned panel, then emits [next] after the
  /// current frame completes.
  ///
  /// The post-frame deferral exists so the closing panel's
  /// `Navigator.maybePop` (driven by `AppEventHandler` handling
  /// [ClosePanelEvent]) finishes before the next surface mounts. Emitting
  /// [next] synchronously could mount the follow-up surface before the pop
  /// completes.
  ///
  /// Preserves the SPEC-normative ordering: [ClosePanelEvent] is emitted
  /// synchronously first, then [next] is emitted exactly once on the next
  /// frame (`SPEC/program/app-ui-wiring.md` § Acceptance Criteria).
  void closePanelThenEmit(AppEvent next) {
    emit(const ClosePanelEvent());
    WidgetsBinding.instance.addPostFrameCallback((_) => emit(next));
  }
}
