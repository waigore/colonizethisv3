/// Per-unit civilian row builder. SPEC/ui/civilian-units-panel.md.
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/app_event_bus_panel_nav.dart';
import '../../../../../core/services/game_service/try_get_game_map_data.dart';
import '../../../../../providers/game_service_provider.dart';
import '../../../../../providers/games_provider.dart';
import 'civilian_units_panel_support_row_card.dart';
import 'civilian_units_panel_unit_row_actions_host.dart';
import 'civilian_units_panel_unit_row_details.dart';
import 'civilian_units_panel_unit_row_pending.dart';
import 'civilian_units_panel_unit_row_shortcuts.dart';

class CivilianUnitsPanelUnitRow extends ConsumerWidget {
  const CivilianUnitsPanelUnitRow({
    required this.game,
    required this.unit,
    required this.provinceNames,
    required this.currentOrders,
    required this.humanPlayerId,
    required this.bus,
    required this.isTileScope,
    required this.isSelectedInTileScope,
    required this.onSelectInTileScope,
    required this.projectedTileKey,
    required this.prospectShortcutTargetTileKey,
    required this.exploreShortcutTargetTileKey,
    required this.buildImprovementShortcutTargetTileKey,
    required this.buildRoadShortcutTargetTileKey,
    required this.buildFortShortcutTargetTileKey,
    required this.buildPortShortcutTargetTileKey,
    required this.buildRailShortcutTargetTileKey,
    required this.purchaseLandShortcutTargetTileKey,
    required this.upgradeTownShortcutTargetTileKey,
    required this.relocateShortcutTargetTileKey,
    this.counterSpyShortcutTargetTileKey,
    this.readOnly = false,
    super.key,
  });

  final Game game;
  final Unit unit;
  final Map<String, String> provinceNames;
  final Orders currentOrders;
  final String humanPlayerId;
  final AppEventBus bus;
  final bool isTileScope;
  final bool isSelectedInTileScope;
  final VoidCallback onSelectInTileScope;
  final String? projectedTileKey;
  final String? prospectShortcutTargetTileKey;
  final String? exploreShortcutTargetTileKey;
  final String? buildImprovementShortcutTargetTileKey;
  final String? buildRoadShortcutTargetTileKey;
  final String? buildFortShortcutTargetTileKey;
  final String? buildPortShortcutTargetTileKey;
  final String? buildRailShortcutTargetTileKey;
  final String? purchaseLandShortcutTargetTileKey;
  final String? upgradeTownShortcutTargetTileKey;
  final String? relocateShortcutTargetTileKey;
  final String? counterSpyShortcutTargetTileKey;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = CivilianUnitsPanelUnitRowPending(
      unit: unit,
      currentOrders: currentOrders,
      humanPlayerId: humanPlayerId,
    );
    final availableWorkTargetIds = ref.watch(
      availableWorkTargetIdsForUnitProvider(unit.id),
    );
    final l10n = appL10n(context);
    final statusLabel =
        civilianUnitsPanelUnitRowSpyStatusLabel(
          l10n: l10n,
          game: game,
          unit: unit,
          pending: pending,
          provinceNames: provinceNames,
          projectedTileKey: projectedTileKey,
          humanPlayerId: humanPlayerId,
        ) ??
        switch (unit.status) {
          UnitStatus.idle => l10n.province_unitStatus_idle,
          UnitStatus.working => l10n.province_unitStatus_working,
        };
    final showActions = !isTileScope || isSelectedInTileScope;
    final inExplorerShortcutMode =
        civilianUnitsPanelUnitRowInExplorerShortcutMode(
          prospectShortcutTargetTileKey: prospectShortcutTargetTileKey,
          exploreShortcutTargetTileKey: exploreShortcutTargetTileKey,
          buildImprovementShortcutTargetTileKey:
              buildImprovementShortcutTargetTileKey,
          buildRoadShortcutTargetTileKey: buildRoadShortcutTargetTileKey,
          buildFortShortcutTargetTileKey: buildFortShortcutTargetTileKey,
          buildPortShortcutTargetTileKey: buildPortShortcutTargetTileKey,
          buildRailShortcutTargetTileKey: buildRailShortcutTargetTileKey,
          purchaseLandShortcutTargetTileKey: purchaseLandShortcutTargetTileKey,
          upgradeTownShortcutTargetTileKey: upgradeTownShortcutTargetTileKey,
        );
    final tileKeyForLocate = projectedTileKey;
    final regionIdForLocate = Unit.regionIdFromTileKey(tileKeyForLocate);
    final rowActions = buildCivilianUnitsPanelUnitRowActions(
      l10n: l10n,
      context: context,
      bus: bus,
      game: game,
      unit: unit,
      humanPlayerId: humanPlayerId,
      pending: pending,
      readOnly: readOnly,
      showActions: showActions,
      inExplorerShortcutMode: inExplorerShortcutMode,
      availableWorkTargetIds: availableWorkTargetIds,
      tileKeyForLocate: tileKeyForLocate,
      regionIdForLocate: regionIdForLocate,
      prospectShortcutTargetTileKey: prospectShortcutTargetTileKey,
      exploreShortcutTargetTileKey: exploreShortcutTargetTileKey,
      buildImprovementShortcutTargetTileKey:
          buildImprovementShortcutTargetTileKey,
      buildRoadShortcutTargetTileKey: buildRoadShortcutTargetTileKey,
      buildFortShortcutTargetTileKey: buildFortShortcutTargetTileKey,
      buildPortShortcutTargetTileKey: buildPortShortcutTargetTileKey,
      buildRailShortcutTargetTileKey: buildRailShortcutTargetTileKey,
      purchaseLandShortcutTargetTileKey: purchaseLandShortcutTargetTileKey,
      upgradeTownShortcutTargetTileKey: upgradeTownShortcutTargetTileKey,
      relocateShortcutTargetTileKey: relocateShortcutTargetTileKey,
      counterSpyShortcutTargetTileKey: counterSpyShortcutTargetTileKey,
    );
    final selected = isTileScope && isSelectedInTileScope;
    return CivilianUnitRowCard(
      key: ValueKey('civilian-unit-card-${unit.id}'),
      selected: selected,
      onTap: () => _handleRowTap(),
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(unit.type, overflow: TextOverflow.ellipsis),
          Text(l10n.civilian_units_status(statusLabel)),
          Text(
            l10n.civilian_units_location(
              civilianUnitsPanelUnitRowLocationLabel(
                provinceNames: provinceNames,
                projectedTileKey: projectedTileKey,
              ),
            ),
          ),
          buildCivilianUnitsPanelUnitRowAssignedToSubtitle(
            l10n: l10n,
            game: game,
            unit: unit,
            pending: pending,
            provinceNames: provinceNames,
            humanPlayerId: humanPlayerId,
            mapData: tryGetGameMapData(
              () => ref.read(gameServiceProvider).getMapData(game.id),
            ),
            buildImprovementShortcutTargetTileKey:
                buildImprovementShortcutTargetTileKey,
            purchaseLandShortcutTargetTileKey:
                purchaseLandShortcutTargetTileKey,
            readOnly: readOnly,
          ),
        ],
      ),
      actions: rowActions,
    );
  }

  void _handleRowTap() {
    if (isTileScope) {
      onSelectInTileScope();
      return;
    }
    final tileKey = projectedTileKey;
    if (tileKey == null) return;
    final regionId = Unit.regionIdFromTileKey(tileKey);
    if (regionId == null) return;
    bus.closePanelThenEmit(
      LocateMapTileEvent(tileKey: tileKey, regionId: regionId),
    );
  }
}
