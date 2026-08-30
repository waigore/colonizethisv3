// Available subpanel for production screen. SPEC/ui/production-panel.md.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_panel.dart';
import '../../../../widgets/ct_resource_cell.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/resource_icon.dart';
import 'commodity_ui_helpers.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'production_available_grid.dart';
import 'production_available_trade_cell.dart';
import 'production_labour_helpers.dart';
import 'production_panel_constants.dart';
import 'production_panel_support_available_sections.dart';

/// Left-hand Available subpanel on the production screen.
class ProductionPanelAvailableSubpanel extends StatelessWidget {
  const ProductionPanelAvailableSubpanel({
    required this.game,
    required this.player,
    required this.labourReadiness,
    required this.forcesFeeding,
    required this.inputCommodityIds,
    required this.outputCommodityIds,
    required this.netDeltasByCommodity,
    required this.l10n,
    this.onOpenCommodityBreakdown,
    this.currentOrders,
    this.labourCallbacks,
    this.canEditLabour = false,
    this.onOpenTradeMarket,
    super.key,
  });

  final Game game;
  final Player player;
  final LabourReadinessSnapshot labourReadiness;
  final ForceFeedingSnapshot forcesFeeding;
  final Set<String> inputCommodityIds;
  final Set<String> outputCommodityIds;
  final Map<String, int> netDeltasByCommodity;
  final AppLocalizations l10n;
  final VoidCallback? onOpenCommodityBreakdown;
  final Orders? currentOrders;
  final ProductionLabourCallbacks? labourCallbacks;
  final bool canEditLabour;
  final void Function(String commodityId)? onOpenTradeMarket;

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
    final name = commodityDisplayName(l10n, c.id);
    final cell = CtResourceCell(
      key: ValueKey<String>('production_available_cell_${c.id}'),
      iconBuilder: (_) =>
          ResourceIcon(commodityId: c.id, size: CtResourceCell.leadingIconSize),
      name: name,
      quantity: qty,
      delta: change == 0 ? null : change,
    );
    final openTrade = onOpenTradeMarket;
    if (openTrade == null || !isWorldMarketTradeableCommodity(c.id)) {
      return cell;
    }
    return ProductionAvailableTradeCell(
      cell: cell,
      onOpenTrade: () => openTrade(c.id),
      tooltip: l10n.production_availableSellableTooltip,
      semanticLabel: l10n.production_availableOpenTradeSemantic(name),
    );
  }

  Widget buildCommodityGrid(
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
          CtActionTextButton(
            onPressed: onOpenCommodityBreakdown,
            label: l10n.production_breakdown,
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
      CtGap.m,
      ...buildFoodSection(availableFood, netChanges, sellableByCommodityId),
      ...buildMaterialsSection(
        rawMaterials,
        manufactured,
        netChanges,
        sellableByCommodityId,
      ),
      ...buildWorkerSection(theme),
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
