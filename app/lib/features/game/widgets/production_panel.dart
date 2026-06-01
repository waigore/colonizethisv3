import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/constants.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_brass_divider.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_panel.dart';
import '../../../widgets/ct_resource_cell.dart';
import '../../../widgets/ct_section_label.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/resource_icon.dart';
import 'chrome/ct_danger_text_button.dart';
import 'production_allocation_row.dart';
import 'production_allocation_row_chrome.dart';
import 'production_available_grid.dart';
import 'production_labour_helpers.dart';
import 'production_labour_section.dart';

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

class _AvailableSubpanel extends StatelessWidget {
  const _AvailableSubpanel({
    required this.game,
    required this.player,
    required this.effectiveLabour,
    required this.inputCommodityIds,
    required this.outputCommodityIds,
    required this.netDeltasByCommodity,
    required this.l10n,
    this.onOpenCommodityBreakdown,
    this.currentOrders,
    this.labourCallbacks,
    this.canEditLabour = false,
  });

  final Game game;
  final Player player;
  final int effectiveLabour;
  final Set<String> inputCommodityIds;
  final Set<String> outputCommodityIds;
  final Map<String, int> netDeltasByCommodity;
  final AppLocalizations l10n;
  final VoidCallback? onOpenCommodityBreakdown;
  final Orders? currentOrders;
  final ProductionLabourCallbacks? labourCallbacks;
  final bool canEditLabour;

  /// Quantity shown in Available commodity cells for tradeable stock.
  ///
  /// Matches the Trade Market tab `(N)` sellable readout:
  /// `sellableHeadroomByCommodityId` (offer cap minus staged offers).
  /// Riches and zero-stockpile commodities fall back to raw stockpile.
  int _displayedStockpileQuantity(
    Commodity c,
    Map<CommodityId, int> sellableByCommodityId,
  ) {
    final headroom = sellableByCommodityId[c.id];
    if (headroom != null) return headroom;
    return player.stockpile.quantityOf(c.id);
  }

  Widget _buildCommodityCell(Commodity c, int qty, int change) {
    final name = c.displayName ?? c.id;
    return CtResourceCell(
      key: ValueKey<String>('production_available_cell_${c.id}'),
      iconBuilder: (_) => ResourceIcon(
        commodityId: c.id,
        size: CtResourceCell.leadingIconSize,
      ),
      name: name,
      quantity: qty,
      delta: change == 0 ? null : change,
    );
  }

  Widget _buildCommodityGrid(
    List<Commodity> commodities,
    Map<String, int> netChanges,
    Map<CommodityId, int> sellableByCommodityId,
  ) {
    return AvailableCellGrid(
      key: ValueKey<String>(
        'production_available_commodity_grid_${commodities.map((c) => c.id).join('_')}',
      ),
      columnCount: kProductionAvailableCommodityGridColumns,
      cells: <Widget>[
        for (final commodity in commodities)
          _buildCommodityCell(
            commodity,
            _displayedStockpileQuantity(commodity, sellableByCommodityId),
            netChanges[commodity.id] ?? 0,
          ),
      ],
    );
  }

  Widget _buildWorkerCell(String workerType, int count) {
    return CtResourceCell(
      key: ValueKey<String>('production_available_worker_$workerType'),
      iconBuilder: (_) => WorkerIcon(
        workerType: workerType,
        size: CtResourceCell.leadingIconSize,
      ),
      name: _workerDisplayName(workerType),
      quantity: count,
    );
  }

  String _workerDisplayName(String workerType) {
    switch (workerType) {
      case 'peasant':
        return l10n.production_workers_peasants;
      case 'apprentice':
        return l10n.production_workers_apprentices;
      case 'journeyman':
        return l10n.production_workers_journeymen;
      case 'master':
        return l10n.production_workers_masters;
      default:
        return workerType;
    }
  }

  List<Widget> _buildFoodSection(
    List<Commodity> availableFood,
    Map<String, int> netChanges,
    Map<CommodityId, int> sellableByCommodityId,
  ) {
    if (availableFood.isEmpty) {
      return const <Widget>[];
    }
    return <Widget>[
      CtSectionLabel(l10n.production_food),
      const SizedBox(height: 6),
      _buildCommodityGrid(availableFood, netChanges, sellableByCommodityId),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildMaterialsSection(
    List<Commodity> rawMaterials,
    List<Commodity> manufactured,
    Map<String, int> netChanges,
    Map<CommodityId, int> sellableByCommodityId,
  ) {
    final children = <Widget>[
      CtSectionLabel(l10n.production_rawMaterials),
      const SizedBox(height: 6),
      _buildCommodityGrid(rawMaterials, netChanges, sellableByCommodityId),
    ];
    if (manufactured.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 12),
        CtSectionLabel(l10n.production_manufactured),
        const SizedBox(height: 6),
        _buildCommodityGrid(manufactured, netChanges, sellableByCommodityId),
      ]);
    }
    return children;
  }

  List<Widget> _buildWorkerSection(ThemeData theme) {
    final children = <Widget>[
      const SizedBox(height: 12),
      CtSectionLabel(l10n.production_workers),
      const SizedBox(height: 6),
      AvailableCellGrid(
        key: kProductionAvailableWorkerGridKey,
        columnCount: kProductionAvailableWorkerGridColumns,
        cells: <Widget>[
          _buildWorkerCell('peasant', player.workerPool.peasants),
          _buildWorkerCell('apprentice', player.workerPool.apprentices),
          _buildWorkerCell('journeyman', player.workerPool.journeymen),
          _buildWorkerCell('master', player.workerPool.masters),
        ],
      ),
      const SizedBox(height: 8),
      EffectiveLabourTotal(
        text: l10n.production_effectiveLabour(effectiveLabour),
        theme: theme,
      ),
    ];
    if (currentOrders != null && labourCallbacks != null) {
      children.addAll(<Widget>[
        const SizedBox(height: 12),
        CtSectionLabel(l10n.production_labourControlsSectionLabel),
        const SizedBox(height: 6),
        ProductionLabourSection(
          player: player,
          currentOrders: currentOrders!,
          canEdit: canEditLabour,
          callbacks: labourCallbacks!,
        ),
      ]);
    }
    return children;
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            l10n.production_available,
            style: theme.textTheme.titleSmall,
          ),
        ),
        if (onOpenCommodityBreakdown != null)
          CtNinePatchButton(
            onPressed: onOpenCommodityBreakdown,
            child: Text(l10n.production_breakdown),
          ),
      ],
    );
  }

  List<Widget> _buildBodyChildren(ThemeData theme) {
    final netChanges = netDeltasByCommodity;
    final sellableByCommodityId = sellableHeadroomByCommodityId(
      game: game,
      playerId: player.id,
      orders: currentOrders ?? const Orders(),
    );
    final rawMaterials = CommodityCatalog.all
        .where(
          (c) =>
              c.category == CommodityCategory.rawMaterial &&
              inputCommodityIds.contains(c.id),
        )
        .toList();
    final manufactured = CommodityCatalog.all
        .where((c) => c.category == CommodityCategory.manufactured)
        .toList();
    final availableFood = CommodityCatalog.all
        .where((c) => c.category == CommodityCategory.food)
        .toList();
    return <Widget>[
      _buildHeader(theme),
      const SizedBox(height: 8),
      ..._buildFoodSection(
        availableFood,
        netChanges,
        sellableByCommodityId,
      ),
      ..._buildMaterialsSection(
        rawMaterials,
        manufactured,
        netChanges,
        sellableByCommodityId,
      ),
      ..._buildWorkerSection(theme),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CtPanel(
      padding: const EdgeInsets.all(CtSpacing.ml),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildBodyChildren(theme),
        ),
      ),
    );
  }
}

class _AllocationSubpanel extends StatelessWidget {
  const _AllocationSubpanel({
    required this.player,
    required this.effectiveLabour,
    required this.desiredOutputByRecipe,
    required this.onDesiredOutputChanged,
    required this.l10n,
  });

  final Player player;
  final int effectiveLabour;
  final Map<String, int> desiredOutputByRecipe;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;
  final AppLocalizations l10n;

  Widget _buildRecipeLabel(ProductionRecipe recipe, ThemeData theme) {
    final outputCommodity = CommodityCatalog.byId[recipe.outputCommodityId];
    final outputName = outputCommodity?.displayName ?? recipe.outputCommodityId;
    final inputParts = recipe.inputQuantities.entries
        .map((e) {
          final comm = CommodityCatalog.byId[e.key];
          final name = comm?.displayName ?? e.key;
          return '$name ×${e.value}';
        })
        .join(', ');
    final label = '$outputName ($inputParts)';

    final hasOutputIcon =
        outputCommodity != null && ResourceIcon.hasIcon(outputCommodity.id);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasOutputIcon) ...[
          ResourceIcon(commodityId: recipe.outputCommodityId, size: 14),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.labelMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  int _computeTotalRequiredLabour() {
    return desiredOutputByRecipe.entries.fold<int>(0, (sum, entry) {
      final recipe = ProductionRecipesCatalog.byId[entry.key];
      if (recipe == null) {
        return sum;
      }
      return sum + entry.value * recipe.labourPerOutput;
    });
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            l10n.production_allocation,
            style: theme.textTheme.titleSmall,
          ),
        ),
        CtDangerTextButton(
          key: const ValueKey<String>('production_allocation_reset_button'),
          onPressed: () => onDesiredOutputChanged({}),
          label: l10n.common_reset,
          tooltip: l10n.common_reset,
        ),
      ],
    );
  }

  /// Builds the recipe rows interleaved with `CtBrassDivider`s per
  /// `SPEC/ui/production-panel.md` § Allocation row chrome — exactly
  /// `N - 1` dividers between consecutive rows, none at the leading or
  /// trailing edges (`Refs #2862` S3 / R13).
  List<Widget> _buildAllocationRows(ThemeData theme) {
    final recipes = ProductionRecipesCatalog.all;
    if (recipes.isEmpty) {
      return const <Widget>[];
    }
    final widgets = <Widget>[];
    for (int i = 0; i < recipes.length; i++) {
      if (i > 0) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: CtBrassDivider(),
          ),
        );
      }
      final recipe = recipes[i];
      widgets.add(
        ProductionAllocationRowChrome(
          key: ValueKey<String>('production_alloc_row_chrome_${recipe.id}'),
          child: ProductionAllocationRow(
            key: ValueKey<String>('production_alloc_row_${recipe.id}'),
            recipe: recipe,
            player: player,
            effectiveLabour: effectiveLabour,
            desiredOutputByRecipe: desiredOutputByRecipe,
            onDesiredOutputChanged: onDesiredOutputChanged,
            buildRecipeLabel: (value) => _buildRecipeLabel(value, theme),
            l10n: l10n,
            theme: theme,
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildLabourSummary(
    ThemeData theme,
    int totalRequiredLabour,
    bool labourInsufficient,
  ) {
    return <Widget>[
      const SizedBox(height: 8),
      Text(
        l10n.production_totalLabour(totalRequiredLabour, effectiveLabour),
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: labourInsufficient ? theme.colorScheme.error : null,
        ),
      ),
      if (labourInsufficient)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.production_labourInsufficient,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalRequiredLabour = _computeTotalRequiredLabour();
    final labourInsufficient = totalRequiredLabour > effectiveLabour;

    return CtPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 8),
            ..._buildAllocationRows(theme),
            ..._buildLabourSummary(
              theme,
              totalRequiredLabour,
              labourInsufficient,
            ),
          ],
        ),
      ),
    );
  }
}

