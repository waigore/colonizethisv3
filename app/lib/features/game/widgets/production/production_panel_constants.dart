part of 'production_panel.dart';

/// Public layout key planted on the narrow (`< [kNarrowBreakpoint]` dp) variant
/// of [ProductionPanel] so widget tests and Widgetbook pinning can confirm
/// that the screen has selected its `_ProductionPanelNarrowLayout` branch
/// (Available stacked above Allocation, scrollable container) at narrow
/// viewports.
///
/// SPEC: `SPEC/ui/production-panel.md` § States and variants — Narrow
/// (<600 dp). Refs #2870 R22 / S9 (Widgetbook mobile-viewport stories +
/// pinning tests for `< 600 dp` layouts).
const Key kProductionPanelNarrowLayoutKey = ValueKey<String>(
  'production_panel_narrow_layout',
);

/// Companion key for the wide (`≥ [kNarrowBreakpoint]` dp) layout branch so a
/// failing pin test surfaces the actual layout selected by [ProductionPanel]
/// (rather than a generic "key not found"). Mirrors
/// [kProductionPanelNarrowLayoutKey].
const Key kProductionPanelWideLayoutKey = ValueKey<String>(
  'production_panel_wide_layout',
);

/// Column count used by the Available subpanel commodity sections (Food, Raw
/// Materials, Manufactured) per `SPEC/ui/production-panel.md` § Layout —
/// Available subpanel "Commodity grid layout" (mockup `.grid-3col`, owner
/// decision **C7** / S8b for issue #2862). Applies on every viewport width.
const int kProductionAvailableCommodityGridColumns = 3;

/// Column count used by the Available subpanel Workers section per
/// `SPEC/ui/production-panel.md` § Layout — Available subpanel "Workers
/// section" (mockup `.grid-2col`, owner decision **C7** / S8b for issue
/// #2862). Applies on every viewport width.
const int kProductionAvailableWorkerGridColumns = 2;

/// Key string planted on the Workers grid container so widget tests can
/// assert the 2-column worker layout (Refs #2862 S8b).
const String kProductionAvailableWorkerGridKeyValue =
    'production_available_worker_grid';

/// Stable widget key for the Workers grid container; tests can locate the
/// grid via this key without crawling the section ancestors.
const Key kProductionAvailableWorkerGridKey = ValueKey<String>(
  kProductionAvailableWorkerGridKeyValue,
);
