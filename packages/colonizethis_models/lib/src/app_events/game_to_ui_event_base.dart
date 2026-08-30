/// Game-to-UI event base type (Refs #4334 wave 3).

import '../app_events.dart';

// ---------------------------------------------------------------------------
// GameToUIEvent — bridge from services when game state changes.
// ---------------------------------------------------------------------------

/// Cross-file subclasses require `abstract` (not `sealed`) per first-class library
/// partition policy (`SPEC/program/models-no-part-directives.md`).
abstract class GameToUIEvent extends AppEvent {
  const GameToUIEvent();
}
