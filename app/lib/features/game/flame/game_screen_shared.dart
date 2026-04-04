import 'package:flutter/material.dart';

/// Breakpoint for in-game narrow layout (side menu, reduced top bar). SPEC/ui/in-game-shell-narrow.md.
const double kInGameNarrowBreakpoint = 600;

/// Key for the base layer cycle button (for tests). SPEC/ui/empire-overview.md § Base layer display cycle.
const Key kBaseLayerCycleButtonKey = Key('base_layer_cycle_button');

/// Key for the home-to-capital button (for tests). SPEC/ui/empire-overview.md § Home-to-capital button.
const Key kHomeToCapitalButtonKey = Key('home_to_capital_button');

/// Key for the map display options button (for tests). SPEC/ui/empire-overview.md § Map display options button and dialog.
const Key kMapDisplayOptionsButtonKey = Key('map_display_options_button');

/// Key for the cargo hold indicator row item. SPEC/ui/empire-overview.md.
const Key kCargoHoldIndicatorKey = Key('cargo_hold_indicator');

/// Key for the region minimap globe toggle. SPEC/ui/empire-overview.md § Region minimap.
const Key kRegionMinimapToggleKey = Key('region_minimap_toggle');

/// Key for the region minimap hit target (map area). SPEC/ui/empire-overview.md § Region minimap.
const Key kRegionMinimapGestureKey = Key('region_minimap_gesture');

/// Key for the region minimap [CustomPaint]. SPEC/ui/empire-overview.md § Region minimap.
const Key kRegionMinimapCustomPaintKey = Key('region_minimap_custom_paint');
