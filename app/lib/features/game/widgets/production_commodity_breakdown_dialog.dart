// Read-only commodity phase breakdown for Production panel. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/production_allocation_provider.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/resource_icon.dart';

/// Dialog showing per-commodity preview deltas for each economy preview phase.
class ProductionCommodityBreakdownDialog extends ConsumerWidget {
  const ProductionCommodityBreakdownDialog({
    super.key,
    required this.game,
    required this.player,
    required this.topology,
    required this.pendingOrders,
    required this.tileMapByRegion,
  });

  final Game game;
  final Player player;
  final MapTopology topology;
  final Orders pendingOrders;
  final Map<String, TileMapResult>? tileMapByRegion;

  static String _phaseColumnLabel(EconomyPreviewStockpilePhase phase) {
    return switch (phase) {
      EconomyPreviewStockpilePhase.pendingBuildTrainCosts =>
        'Pending build/train costs',
      EconomyPreviewStockpilePhase.extraction => 'Extraction',
      EconomyPreviewStockpilePhase.richesToTreasury => 'Riches to treasury',
      EconomyPreviewStockpilePhase.consumption => 'Consumption',
      EconomyPreviewStockpilePhase.production => 'Production',
    };
  }

  static String _formatDelta(int v) {
    if (v > 0) return '+$v';
    return '$v';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final desiredOutputByRecipe = ref.watch(productionDesiredOutputProvider);
    final defaultAssignmentsByPlayerId = {
      player.id: assignedRecipesFromDesiredOutput(desiredOutputByRecipe),
    };
    final phaseDeltas = previewStockpilePhaseDeltasByCommodityForPlayer(
      game: game,
      topology: topology,
      playerId: player.id,
      pendingOrders: pendingOrders,
      tileMapByRegion: tileMapByRegion,
      defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
    );

    final inputCommodityIds = <String>{};
    for (final recipe in ProductionRecipesCatalog.all) {
      inputCommodityIds.addAll(recipe.inputQuantities.keys);
    }

    List<Commodity> commoditiesForCategory(
      CommodityCategory category, {
      Set<String>? restrictToInputs,
    }) {
      return CommodityCatalog.all
          .where(
            (c) =>
                c.category == category &&
                (restrictToInputs == null || restrictToInputs.contains(c.id)),
          )
          .toList();
    }

    final sections = <(String, List<Commodity>)>[
      ('Food', commoditiesForCategory(CommodityCategory.food)),
      (
        'Raw Materials',
        commoditiesForCategory(
          CommodityCategory.rawMaterial,
          restrictToInputs: inputCommodityIds,
        ),
      ),
      ('Manufactured', commoditiesForCategory(CommodityCategory.manufactured)),
    ];

    int phaseValue(String commodityId, EconomyPreviewStockpilePhase phase) {
      return phaseDeltas[phase]?[commodityId] ?? 0;
    }

    int rowTotal(String commodityId) {
      var t = 0;
      for (final p in EconomyPreviewStockpilePhase.values) {
        t += phaseValue(commodityId, p);
      }
      return t;
    }

    List<DataRow> rowsFor(List<Commodity> list) {
      return list.map((c) {
        final total = rowTotal(c.id);
        final name = c.displayName ?? c.id;
        return DataRow(
          cells: [
            DataCell(
              Row(
                children: [
                  ResourceIcon(commodityId: c.id, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            ...EconomyPreviewStockpilePhase.values.map(
              (p) => DataCell(
                Text(_formatDelta(phaseValue(c.id, p)), maxLines: 1),
              ),
            ),
            DataCell(Text(_formatDelta(total), maxLines: 1)),
          ],
        );
      }).toList();
    }

    final phaseColCount = EconomyPreviewStockpilePhase.values.length;

    return CtDialogShell(
      maxWidth: 720,
      maxHeight: 560,
      destTileSize: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Commodity breakdown', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Flexible(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowHeight: 40,
                    dataRowMinHeight: 32,
                    dataRowMaxHeight: 48,
                    columns: [
                      const DataColumn(label: Text('Commodity')),
                      ...EconomyPreviewStockpilePhase.values.map(
                        (p) => DataColumn(
                          label: Text(_phaseColumnLabel(p), softWrap: true),
                        ),
                      ),
                      const DataColumn(label: Text('Total')),
                    ],
                    rows: [
                      for (final (label, commodities) in sections)
                        if (commodities.isNotEmpty) ...[
                          DataRow(
                            cells: [
                              DataCell(
                                Text(label, style: theme.textTheme.titleSmall),
                              ),
                              ...List<DataCell>.generate(
                                phaseColCount + 1,
                                (_) => const DataCell(SizedBox.shrink()),
                              ),
                            ],
                          ),
                          ...rowsFor(commodities),
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: CtNinePatchButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
