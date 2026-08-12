/// UI action event base type (Refs #4136 Slice B; partition Refs #4334 wave 3).

import '../app_events.dart';

// ---------------------------------------------------------------------------
// UIActionEvent — emitted by UI components that need other UI components to act.
// ---------------------------------------------------------------------------

/// Cross-file subclasses require `abstract` (not `sealed`) per first-class library
/// partition policy (`SPEC/program/models-no-part-directives.md`).
abstract class UIActionEvent extends AppEvent {
  const UIActionEvent();
}
