// Expected plain-text lines for NavalUnitsPanel. Mirrors
// app/lib/features/game/widgets/naval_units_panel.dart for e2e.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/utils/naval_tree_builder.dart'
    show FleetRow, NavalTreeLocationNode, buildNavalTree, flattenNavalTree;
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_region_label.dart';
import 'package:colonizethis_app/l10n/app_localizations.dart';

String _fleetSummaryLine(FleetRow row, AppLocalizations l10n) {
  final parts = <String>[];
  parts.add(l10n.naval_units_totalShips(row.totalShips));
  parts.add(l10n.naval_units_strength(row.strength.toStringAsFixed(1)));
  if (row.warshipCount > 0) {
    parts.add(l10n.naval_units_warships(row.warshipCount));
  }
  if (row.merchantCount > 0) {
    parts.add(l10n.naval_units_merchants(row.merchantCount));
  }
  return parts.join(' · ');
}

String _collapsedSubtitle(FleetRow row, AppLocalizations l10n) {
  final base =
      '${row.locationLabel}\n${l10n.naval_units_mission(row.missionLabel)} · ${_fleetSummaryLine(row, l10n)}';
  if (row.draftNavalMoveLine != null) {
    return '$base\n${row.draftNavalMoveLine}';
  }
  return base;
}

void _addFleetRowTexts({
  required List<String> out,
  required FleetRow row,
  required AppLocalizations l10n,
  required bool expansionTilesOpen,
}) {
  out.add(row.label);
  out.add(_collapsedSubtitle(row, l10n));
  if (!expansionTilesOpen) {
    return;
  }
  if (row.shipCountsByType.isEmpty) {
    out.add(l10n.naval_units_noShipsInFleet);
  } else {
    for (final entry in row.shipCountsByType.entries) {
      out.add(
        l10n.naval_units_shipTypeCount(
          shipTypeDisplayName(entry.key),
          entry.value,
        ),
      );
    }
  }
  out.add(l10n.naval_units_strength(row.strength.toStringAsFixed(1)));
  out.add(
    row.isHomeFleet
        ? l10n.naval_units_cargoCapacity(row.cargoCapacity)
        : l10n.naval_units_cargoCapacityIfAssigned(row.cargoCapacity),
  );
  if (!row.isHomeFleet) {
    out.add(l10n.common_move);
  }
  out.add(l10n.common_split);
}

/// In-order [Text.data] for [NavalUnitsPanel] preorder traversal.
///
/// When [fleetTilesExpanded] is false, only texts from collapsed [ExpansionTile]
/// headers match typical widget preorder. When true, includes expanded children
/// (ship breakdown, Move/Split) in panel order.
List<String> navalUnitsPanelExpectedTexts(
  CtE2eNavalPanelSnapshot snap,
  AppLocalizations l10n, {
  required bool fleetTilesExpanded,
}) {
  final tree = buildNavalTree(
    snap.game,
    snap.humanPlayerId,
    snap.topology,
    snap.draftOrders,
    l10n,
    tileMapByRegion: snap.tileMapByRegion,
    topologyByRegion: snap.topologyByRegion,
    locationScopeKeyFilter: snap.locationScopeKey,
  );
  final flat = flattenNavalTree(tree);
  final hasAny = tree.any(
    (group) => group.homeFleet != null || group.locations.isNotEmpty,
  );

  final out = <String>[];
  final tileScope =
      snap.tileScopeTileKey != null && snap.tileScopeTileKey!.isNotEmpty;
  out.add(tileScope ? l10n.naval_units_title_tile : l10n.naval_units_title);
  if (tileScope) {
    out.add(l10n.civilian_units_tile);
  }
  if (hasAny && flat.isNotEmpty) {
    out.add(l10n.common_combine);
  }

  if (!hasAny) {
    out.add(l10n.naval_units_empty);
    return out;
  }

  for (final group in tree) {
    out.add(unitsPanelRegionLabel(group.regionId));
    if (group.homeFleet != null) {
      _addFleetRowTexts(
        out: out,
        row: group.homeFleet!,
        l10n: l10n,
        expansionTilesOpen: fleetTilesExpanded,
      );
    }
    for (final NavalTreeLocationNode loc in group.locations) {
      out.add(
        l10n.locationSection_headerLine(
          loc.displayLabel,
          unitsPanelRegionLabel(loc.regionId),
        ),
      );
      for (final row in loc.fleets) {
        _addFleetRowTexts(
          out: out,
          row: row,
          l10n: l10n,
          expansionTilesOpen: fleetTilesExpanded,
        );
      }
    }
  }
  return out;
}
