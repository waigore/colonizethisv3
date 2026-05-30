import 'package:flutter/material.dart';

/// Key for the base layer cycle button (for tests). SPEC/ui/empire-overview.md § Base layer display cycle.
const Key kBaseLayerCycleButtonKey = Key('base_layer_cycle_button');

/// Key for the home-to-capital button (for tests). SPEC/ui/empire-overview.md § Home-to-capital button.
const Key kHomeToCapitalButtonKey = Key('home_to_capital_button');

/// Key for the map display options button (for tests). SPEC/ui/empire-overview.md § Map display options button and dialog.
const Key kMapDisplayOptionsButtonKey = Key('map_display_options_button');

/// Inset from map stack left/bottom for overlay controls (matches former top-left placement).
const double kMapOverlayEdgeInset = 0;

/// Width of left-edge swipe target to open the debug side menu; empire rail starts to the right.
const double kEdgeSwipeStripWidth = 20;

/// Keys for empire left-rail icon buttons (tests). SPEC/ui/empire-overview.md, empire-buttons.md.
const Key kEmpireProductionButtonKey = Key('empire_rail_production');
const Key kEmpireTradeButtonKey = Key('empire_rail_trade');
const Key kEmpireCivilianUnitsButtonKey = Key('empire_rail_civilian_units');
const Key kEmpireMilitaryUnitsButtonKey = Key('empire_rail_military_units');
const Key kEmpireNavalUnitsButtonKey = Key('empire_rail_naval_units');
const Key kEmpireDiplomacyButtonKey = Key('empire_rail_diplomacy');
const Key kEmpireTechnologyButtonKey = Key('empire_rail_technology');
const Key kEmpireDebugConsoleButtonKey = Key('empire_rail_debug_console');

/// Key for the cargo hold indicator row item. SPEC/ui/empire-overview.md.
const Key kCargoHoldIndicatorKey = Key('cargo_hold_indicator');

/// Key for the treasury indicator row item. SPEC/ui/empire-overview.md.
const Key kTreasuryIndicatorKey = Key('treasury_indicator');

/// Key for the in-map Next turn control (integration / widget tests).
const Key kGameMapNextTurnButtonKey = Key('game_map_next_turn_button');

/// Disabled-state [Opacity] value for the in-game Next turn button (issue
/// #2861 R1 / AC#9). Mockup source of truth: `.next-turn.disabled
/// { opacity: 0.35 }` in `SPEC/ui/mockups/GAME10001-game-screen.html`.
/// Overrides the catalog-default `CtNinePatchButton.disabledOpacity`
/// (`0.4`) per `SPEC/ui/game-screen.md` § Acceptance Criteria. Used by
/// both [GameTopBar] and the `GameScreen` fallback Flame-canvas Next-turn
/// button so the dimming reads consistently across both shells.
const double kNextTurnDisabledOpacity = 0.35;

/// Key for the player turn event feed toggle (widget / integration tests).
/// SPEC/ui/player-turn-event-feed.md.
const Key kPlayerTurnFeedToggleButtonKey = Key(
  'player-turn-feed-toggle-button',
);

/// Right gutter (logical px) from the map stack viewport edge for wide-layout overlays that hug the map column (minimap, feed card). SPEC/ui/player-turn-event-feed.md.
const double kGameMapWideStackRightGutter = 8;

/// Province / sea zone detail side panel width on wide layout (logical px).
/// SPEC/ui/in-game-shell-narrow.md; parity with [GameMapProvinceDetailSidePanel].
const double kGameMapWideProvinceSidePanelWidth = 320;

/// Combined `Positioned.right` inset so overlays clear the 320 dp wide province column when open.
/// LTR-only for this workstream. SPEC/ui/player-turn-event-feed.md.
double gameMapWideOverlayRightInset({required bool provincePanelOpen}) =>
    kGameMapWideStackRightGutter +
    (provincePanelOpen ? kGameMapWideProvinceSidePanelWidth : 0);

/// Key for the region minimap globe toggle. SPEC/ui/empire-overview.md § Region minimap.
const Key kRegionMinimapToggleKey = Key('region_minimap_toggle');

/// Key for the region minimap hit target (map area). SPEC/ui/empire-overview.md § Region minimap.
const Key kRegionMinimapGestureKey = Key('region_minimap_gesture');

/// Key for the region minimap [CustomPaint]. SPEC/ui/empire-overview.md § Region minimap.
const Key kRegionMinimapCustomPaintKey = Key('region_minimap_custom_paint');

/// Key for the region minimap zoom slider. SPEC/ui/empire-overview.md § Region minimap.
const Key kRegionMinimapZoomSliderKey = Key('region_minimap_zoom_slider');

/// Key for the floating players bar widget (top-right of the wide map stack).
/// SPEC/ui/empire-overview.md § Players bar.
const Key kGameMapPlayersBarKey = Key('game_map_players_bar');

/// Test/integration key prefix for a single player chip row inside the players bar.
/// Concatenate with the `Player.id` to obtain a stable per-row key:
///   `Key('${kGameMapPlayerChipKeyPrefix}${player.id}')`.
/// SPEC/ui/empire-overview.md § Players bar.
const String kGameMapPlayerChipKeyPrefix = 'game_map_player_chip:';
