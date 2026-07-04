// coverage:ignore-file
// E2E test fixture; exercised only by integration_test scenarios (which do not
// run in `flutter test test/`). Pulled into the test isolate's import graph by
// `app/integration_test/e2e_test_shared_panel_text_match.dart` (Refs #2336);
// excluded from the app coverage gate using the same convention as
// `app/lib/widgetbook/catalog*.dart`.
// Expected plain-text lines for NavalUnitsPanel. Mirrors
// app/lib/features/game/widgets/naval_units_panel.dart for e2e.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/utils/naval_tree_builder.dart'
    show FleetRow, NavalTreeLocationNode, buildNavalTree, flattenNavalTree;
import 'package:colonizethis_app/features/game/utils/region_labels.dart';
import 'package:colonizethis_app/l10n/l10n.dart';

String _roleLabelFor(String typeId, AppLocalizations l10n) {
  final stats = NavalStatsCatalog.get(typeId);
  return stats.cargoHold > 0
      ? l10n.naval_units_compositionRoleMerchant
      : l10n.naval_units_compositionRoleWarship;
}

void _addFleetRowTexts({
  required List<String> out,
  required FleetRow row,
  required AppLocalizations l10n,
  required bool expansionTilesOpen,
}) {
  out.add(row.label);
  if (row.isHomeFleet) {
    // Mockup `.home-tag` rendered next to the name (Refs #2866 S8 R26).
    out.add(l10n.naval_units_homeFleetChip);
  }
  // UnitsEntityActionRow (dense): trailing Move / Split / Locate cluster.
  // Whether Move and Split render as `Icon + Text` or collapse to icon-only
  // depends on the realized action-cluster width vs `_denseIconOnlyBreakpoint`
  // (70 dp × actionCount), which is HOST-DEPENDENT: at the narrow macOS test
  // host the cluster falls below the breakpoint (icon-only, no `Text` labels in
  // preorder), but on the wider Linux desktop integration host (real
  // `IntegrationTestWidgetsFlutterBinding`, 1280-wide view at DPR 1.0) the
  // cluster clears the breakpoint and Move/Split render their text labels.
  // This mirror is the canonical ICON-ONLY variant and never emits the Move /
  // Split labels; the integration assertion normalizes those two host-width-
  // dependent labels out of the collected texts via
  // `e2eExpectNavalPanelMatchesE2eSnapshot`'s `ignoreActualTexts` so it passes
  // on both hosts. Locate is always icon-only. Refs #2866 S8 R25 + R27; GitHub
  // #2336 panel-text mirror drift / AC6.
  out.add(row.locationLabel);
  out.add(l10n.naval_units_mission(row.missionLabel));
  if (row.draftNavalMoveLine != null) {
    out.add(row.draftNavalMoveLine!);
  }
  if (!expansionTilesOpen) {
    return;
  }
  if (row.shipCountsByType.isEmpty) {
    out.add(l10n.naval_units_noShipsInFleet);
  } else {
    // Mockup `.fleet-row .f-expanded table` columns are `Type | ×Count |
    // Role` per ship type (Refs #2866 S8 R29).
    for (final entry in row.shipCountsByType.entries) {
      out.add(shipTypeDisplayName(entry.key));
      out.add(l10n.naval_units_compositionCount(entry.value));
      out.add(_roleLabelFor(entry.key, l10n));
    }
  }
  // Home Fleet only: `Cargo capacity: X holds` between the table and the
  // summary band; non-home fleets no longer render a cargo line in the
  // expanded view.
  if (row.isHomeFleet) {
    out.add(l10n.naval_units_cargoCapacityHolds(row.cargoCapacity));
  }
  // Single-line composition summary + retained Strength line.
  out.add(
    l10n.naval_units_compositionSummary(
      row.totalShips,
      row.warshipCount,
      row.merchantCount,
    ),
  );
  out.add(l10n.naval_units_strength(row.strength.toStringAsFixed(1)));
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
    // Region section headers render via RegionSectionHeader -> CtSectionLabel
    // under the dark editorial-monocle theme (Refs #2859 R9 / #2866 S1-S3),
    // which upper-cases the label (`Text(text.toUpperCase())`). The location
    // header line below (LocationSectionHeader) renders as-is, so only the
    // region group header is upper-cased here (Refs #2336).
    out.add(regionDisplayLabel(group.regionId).toUpperCase());
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
          regionDisplayLabel(loc.regionId),
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
