// Canonical observe-mode guard for player-scoped game surfaces (Refs #3546
// target state #1).
//
// The full-screen feature bodies (trade / technology / production / diplomacy)
// and the military/naval unit-panel sheets all repeated the same guard: when the
// shell has no defined player chrome (global observe), render an
// [ObserveModeNotDefinedPanel] titled for the surface; otherwise render the
// real player-scoped body. Each call site duplicated that branch and the panel
// construction. This helper is the single source for that decision and is used
// as a guard clause at every site.

import 'package:flutter/widgets.dart';

import '../shell_player_context.dart';
import 'observe_mode_not_defined_panel.dart';

/// Returns the global-observe sentinel panel when [shell] hides player chrome
/// ([shellPanelsNotDefined] is true), or `null` when player-scoped content
/// should render.
///
/// Use it as a guard clause so the observe branch lives in one place while the
/// caller keeps its own body and reads mutation state from [shell] directly:
///
/// ```dart
/// final shell = shellRef.read(shellPlayerContextProvider);
/// final sentinel = observeNotDefinedSentinel(shell, 'Trade');
/// if (sentinel != null) return sentinel;
/// final canEdit = shell.canMutateViaUi;
/// // ... build the player-scoped body ...
/// ```
Widget? observeNotDefinedSentinel(ShellPlayerContext shell, String title) {
  if (shellPanelsNotDefined(shell)) {
    return ObserveModeNotDefinedPanel(title: title);
  }
  return null;
}
