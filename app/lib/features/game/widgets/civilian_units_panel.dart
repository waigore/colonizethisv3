// Civilian units panel. SPEC/ui/civilian-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/ct_e2e.dart';
import '../../../config/ct_e2e_last_panel_snapshot.dart';
import '../../../core/services/app_event_handler_scope.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/games_provider.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/resource_icon.dart';
import 'units/shared/region_section_header.dart';
import 'units/shared/units_entity_action_row.dart';
import 'units/shared/units_panel_region_label.dart';
import 'units/shared/units_panel_shell.dart';

/// Panel that lists all civilian units for the human player. SPEC/ui/civilian-units-panel.md.

part 'civilian_units_panel_support.dart';

class CivilianUnitsPanel extends ConsumerStatefulWidget {
  const CivilianUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    this.currentOrders = const Orders(),
    this.tileScopeTileKey,
    this.initialSelectedUnitId,
    this.explorerOnly = false,
    this.builderOnly = false,
    this.prospectShortcutTargetTileKey,
    this.exploreShortcutTargetTileKey,
    this.buildImprovementShortcutTargetTileKey,
  });

  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;

  /// Current-turn orders (to show Assign only when no pending work, Cancel when pending or in-progress).
  final Orders currentOrders;

  /// Optional tile key (`regionId|provinceId|x|y`) for tile-scoped mode.
  final String? tileScopeTileKey;

  /// Optional initial selected unit in tile-scoped mode.
  final String? initialSelectedUnitId;

  /// Optional filter mode used by province prospect shortcut.
  final bool explorerOnly;

  /// Optional filter mode used by province build-improvement shortcut.
  final bool builderOnly;

  /// Optional selected tile key for immediate explorer prospect assign flow.
  final String? prospectShortcutTargetTileKey;

  /// Optional selected tile key for immediate explorer explore assign flow.
  final String? exploreShortcutTargetTileKey;

  /// Optional selected tile key for immediate builder build-improvement assign flow.
  final String? buildImprovementShortcutTargetTileKey;

  @override
  ConsumerState<CivilianUnitsPanel> createState() => _CivilianUnitsPanelState();
}

class _CivilianUnitsPanelState extends ConsumerState<CivilianUnitsPanel> {
  String? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _selectedUnitId = widget.initialSelectedUnitId;
  }

  @override
  void didUpdateWidget(covariant CivilianUnitsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedUnitId != widget.initialSelectedUnitId) {
      _selectedUnitId = widget.initialSelectedUnitId;
    }
  }

  bool _isExplorerUnit(Unit unit) {
    return workOrderTargetsByUnitType[unit.type]?.contains(
          kWorkTargetProspect,
        ) ??
        false;
  }

  bool _isBuilderUnit(Unit unit) {
    return workOrderTargetsByUnitType[unit.type]?.contains(
          kWorkTargetBuildImprovement,
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final provinceNames = _provinceNamesByPrefixedId(widget.game);
    final ow = _civilianUnitsInRegion(
      widget.game.worldState.oldWorld.units,
      widget.humanPlayerId,
      provinceNames,
      widget.currentOrders,
    );
    final nw = _civilianUnitsInRegion(
      widget.game.worldState.newWorld.units,
      widget.humanPlayerId,
      provinceNames,
      widget.currentOrders,
    );
    List<Unit> scopedOw = ow;
    List<Unit> scopedNw = nw;
    final scopeTileKey = widget.tileScopeTileKey;
    final tileScopeActive = scopeTileKey != null && scopeTileKey.isNotEmpty;
    if (tileScopeActive) {
      scopedOw = ow
          .where(
            (u) =>
                projectedCivilianTileKey(
                  unit: u,
                  playerId: widget.humanPlayerId,
                  orders: widget.currentOrders,
                ) ==
                scopeTileKey,
          )
          .toList();
      scopedNw = nw
          .where(
            (u) =>
                projectedCivilianTileKey(
                  unit: u,
                  playerId: widget.humanPlayerId,
                  orders: widget.currentOrders,
                ) ==
                scopeTileKey,
          )
          .toList();
    }
    if (widget.explorerOnly) {
      scopedOw = scopedOw.where((Unit u) => _isExplorerUnit(u)).toList();
      scopedNw = scopedNw.where((Unit u) => _isExplorerUnit(u)).toList();
    }
    if (widget.builderOnly) {
      scopedOw = scopedOw.where((Unit u) => _isBuilderUnit(u)).toList();
      scopedNw = scopedNw.where((Unit u) => _isBuilderUnit(u)).toList();
    }
    final hasAny = scopedOw.isNotEmpty || scopedNw.isNotEmpty;
    final allScopedUnits = <Unit>[...scopedOw, ...scopedNw];
    final selectedUnitId = _selectedUnitId;
    final resolvedSelectedUnitId =
        selectedUnitId != null &&
            allScopedUnits.any((u) => u.id == selectedUnitId)
        ? selectedUnitId
        : (allScopedUnits.isNotEmpty ? allScopedUnits.first.id : null);
    Unit? resolvedSelectedUnit;
    if (resolvedSelectedUnitId != null) {
      for (final u in allScopedUnits) {
        if (u.id == resolvedSelectedUnitId) {
          resolvedSelectedUnit = u;
          break;
        }
      }
    }
    final headerTileKey = resolvedSelectedUnit == null
        ? null
        : projectedCivilianTileKey(
            unit: resolvedSelectedUnit,
            playerId: widget.humanPlayerId,
            orders: widget.currentOrders,
          );

    final panel = UnitsPanelShell(
      title: tileScopeActive
          ? l10n.civilian_units_title_tile
          : l10n.civilian_units_title,
      actions: [
        if (tileScopeActive)
          CtNinePatchButton(
            enabled: headerTileKey != null && headerTileKey.isNotEmpty,
            onPressed: () {
              final key = headerTileKey;
              if (key == null || key.isEmpty) {
                return;
              }
              widget.bus.emit(const ClosePanelEvent());
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.bus.emit(OpenMapTileDetailEvent(tileKey: key));
              });
            },
            child: Text(l10n.civilian_units_tile),
          ),
        CtNinePatchButton(
          onPressed: () {
            widget.bus.emit(const ClosePanelEvent());
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.bus.emit(OpenDialogEvent(trainCiviliansDialogId));
            });
          },
          child: Text(l10n.common_train),
        ),
      ],
      hasContent: hasAny,
      listChildren: [
        if (scopedOw.isNotEmpty) ...[
          RegionSectionHeader(label: unitsPanelRegionLabel('oldWorld')),
          ...scopedOw.map(
            (u) => _UnitRow(
              game: widget.game,
              unit: u,
              provinceNames: provinceNames,
              currentOrders: widget.currentOrders,
              humanPlayerId: widget.humanPlayerId,
              bus: widget.bus,
              isTileScope: tileScopeActive,
              isSelectedInTileScope: resolvedSelectedUnitId == u.id,
              onSelectInTileScope: () => setState(() => _selectedUnitId = u.id),
              projectedTileKey: projectedCivilianTileKey(
                unit: u,
                playerId: widget.humanPlayerId,
                orders: widget.currentOrders,
              ),
              prospectShortcutTargetTileKey:
                  widget.prospectShortcutTargetTileKey,
              exploreShortcutTargetTileKey: widget.exploreShortcutTargetTileKey,
              buildImprovementShortcutTargetTileKey:
                  widget.buildImprovementShortcutTargetTileKey,
            ),
          ),
        ],
        if (scopedNw.isNotEmpty) ...[
          RegionSectionHeader(label: unitsPanelRegionLabel('newWorld')),
          ...scopedNw.map(
            (u) => _UnitRow(
              game: widget.game,
              unit: u,
              provinceNames: provinceNames,
              currentOrders: widget.currentOrders,
              humanPlayerId: widget.humanPlayerId,
              bus: widget.bus,
              isTileScope: tileScopeActive,
              isSelectedInTileScope: resolvedSelectedUnitId == u.id,
              onSelectInTileScope: () => setState(() => _selectedUnitId = u.id),
              projectedTileKey: projectedCivilianTileKey(
                unit: u,
                playerId: widget.humanPlayerId,
                orders: widget.currentOrders,
              ),
              prospectShortcutTargetTileKey:
                  widget.prospectShortcutTargetTileKey,
              exploreShortcutTargetTileKey: widget.exploreShortcutTargetTileKey,
              buildImprovementShortcutTargetTileKey:
                  widget.buildImprovementShortcutTargetTileKey,
            ),
          ),
        ],
      ],
      emptyMessage: l10n.civilian_units_empty,
    );
    if (kCtE2EEnabled) {
      final snapshotTargets = <String, List<String>>{
        for (final u in allScopedUnits)
          u.id: ref.read(availableWorkTargetIdsForUnitProvider(u.id)),
      };
      updateCtE2eCivilianPanelSnapshotIfEnabled(
        CtE2eCivilianPanelSnapshot(
          game: widget.game,
          humanPlayerId: widget.humanPlayerId,
          currentOrders: widget.currentOrders,
          availableWorkTargets: snapshotTargets,
          tileScopeTileKey: widget.tileScopeTileKey,
          initialSelectedUnitId: widget.initialSelectedUnitId,
          resolvedSelectedUnitId: resolvedSelectedUnitId,
        ),
      );
      return KeyedSubtree(key: kCtE2ECivilianPanelRootKey, child: panel);
    }
    return panel;
  }
}
