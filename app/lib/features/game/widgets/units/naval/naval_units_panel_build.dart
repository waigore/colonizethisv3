import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import '../../../../../core/services/app_event_bus_panel_nav.dart';
import '../../panels/tree_builders/naval_tree_builder.dart';
import '../shared/base_units_panel.dart';
import 'naval_units_panel.dart';
import 'naval_units_panel_list.dart';
import 'naval_units_panel_state_base.dart';
import 'naval_units_panel_support_combine.dart';
import 'naval_units_panel_support_combine_home.dart';
import 'naval_units_panel_support_dialogs.dart';

mixin NavalUnitsPanelBuild
    on
        BaseUnitsPanelState<NavalUnitsPanel>,
        NavalUnitsPanelStateBase,
        NavalUnitsPanelCombineHome,
        NavalUnitsPanelCombine,
        NavalUnitsPanelDialogs,
        NavalUnitsPanelList {
  Widget buildNavalUnitsPanel(BuildContext context) {
    final l10n = appL10n(context);
    final tileScopeActive =
        widget.tileScopeTileKey != null && widget.tileScopeTileKey!.isNotEmpty;
    final tree = buildNavalTree(
      widget.game,
      widget.humanPlayerId,
      widget.topology,
      widget.draftOrders,
      l10n,
      tileMapByRegion: widget.tileMapByRegion,
      topologyByRegion: widget.topologyByRegion,
      locationScopeKeyFilter: widget.locationScopeKey,
    );
    final flat = flattenNavalTree(tree);
    visibleScopedFleetIds.clear();
    visibleScopedFleetIds.addAll(flat.map((row) => row.fleetId));
    final hasAny = tree.any(
      (group) => group.homeFleet != null || group.locations.isNotEmpty,
    );
    final canCombine = !widget.readOnly && canCombineSelection(flat);
    final readOnly = widget.readOnly;

    // Header actions render as compact **primary** pills
    // (`CtActionTextButton(primary: true)`) per SPEC/ui/naval-units-panel.md
    // § Header actions and issue #3514 owner decisions #5 / #15. The optional
    // tile-scope pill (and its 4px spacer) leads the shared select-all +
    // Combine cluster assembled by `BaseUnitsPanelState.buildUnitsPanel`.
    final panel = buildUnitsPanel(
      title: tileScopeActive
          ? l10n.naval_units_title_tile
          : l10n.naval_units_title,
      leadingActions: [
        if (tileScopeActive)
          CtActionTextButton(
            primary: true,
            enabled: widget.tileScopeTileKey!.isNotEmpty,
            onPressed: () {
              final key = widget.tileScopeTileKey!;
              widget.bus.closePanelThenEmit(
                OpenMapTileDetailEvent(tileKey: key),
              );
            },
            label: l10n.civilian_units_tile,
          ),
        if (tileScopeActive && hasAny && flat.isNotEmpty)
          const SizedBox(width: 4),
      ],
      trailingActions: [
        CtActionTextButton(
          primary: true,
          onPressed: readOnly ? null : openTrainDialog,
          enabled: !readOnly,
          label: l10n.common_train,
        ),
      ],
      showCombineCluster: hasAny && flat.isNotEmpty && !readOnly,
      selectableIds: fleetSelectionIds(flat),
      selectAllTooltip: l10n.naval_units_selectAllFleets,
      deselectAllTooltip: l10n.naval_units_deselectAllFleets,
      combineLabel: l10n.common_combine,
      canCombine: canCombine,
      onSelectAll: () => onHeaderSelectAllTapped(flat),
      onCombine: () => performCombine(flat),
      hasContent: hasAny,
      listChildren: navalListChildren(
        tree: tree,
        l10n: l10n,
        readOnly: readOnly,
      ),
      emptyMessage: l10n.naval_units_empty,
    );
    if (kCtE2EEnabled) {
      updateCtE2eNavalPanelSnapshotIfEnabled(
        CtE2eNavalPanelSnapshot(
          game: widget.game,
          humanPlayerId: widget.humanPlayerId,
          topology: widget.topology,
          draftOrders: widget.draftOrders,
          tileMapByRegion: widget.tileMapByRegion,
          topologyByRegion: widget.topologyByRegion,
          locationScopeKey: widget.locationScopeKey,
          initialSelectedFleetId: widget.initialSelectedFleetId,
          tileScopeTileKey: widget.tileScopeTileKey,
        ),
      );
      return KeyedSubtree(key: kCtE2ENavalPanelRootKey, child: panel);
    }
    return panel;
  }
}
