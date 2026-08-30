// App events: typed event bus for UI↔UI, UI↔game logic, game logic→UI.
// Coupling / wiring rules: SPEC/program/app-ui-wiring.md. Bus architecture: SPEC/program/app-event-bus.md.
//
// Three event domains:
//  1. GameEvent    — game occurrences from colonizethis_logic (consumed, not defined here)
//  2. UIActionEvent — UI components requesting actions (dialogs, navigation, panels)
//  3. UISystemEvent — system-level UI feedback (snackbars, overlays, toasts)
//
// Note: GameEvent lives in colonizethis_logic to avoid circular deps.
// DialogueEvent and PortraitMoodEvent live here in colonizethis_models.
//
// Panel requests: prefer typed subclasses below (SPEC/program/app-ui-wiring.md).
// [OpenPanelEvent] remains for legacy string-id panels until migrated.
//
// Concrete event types live under `app_events/` as first-class libraries
// (Refs #4068 Slice C; wave-3 partitions Refs #4334): `ui_action_events.dart`
// barrel (UIActionEvent + domain partitions), `session_command_events.dart`
// barrel (SessionCommandEvent + domain partitions), `ui_system_events.dart`
// (UISystemEvent), and `game_to_ui_events.dart` barrel (GameToUIEvent +
// app-prefixed GameEvent mirror partitions).


export 'ai_events.dart' show DialogueEvent, PortraitMoodEvent;

export 'app_events/game_to_ui_events.dart';
export 'app_events/session_command_events.dart';
export 'app_events/ui_action_events.dart';
export 'app_events/ui_system_events.dart';


abstract class AppEvent {
  const AppEvent();
}
