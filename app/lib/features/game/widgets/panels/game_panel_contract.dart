// Shared game-panel contract (Refs #3279 target state #2).
//
// The human-facing game panels that orchestrate a player's orders all carry
// the same four inputs: the current [Game], the acting [humanPlayerId], the
// [AppEventBus] used for cross-panel coordination, and a [readOnly] flag that
// disables mutation in observe mode. Before this contract each panel declared
// those fields independently with no shared type, so generic helpers and tests
// could not refer to "a game-bearing panel" without enumerating concrete
// classes.
//
// [GamePanelMixin] is the shared marker: it mandates the four getters (the
// panels already expose them as `final` fields, so mixing it in adds no
// per-panel field code) and exposes a single [GamePanelConfig] bundle so
// callers can pass the shared inputs as one value.
//
// `screenId` is intentionally *not* part of this mixin: it stays a
// `static const` on each panel (grep-able and traceable to
// `SPEC/ui/screen-registry.md`, enforced by `repo.app_panel_screen_id`), and a
// `static const screenId` cannot coexist with an instance getter of the same
// name on one class.
//
// Panels that do not carry the full set are out of scope: `ProductionPanel`
// and `TechnologyPanel` take a `Player` but no `bus`/`readOnly`, and
// `PauseMenuPanel` / `ObserveModeNotDefinedPanel` take no `game`.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/widgets.dart';

/// Immutable bundle of the inputs shared by every game-bearing panel.
///
/// Built on demand by [GamePanelMixin.gamePanelConfig] from the panel's own
/// fields, so it always reflects the live widget configuration.
class GamePanelConfig {
  const GamePanelConfig({
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    this.readOnly = false,
  });

  /// Current game state the panel renders and mutates orders against.
  final Game game;

  /// Acting player whose units/orders the panel manages.
  final String humanPlayerId;

  /// Event bus for cross-panel / cross-screen coordination
  /// (`SPEC/program/app-ui-wiring.md`).
  final AppEventBus bus;

  /// When true the panel renders without mutation affordances (observe mode).
  final bool readOnly;
}

/// Shared contract for the game-bearing player panels
/// (`CivilianUnitsPanel`, `MilitaryUnitsPanel`, `NavalUnitsPanel`,
/// `DiplomacyPanel`).
///
/// Implementing panels expose the four shared inputs via their existing
/// `final` fields; the mixin only adds the [gamePanelConfig] bundle. Enforced
/// by `repo.app_game_panel_mixin` (`SPEC/program/repo-lint.md`).
mixin GamePanelMixin on Widget {
  /// Current game state.
  Game get game;

  /// Acting player id.
  String get humanPlayerId;

  /// Cross-panel event bus.
  AppEventBus get bus;

  /// Observe-mode read-only flag.
  bool get readOnly;

  /// The shared inputs bundled as one immutable value.
  GamePanelConfig get gamePanelConfig => GamePanelConfig(
    game: game,
    humanPlayerId: humanPlayerId,
    bus: bus,
    readOnly: readOnly,
  );
}
