// coverage:ignore-file
// E2E test fixture; exercised only by integration_test scenarios (which do not
// run in `flutter test test/`). Pulled into the test isolate's import graph by
// `app/integration_test/e2e_test_shared_panel_text_match.dart` (Refs #2336);
// excluded from the app coverage gate using the same convention as
// `app/lib/widgetbook/catalog*.dart`.
// Expected plain-text lines for CivilianUnitsPanel (bottom sheet). Mirrors
// app/lib/features/game/widgets/units/civilian/civilian_units_panel.dart for e2e.
// If drift fails tests, align this file with the panel widget.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_sort.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/region_labels.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

part 'civilian_units_panel_e2e_expected_lines_assigned.dart';
part 'civilian_units_panel_e2e_expected_lines_rows.dart';

/// In-order [Text.data] strings for [CivilianUnitsPanel] preorder traversal.
List<String> civilianUnitsPanelExpectedTexts(
  CtE2eCivilianPanelSnapshot snap,
  AppLocalizations l10n,
) {
  final game = snap.game;
  final humanPlayerId = snap.humanPlayerId;
  final provinceNames = provinceNamesByPrefixedId(game);
  final ow = civilianUnitsInRegion(
    game.worldState.oldWorld.units,
    humanPlayerId,
    provinceNames,
    snap.currentOrders,
  );
  final nw = civilianUnitsInRegion(
    game.worldState.newWorld.units,
    humanPlayerId,
    provinceNames,
    snap.currentOrders,
  );
  final scopeTileKey = snap.tileScopeTileKey;
  final tileScopeActive = scopeTileKey != null && scopeTileKey.isNotEmpty;
  var scopedOw = ow;
  var scopedNw = nw;
  if (tileScopeActive) {
    scopedOw = ow
        .where(
          (u) =>
              projectedCivilianTileKey(
                unit: u,
                playerId: humanPlayerId,
                orders: snap.currentOrders,
              ) ==
              scopeTileKey,
        )
        .toList();
    scopedNw = nw
        .where(
          (u) =>
              projectedCivilianTileKey(
                unit: u,
                playerId: humanPlayerId,
                orders: snap.currentOrders,
              ) ==
              scopeTileKey,
        )
        .toList();
  }
  final allScoped = <Unit>[...scopedOw, ...scopedNw];
  final resolvedSelected =
      snap.resolvedSelectedUnitId ??
      (allScoped.isNotEmpty ? allScoped.first.id : null);

  final out = <String>[];
  out.add(
    tileScopeActive
        ? l10n.civilian_units_title_tile
        : l10n.civilian_units_title,
  );
  if (tileScopeActive) {
    out.add(l10n.civilian_units_tile);
  }
  out.add(l10n.common_train);

  final hasAny = scopedOw.isNotEmpty || scopedNw.isNotEmpty;
  if (!hasAny) {
    out.add(l10n.civilian_units_empty);
    return out;
  }

  if (scopedOw.isNotEmpty) {
    // Region section headers render via RegionSectionHeader -> CtSectionLabel
    // under the dark editorial-monocle theme (Refs #2859 R9 / #2866 S1-S3),
    // which upper-cases the label (`Text(text.toUpperCase())`). The expected
    // mirror must upper-case to match the rendered Text.data (Refs #2336).
    out.add(regionDisplayLabel('oldWorld').toUpperCase());
    for (final u in scopedOw) {
      _addUnitRowTexts(
        out: out,
        game: game,
        unit: u,
        humanPlayerId: humanPlayerId,
        currentOrders: snap.currentOrders,
        provinceNames: provinceNames,
        l10n: l10n,
        isTileScope: tileScopeActive,
        resolvedSelectedUnitId: resolvedSelected,
        projectedTileKey: projectedCivilianTileKey(
          unit: u,
          playerId: humanPlayerId,
          orders: snap.currentOrders,
        ),
      );
    }
  }
  if (scopedNw.isNotEmpty) {
    // Upper-cased to match the RegionSectionHeader -> CtSectionLabel render
    // (see oldWorld header above; Refs #2859 R9 / #2866 S1-S3 / #2336).
    out.add(regionDisplayLabel('newWorld').toUpperCase());
    for (final u in scopedNw) {
      _addUnitRowTexts(
        out: out,
        game: game,
        unit: u,
        humanPlayerId: humanPlayerId,
        currentOrders: snap.currentOrders,
        provinceNames: provinceNames,
        l10n: l10n,
        isTileScope: tileScopeActive,
        resolvedSelectedUnitId: resolvedSelected,
        projectedTileKey: projectedCivilianTileKey(
          unit: u,
          playerId: humanPlayerId,
          orders: snap.currentOrders,
        ),
      );
    }
  }
  return out;
}
