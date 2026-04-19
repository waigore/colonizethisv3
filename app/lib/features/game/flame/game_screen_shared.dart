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
const Key kEmpireCivilianUnitsButtonKey = Key('empire_rail_civilian_units');
const Key kEmpireMilitaryUnitsButtonKey = Key('empire_rail_military_units');
const Key kEmpireNavalUnitsButtonKey = Key('empire_rail_naval_units');
const Key kEmpireDiplomacyButtonKey = Key('empire_rail_diplomacy');
const Key kEmpireTechnologyButtonKey = Key('empire_rail_technology');

/// Key for the cargo hold indicator row item. SPEC/ui/empire-overview.md.
const Key kCargoHoldIndicatorKey = Key('cargo_hold_indicator');

/// Key for the treasury indicator row item. SPEC/ui/empire-overview.md.
const Key kTreasuryIndicatorKey = Key('treasury_indicator');

/// Key for the in-map Next turn control (integration / widget tests).
const Key kGameMapNextTurnButtonKey = Key('game_map_next_turn_button');

/// Key for the region minimap globe toggle. SPEC/ui/empire-overview.md § Region minimap.
const Key kRegionMinimapToggleKey = Key('region_minimap_toggle');

/// Key for the region minimap hit target (map area). SPEC/ui/empire-overview.md § Region minimap.
const Key kRegionMinimapGestureKey = Key('region_minimap_gesture');

/// Key for the region minimap [CustomPaint]. SPEC/ui/empire-overview.md § Region minimap.
const Key kRegionMinimapCustomPaintKey = Key('region_minimap_custom_paint');

/// Key for the region minimap zoom slider. SPEC/ui/empire-overview.md § Region minimap.
const Key kRegionMinimapZoomSliderKey = Key('region_minimap_zoom_slider');
