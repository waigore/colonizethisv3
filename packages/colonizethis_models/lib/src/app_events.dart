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
// Concrete event types are split across `app_events/` part files by event
// category: `ui_action_events.dart` (UIActionEvent), `session_command_events.dart`
// (SessionCommandEvent), `ui_system_events.dart` (UISystemEvent), and
// `game_to_ui_events.dart` (GameToUIEvent + app-prefixed GameEvent mirrors).

import 'combat_mode.dart';
import 'diplomacy.dart';
import 'game.dart';
import 'turn_news_digest.dart';
import 'orders.dart';

export 'ai_events.dart' show DialogueEvent, PortraitMoodEvent;

part 'app_events/ui_action_events.dart';
part 'app_events/session_command_events.dart';
part 'app_events/ui_system_events.dart';
part 'app_events/game_to_ui_events.dart';

abstract class AppEvent {
  const AppEvent();
}
