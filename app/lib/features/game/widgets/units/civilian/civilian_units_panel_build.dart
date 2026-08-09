import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show projectedCivilianTileKey;
import 'package:colonizethis_world/colonizethis_world.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import '../../../../../core/services/app_event_bus_panel_nav.dart';
import '../../../../../core/services/app_event_handler/app_event_handler_scope.dart';
import '../../../../../providers/games_provider.dart';
import '../shared/units_panel_shell.dart';
import 'civilian_units_panel.dart';
import 'civilian_units_panel_list.dart';
import 'civilian_units_panel_state_base.dart';
import 'civilian_units_sort.dart';

mixin CivilianUnitsPanelBuild
    on ConsumerState<CivilianUnitsPanel>, CivilianUnitsPanelStateBase, CivilianUnitsPanelList {
  Widget buildCivilianUnitsPanel(BuildContext context) {
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
    final scopedOw = scopedCivilianUnits(
      ow,
      tileScopeTileKey: scopeTileKey,
      explorerOnly: widget.explorerOnly,
      builderOnly: widget.builderOnly,
      engineerOnly: widget.engineerOnly,
      merchantOnly: widget.merchantOnly,
    );
    final scopedNw = scopedCivilianUnits(
      nw,
      tileScopeTileKey: scopeTileKey,
      explorerOnly: widget.explorerOnly,
      builderOnly: widget.builderOnly,
      engineerOnly: widget.engineerOnly,
      merchantOnly: widget.merchantOnly,
    );
    final hasAny = scopedOw.isNotEmpty || scopedNw.isNotEmpty;
    final allScopedUnits = <Unit>[...scopedOw, ...scopedNw];
    final selectedUnitId = this.selectedUnitId;
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
          CtActionTextButton(
            primary: true,
            enabled: headerTileKey != null && headerTileKey.isNotEmpty,
            onPressed: () {
              final key = headerTileKey;
              if (key == null || key.isEmpty) {
                return;
              }
              widget.bus.closePanelThenEmit(
                OpenMapTileDetailEvent(tileKey: key),
              );
            },
            label: l10n.civilian_units_tile,
          ),
        CtActionTextButton(
          primary: true,
          enabled: !widget.readOnly,
          onPressed: widget.readOnly
              ? null
              : () {
                  widget.bus.closePanelThenEmit(
                    OpenDialogEvent(trainCiviliansDialogId),
                  );
                },
          label: l10n.common_train,
        ),
      ],
      hasContent: hasAny,
      listChildren: [
        ...civilianListChildrenForRegion(
          regionId: kRegionOldWorld,
          units: scopedOw,
          multiOwner: multiOwner,
          game: widget.game,
          provinceNames: provinceNames,
          tileScopeActive: tileScopeActive,
          resolvedSelectedUnitId: resolvedSelectedUnitId,
          onSelectUnit: (id) => setState(() => this.selectedUnitId = id),
        ),
        ...civilianListChildrenForRegion(
          regionId: kRegionNewWorld,
          units: scopedNw,
          multiOwner: multiOwner,
          game: widget.game,
          provinceNames: provinceNames,
          tileScopeActive: tileScopeActive,
          resolvedSelectedUnitId: resolvedSelectedUnitId,
          onSelectUnit: (id) => setState(() => this.selectedUnitId = id),
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
