/// Session command event base type (Refs #4136 Slice B).

import '../app_events.dart';

// ---------------------------------------------------------------------------
// SessionCommandEvent — applied by long-lived shell listeners, not AppEventHandler.
// ---------------------------------------------------------------------------

/// Session-scoped commands: listeners use a stable [ProviderScope] ref (e.g.
/// [AppEventHandlerScope]). **Do not** capture [WidgetRef] from widgets that
/// unmount when opening panels (side menus, sheets). SPEC/program/app-event-bus.md.
abstract class SessionCommandEvent extends AppEvent {
  const SessionCommandEvent();
}
