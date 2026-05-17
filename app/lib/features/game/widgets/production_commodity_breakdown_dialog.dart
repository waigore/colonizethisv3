// Read-only commodity phase breakdown for Production panel. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/production_allocation_provider.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/resource_icon.dart';

/// Dialog showing per-commodity preview deltas for each economy preview phase.
class ProductionCommodityBreakdownDialog extends ConsumerStatefulWidget {
  const ProductionCommodityBreakdownDialog({
    super.key,
    required this.game,
    required this.player,
    required this.topology,
    required this.tileMapByRegion,
    required this.currentOrders,
  });

  final Game game;
  final Player player;
  final MapTopology topology;
  final Map<String, TileMapResult>? tileMapByRegion;
  final Orders currentOrders;

  @override
  ConsumerState<ProductionCommodityBreakdownDialog> createState() =>
      _ProductionCommodityBreakdownDialogState();

  static String _phaseColumnLabel(
    AppLocalizations l10n,
    EconomyPreviewStockpilePhase phase,
  ) {
    return switch (phase) {
      EconomyPreviewStockpilePhase.pendingBuildCosts =>
        l10n.production_breakdown_phase_pendingBuildCosts,
      EconomyPreviewStockpilePhase.extraction =>
        l10n.production_breakdown_phase_extraction,
      EconomyPreviewStockpilePhase.richesToTreasury =>
        l10n.production_breakdown_phase_richesToTreasury,
      EconomyPreviewStockpilePhase.consumption =>
        l10n.production_breakdown_phase_consumption,
      EconomyPreviewStockpilePhase.production =>
        l10n.production_breakdown_phase_production,
    };
  }

  static String _formatDelta(int v) {
    if (v > 0) return '+$v';
    return '$v';
  }
}

class _ProductionCommodityBreakdownDialogState
    extends ConsumerState<ProductionCommodityBreakdownDialog> {
  late final ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final desiredOutputByRecipe = ref.watch(productionDesiredOutputProvider);
    final defaultAssignmentsByPlayerId = {
      widget.player.id: assignedRecipesFromDesiredOutput(desiredOutputByRecipe),
    };
    final phaseDeltas = previewStockpilePhaseDeltasByCommodityForPlayer(
      game: widget.game,
      topology: widget.topology,
      playerId: widget.player.id,
      tileMapByRegion: widget.tileMapByRegion,
      currentOrders: widget.currentOrders,
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
      (l10n.production_food, commoditiesForCategory(CommodityCategory.food)),
      (
        l10n.production_rawMaterials,
        commoditiesForCategory(
          CommodityCategory.rawMaterial,
          restrictToInputs: inputCommodityIds,
        ),
      ),
      (
        l10n.production_manufactured,
        commoditiesForCategory(CommodityCategory.manufactured),
      ),
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
                Text(
                  ProductionCommodityBreakdownDialog._formatDelta(
                    phaseValue(c.id, p),
                  ),
                  maxLines: 1,
                ),
              ),
            ),
            DataCell(
              Text(
                ProductionCommodityBreakdownDialog._formatDelta(total),
                maxLines: 1,
              ),
            ),
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
          Text(
            l10n.production_breakdown_title,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 48,
                columns: [
                  DataColumn(label: Text(l10n.production_breakdown_commodity)),
                  ...EconomyPreviewStockpilePhase.values.map(
                    (p) => DataColumn(
                      label: Text(
                        ProductionCommodityBreakdownDialog._phaseColumnLabel(
                          l10n,
                          p,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ),
                  DataColumn(label: Text(l10n.production_breakdown_total)),
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: CtNinePatchButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.common_close),
            ),
          ),
        ],
      ),
    );
  }
}
