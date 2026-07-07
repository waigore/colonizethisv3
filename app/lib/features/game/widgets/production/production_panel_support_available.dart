/// Available subpanel for production screen. SPEC/ui/production-panel.md.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'production_panel.dart';

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
