import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../config/editorial_monocle_palette.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_brass_divider.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_panel.dart';
import '../../../../widgets/ct_resource_cell.dart';
import '../../../../widgets/ct_section_label.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/resource_icon.dart';
import '../chrome/ct_action_text_button.dart';
import '../chrome/ct_danger_text_button.dart';
import 'production_allocation_row.dart';
import 'production_allocation_row_chrome.dart';
import 'production_available_grid.dart';
import 'production_labour_helpers.dart';
import 'production_labour_section.dart';

part 'production_panel_support_available.dart';
part 'production_panel_support_available_sections.dart';
part 'production_panel_support_allocation.dart';

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

class ProductionPanel extends StatelessWidget {
  const ProductionPanel({
    super.key,
    required this.game,
    required this.player,
    required this.desiredOutputByRecipe,
    required this.netDeltasByCommodity,
    required this.onDesiredOutputChanged,
    this.onOpenCommodityBreakdown,
    this.currentOrders,
    this.labourCallbacks,
    this.canEditLabour = false,
  });

  /// SPEC/ui/production-panel.md — [UiScreenIds.productionScreen]. Hosted by
  /// `ProductionScreen`; shares its stable surface ID.
  static const screenId = UiScreenIds.productionScreen;

  final Game game;
  final Player player;
  final Map<String, int> desiredOutputByRecipe;
  final Map<String, int> netDeltasByCommodity;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;

  /// When set, Available header shows a text button that opens the breakdown dialog.
  final VoidCallback? onOpenCommodityBreakdown;

  /// Required for the Labour controls to display queued counts. When `null`
  /// the Labour section renders read-only with zero pending counts.
  final Orders? currentOrders;

  /// Callbacks bound to the screen's providers. When `null`, the Labour
  /// controls render in read-only mode (no +/-/Disband buttons).
  final ProductionLabourCallbacks? labourCallbacks;

  /// True when the viewed player may mutate orders or pool via the Labour
  /// controls. Combined with [labourCallbacks] presence to gate buttons.
  final bool canEditLabour;

  static Set<String> get _inputCommodityIds {
    final inputIds = <String>{};
    for (final recipe in ProductionRecipesCatalog.all) {
      inputIds.addAll(recipe.inputQuantities.keys);
    }
    return inputIds;
  }

  static Set<String> get _outputCommodityIds {
    return ProductionRecipesCatalog.all.map((r) => r.outputCommodityId).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final regimentCounts = regimentTypeCountsForPlayer(
      game.worldState,
      player.id,
    );
    final shipCounts = shipTypeCountsForPlayer(game.worldState, player.id);
    final effectiveLabour = effectiveLabourForWorkers(
      workers: player.workerPool,
      stockpile: player.stockpile,
      regimentCountsById: regimentCounts,
      shipCountsById: shipCounts,
    );
    final inputCommodityIds = _inputCommodityIds;
    final outputCommodityIds = _outputCommodityIds;
    final isNarrow = MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    final availableSubpanel = _AvailableSubpanel(
      game: game,
      player: player,
      effectiveLabour: effectiveLabour,
      inputCommodityIds: inputCommodityIds,
      outputCommodityIds: outputCommodityIds,
      netDeltasByCommodity: netDeltasByCommodity,
      l10n: l10n,
      onOpenCommodityBreakdown: onOpenCommodityBreakdown,
      currentOrders: currentOrders,
      labourCallbacks: labourCallbacks,
      canEditLabour: canEditLabour,
    );
    final allocationSubpanel = _AllocationSubpanel(
      player: player,
      effectiveLabour: effectiveLabour,
      desiredOutputByRecipe: desiredOutputByRecipe,
      onDesiredOutputChanged: onDesiredOutputChanged,
      l10n: l10n,
    );

    if (isNarrow) {
      return _ProductionPanelNarrowLayout(
        key: kProductionPanelNarrowLayoutKey,
        availableSubpanel: availableSubpanel,
        allocationSubpanel: allocationSubpanel,
      );
    }

    return _ProductionPanelWideLayout(
      key: kProductionPanelWideLayoutKey,
      availableSubpanel: availableSubpanel,
      allocationSubpanel: allocationSubpanel,
    );
  }
}

class _ProductionPanelNarrowLayout extends StatelessWidget {
  const _ProductionPanelNarrowLayout({
    super.key,
    required this.availableSubpanel,
    required this.allocationSubpanel,
  });

  final Widget availableSubpanel;
  final Widget allocationSubpanel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          availableSubpanel,
          const SizedBox(height: 24),
          allocationSubpanel,
        ],
      ),
    );
  }
}

class _ProductionPanelWideLayout extends StatelessWidget {
  const _ProductionPanelWideLayout({
    super.key,
    required this.availableSubpanel,
    required this.allocationSubpanel,
  });

  final Widget availableSubpanel;
  final Widget allocationSubpanel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: availableSubpanel),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: allocationSubpanel),
        ],
      ),
    );
  }
}
