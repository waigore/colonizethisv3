// Civilian units panel. SPEC/ui/civilian-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/ct_e2e.dart';
import '../../../config/ct_e2e_last_panel_snapshot.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../core/services/app_event_handler_scope.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/games_provider.dart';
import '../../../widgets/ct_icon_action.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/resource_icon.dart';
import 'civilian_units_sort.dart';
import 'train_dialog_chrome.dart';
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
    this.civilianOwnerIds,
    required this.bus,
    this.currentOrders = const Orders(),
    this.tileScopeTileKey,
    this.initialSelectedUnitId,
    this.explorerOnly = false,
    this.builderOnly = false,
    this.prospectShortcutTargetTileKey,
    this.exploreShortcutTargetTileKey,
    this.buildImprovementShortcutTargetTileKey,
    this.readOnly = false,
  });

  /// SPEC/ui/civilian-units-panel.md — [UiScreenIds.civilianUnitsPanel].
  static const screenId = UiScreenIds.civilianUnitsPanel;

  final Game game;
  final String humanPlayerId;

  /// When set, lists civilians for every id (global observe). Otherwise [humanPlayerId] only.
  final Set<String>? civilianOwnerIds;

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

  /// When true, work assign/cancel and train are disabled (observe mode).
  final bool readOnly;

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

  List<Widget> _civilianListChildrenForRegion({
    required String regionId,
    required List<Unit> units,
    required bool multiOwner,
    required Game game,
    required Map<String, String> provinceNames,
    required bool tileScopeActive,
    required String? resolvedSelectedUnitId,
    required void Function(String id) onSelectUnit,
  }) {
    if (units.isEmpty) {
      return const [];
    }
    final children = <Widget>[
      RegionSectionHeader(label: unitsPanelRegionLabel(regionId)),
    ];
    if (!multiOwner) {
      children.addAll(
        units.map(
          (u) => _unitRow(
            unit: u,
            provinceNames: provinceNames,
            tileScopeActive: tileScopeActive,
            resolvedSelectedUnitId: resolvedSelectedUnitId,
            onSelectUnit: onSelectUnit,
          ),
        ),
      );
      return children;
    }
    final byOwner = <String, List<Unit>>{};
    for (final u in units) {
      byOwner.putIfAbsent(u.ownerId, () => []).add(u);
    }
    final ownerIds = byOwner.keys.toList()..sort();
    for (final ownerId in ownerIds) {
      final ownerUnits = byOwner[ownerId]!;
      children.add(
        RegionSectionHeader(
          label: game.factionDisplayNameById(ownerId) ?? ownerId,
        ),
      );
      children.addAll(
        ownerUnits.map(
          (u) => _unitRow(
            unit: u,
            provinceNames: provinceNames,
            tileScopeActive: tileScopeActive,
            resolvedSelectedUnitId: resolvedSelectedUnitId,
            onSelectUnit: onSelectUnit,
          ),
        ),
      );
    }
    return children;
  }

  Widget _unitRow({
    required Unit unit,
    required Map<String, String> provinceNames,
    required bool tileScopeActive,
    required String? resolvedSelectedUnitId,
    required void Function(String id) onSelectUnit,
  }) {
    return _UnitRow(
      game: widget.game,
      unit: unit,
      provinceNames: provinceNames,
      currentOrders: widget.currentOrders,
      humanPlayerId: unit.ownerId,
      bus: widget.bus,
      readOnly: widget.readOnly,
      isTileScope: tileScopeActive,
      isSelectedInTileScope: resolvedSelectedUnitId == unit.id,
      onSelectInTileScope: () => onSelectUnit(unit.id),
      projectedTileKey: projectedCivilianTileKey(
        unit: unit,
        playerId: unit.ownerId,
        orders: widget.currentOrders,
      ),
      prospectShortcutTargetTileKey: widget.prospectShortcutTargetTileKey,
      exploreShortcutTargetTileKey: widget.exploreShortcutTargetTileKey,
      buildImprovementShortcutTargetTileKey:
          widget.buildImprovementShortcutTargetTileKey,
    );
  }

  List<Unit> _scopedCivilianUnits(
    List<Unit> units, {
    required String? tileScopeTileKey,
    required bool explorerOnly,
    required bool builderOnly,
  }) {
    final tileScopeActive =
        tileScopeTileKey != null && tileScopeTileKey.isNotEmpty;
    if (!tileScopeActive && !explorerOnly && !builderOnly) {
      return units;
    }
    return [
      for (final u in units)
        if ((!tileScopeActive ||
                projectedCivilianTileKey(
                      unit: u,
                      playerId: u.ownerId,
                      orders: widget.currentOrders,
                    ) ==
                    tileScopeTileKey) &&
            (!explorerOnly || _isExplorerUnit(u)) &&
            (!builderOnly || _isBuilderUnit(u)))
          u,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final provinceNames = provinceNamesByPrefixedId(widget.game);
    final ownerIds = widget.civilianOwnerIds ?? {widget.humanPlayerId};
    final multiOwner = ownerIds.length > 1;
    final ow = civilianUnitsInRegionForOwners(
      widget.game.worldState.oldWorld.units,
      ownerIds,
      provinceNames,
      widget.currentOrders,
    );
    final nw = civilianUnitsInRegionForOwners(
      widget.game.worldState.newWorld.units,
      ownerIds,
      provinceNames,
      widget.currentOrders,
    );
    final scopeTileKey = widget.tileScopeTileKey;
    final tileScopeActive = scopeTileKey != null && scopeTileKey.isNotEmpty;
    final scopedOw = _scopedCivilianUnits(
      ow,
      tileScopeTileKey: scopeTileKey,
      explorerOnly: widget.explorerOnly,
      builderOnly: widget.builderOnly,
    );
    final scopedNw = _scopedCivilianUnits(
      nw,
      tileScopeTileKey: scopeTileKey,
      explorerOnly: widget.explorerOnly,
      builderOnly: widget.builderOnly,
    );
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
            playerId: resolvedSelectedUnit.ownerId,
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
          onPressed: widget.readOnly
              ? null
              : () {
                  widget.bus.emit(const ClosePanelEvent());
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    widget.bus.emit(OpenDialogEvent(trainCiviliansDialogId));
                  });
                },
          enabled: !widget.readOnly,
          child: Text(l10n.common_train),
        ),
      ],
      hasContent: hasAny,
      listChildren: [
        ..._civilianListChildrenForRegion(
          regionId: 'oldWorld',
          units: scopedOw,
          multiOwner: multiOwner,
          game: widget.game,
          provinceNames: provinceNames,
          tileScopeActive: tileScopeActive,
          resolvedSelectedUnitId: resolvedSelectedUnitId,
          onSelectUnit: (id) => setState(() => _selectedUnitId = id),
        ),
        ..._civilianListChildrenForRegion(
          regionId: 'newWorld',
          units: scopedNw,
          multiOwner: multiOwner,
          game: widget.game,
          provinceNames: provinceNames,
          tileScopeActive: tileScopeActive,
          resolvedSelectedUnitId: resolvedSelectedUnitId,
          onSelectUnit: (id) => setState(() => _selectedUnitId = id),
        ),
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
