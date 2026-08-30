// Shared scenario Games + host re-exports for civilian panel suites.
//
// The three part files previously inlined ~14 near-identical `Game(` builders
// (OW Alpha province + one/few civilians). Named factories below keep each
// part file's assertions local while scenario wiring lives once (Refs #4021).
//
// SPEC: SPEC/ui/civilian-units-panel.md, SPEC/program/repo-lint.md.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'panel_fixtures/core.dart';

export 'civilian_units_panel_pending_fixtures.dart';
export 'civilian_units_panel_spy_fixtures.dart';
export 'diplomacy_panel_test_support.dart'
    show CivilianPanelBusDialogHost, buildCivilianPanel;
export 'panel_fixtures/civilian.dart' show buildCivilianPanelTestGame;

/// Idle civilian [Unit] at [tileKey] in [provinceId].
Unit civilianIdleUnit({
  required String id,
  required String type,
  required String ownerId,
  required String provinceId,
  required String tileKey,
}) {
  return Unit(
    id: id,
    type: type,
    ownerId: ownerId,
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
}

/// OW civilian mini-game: one province (plus optional extras) and [units].
Game buildCivilianOwUnitsGame({
  required String id,
  String humanId = 'h1',
  String humanDisplayName = 'Human',
  String provinceId = 'oldWorld|p1',
  String provinceDisplayName = 'Alpha',
  int? fortLevel,
  required List<Unit> units,
  List<Province> extraProvinces = const [],
  Map<String, String> resourceByTileKey = const {},
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {},
}) {
  return buildPanelTestGame(
    id: id,
    players: [
      Player(id: humanId, displayName: humanDisplayName, isHuman: true),
    ],
    oldWorldProvinces: [
      Province(
        id: provinceId,
        regionId: 'oldWorld',
        displayName: provinceDisplayName,
        fortLevel: fortLevel ?? 0,
      ),
      ...extraProvinces,
    ],
    oldWorldUnits: units,
    resourceByTileKey: resourceByTileKey,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
  );
}

/// Explorer + builder (or builder + explorer) on one OW tile for shortcut modes.
Game buildCivilianExplorerBuilderShortcutGame({
  required String id,
  String humanId = 'h1',
  String tileKey = 'oldWorld|p1|0|0',
  bool builderFirst = false,
}) {
  const provinceId = 'oldWorld|p1';
  final explorer = civilianIdleUnit(
    id: 'e1',
    type: kUnitTypeExplorer,
    ownerId: humanId,
    provinceId: provinceId,
    tileKey: tileKey,
  );
  final builder = civilianIdleUnit(
    id: 'b1',
    type: kUnitTypeBuilder,
    ownerId: humanId,
    provinceId: provinceId,
    tileKey: tileKey,
  );
  return buildCivilianOwUnitsGame(
    id: id,
    humanId: humanId,
    units: builderFirst ? [builder, explorer] : [explorer, builder],
  );
}

/// Engineer + builder on one OW tile for build-road shortcut mode.
Game buildCivilianEngineerBuilderShortcutGame({
  required String id,
  String humanId = 'h1',
  String tileKey = 'oldWorld|p1|0|0',
  bool engineerFirst = false,
}) {
  const provinceId = 'oldWorld|p1';
  final engineer = civilianIdleUnit(
    id: 'e_eng',
    type: kUnitTypeEngineer,
    ownerId: humanId,
    provinceId: provinceId,
    tileKey: tileKey,
  );
  final builder = civilianIdleUnit(
    id: 'b1',
    type: kUnitTypeBuilder,
    ownerId: humanId,
    provinceId: provinceId,
    tileKey: tileKey,
  );
  return buildCivilianOwUnitsGame(
    id: id,
    humanId: humanId,
    units: engineerFirst ? [engineer, builder] : [builder, engineer],
  );
}

/// Merchant + builder on one OW tile for purchase-land shortcut mode.
Game buildCivilianMerchantBuilderShortcutGame({
  required String id,
  String humanId = 'h1',
  String tileKey = 'oldWorld|p1|0|0',
  bool merchantFirst = false,
}) {
  const provinceId = 'oldWorld|p1';
  final merchant = civilianIdleUnit(
    id: 'm1',
    type: kUnitTypeMerchant,
    ownerId: humanId,
    provinceId: provinceId,
    tileKey: tileKey,
  );
  final builder = civilianIdleUnit(
    id: 'b1',
    type: kUnitTypeBuilder,
    ownerId: humanId,
    provinceId: provinceId,
    tileKey: tileKey,
  );
  return buildCivilianOwUnitsGame(
    id: id,
    humanId: humanId,
    units: merchantFirst ? [merchant, builder] : [builder, merchant],
  );
}
