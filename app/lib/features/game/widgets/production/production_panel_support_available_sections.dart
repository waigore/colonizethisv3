import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_resource_cell.dart';
import '../../../../widgets/ct_section_label.dart';
import '../../../../widgets/resource_icon.dart';
import 'production_available_grid.dart';
import 'production_forces_food_readiness_summary.dart';
import 'production_labour_readiness_summary.dart';
import 'production_labour_section.dart';
import 'production_panel_constants.dart';
import 'production_panel_support_available.dart';

extension ProductionPanelAvailableSections on ProductionPanelAvailableSubpanel {
  Widget buildWorkerCell(String workerType, int count) {
    return CtResourceCell(
      key: ValueKey<String>('production_available_worker_$workerType'),
      iconBuilder: (_) => WorkerIcon(
        workerType: workerType,
        size: CtResourceCell.leadingIconSize,
      ),
      name: workerDisplayName(workerType),
      quantity: count,
    );
  }

  String workerDisplayName(String workerType) {
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

  List<Widget> buildFoodSection(
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
      buildCommodityGrid(availableFood, netChanges, sellableByCommodityId),
      CtGap.ml,
    ];
  }

  List<Widget> buildMaterialsSection(
    List<Commodity> rawMaterials,
    List<Commodity> manufactured,
    Map<String, int> netChanges,
    Map<CommodityId, int> sellableByCommodityId,
  ) {
    final children = <Widget>[
      CtSectionLabel(l10n.production_rawMaterials),
      const SizedBox(height: 6),
      buildCommodityGrid(rawMaterials, netChanges, sellableByCommodityId),
    ];
    if (manufactured.isNotEmpty) {
      children.addAll([
        CtGap.ml,
        CtSectionLabel(l10n.production_manufactured),
        const SizedBox(height: 6),
        buildCommodityGrid(manufactured, netChanges, sellableByCommodityId),
      ]);
    }
    return children;
  }

  List<Widget> buildWorkerSection(ThemeData theme) {
    final children = <Widget>[
      CtGap.ml,
      CtSectionLabel(l10n.production_workers),
      const SizedBox(height: 6),
      AvailableCellGrid(
        key: kProductionAvailableWorkerGridKey,
        columnCount: kProductionAvailableWorkerGridColumns,
        cells: <Widget>[
          buildWorkerCell('peasant', player.workerPool.peasants),
          buildWorkerCell('apprentice', player.workerPool.apprentices),
          buildWorkerCell('journeyman', player.workerPool.journeymen),
          buildWorkerCell('master', player.workerPool.masters),
        ],
      ),
      CtGap.m,
      ProductionLabourReadinessSummary(
        snapshot: labourReadiness,
        l10n: l10n,
        theme: theme,
      ),
      CtGap.m,
      ProductionForcesFoodReadinessSummary(
        snapshot: forcesFeeding,
        l10n: l10n,
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
}
