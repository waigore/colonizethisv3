/// Available subpanel section builders. SPEC/ui/production-panel.md.

part of 'production_panel.dart';

extension _AvailableSubpanelSections on _AvailableSubpanel {
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
      CtGap.ml,
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
        CtGap.ml,
        CtSectionLabel(l10n.production_manufactured),
        const SizedBox(height: 6),
        _buildCommodityGrid(manufactured, netChanges, sellableByCommodityId),
      ]);
    }
    return children;
  }

  List<Widget> _buildWorkerSection(ThemeData theme) {
    final children = <Widget>[
      CtGap.ml,
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
      CtGap.m,
      EffectiveLabourTotal(
        text: l10n.production_effectiveLabour(effectiveLabour),
        theme: theme,
      ),
    ];
    if (currentOrders != null && labourCallbacks != null) {
      children.addAll(<Widget>[
        CtGap.ml,
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
}
