// Shared fixtures and pump host for province draft-orders panel suites.
//
// `province_panel_draft_orders_test.dart` and
// `province_panel_draft_orders_part2_test.dart` previously duplicated
// `_pumpOverlayLayout`, region/game/player-view builders, and a raw
// `MaterialApp` overlay shell. Canonical home is this module (Refs #4035).
//
// SPEC: SPEC/program/repo-lint.md (approved harness modules).

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'app_shell_harness.dart';

const String kProvinceDraftOrdersRegionId = 'oldWorld';
const String kProvinceDraftOrdersLocalProvinceId = 'pDraft';
const String kProvinceDraftOrdersLocalDestProvinceId = 'pDest';
const String kProvinceDraftOrdersHumanId = 'gp1';

String get kProvinceDraftOrdersFullProvinceId =>
    '$kProvinceDraftOrdersRegionId|$kProvinceDraftOrdersLocalProvinceId';

String get kProvinceDraftOrdersFullDestProvinceId =>
    '$kProvinceDraftOrdersRegionId|$kProvinceDraftOrdersLocalDestProvinceId';

String provinceDraftOrdersTileKey(int x, int y) =>
    '$kProvinceDraftOrdersFullProvinceId|$x|$y';

const Player kProvinceDraftOrdersHumanPlayer = Player(
  id: kProvinceDraftOrdersHumanId,
  displayName: 'Human',
  isHuman: true,
  treasury: 0,
);

/// Bounded pumps only — avoid [pumpAndSettle] (animations / unbounded work).
Future<void> pumpProvinceDraftOrdersOverlayLayout(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

Province provinceDraftOrdersProvince({
  required String id,
  required String displayName,
  String? ownerId,
}) => Province(
  id: id,
  regionId: id.split('|').first,
  displayName: displayName,
  ownerId: ownerId,
);

RegionMapViewData provinceDraftOrdersRegion({
  TileVisibility visibility = TileVisibility.visible,
  Set<String> greatPowerFactionIds = const {kProvinceDraftOrdersHumanId},
}) {
  return RegionMapViewData(
    regionId: kProvinceDraftOrdersRegionId,
    width: 1,
    height: 1,
    cellSize: 32,
    cells: [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: kProvinceDraftOrdersLocalProvinceId,
        isSea: false,
        terrainTypeId: 'plains',
        visibility: visibility,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: greatPowerFactionIds,
    terrainColors: const {},
  );
}

PlayerView provinceDraftOrdersPlayerView({
  required String tileKey,
  VisibilityLevel visibility = VisibilityLevel.fullyVisible,
  Map<String, Province> provincesById = const {},
}) {
  return PlayerView(
    playerId: kProvinceDraftOrdersHumanId,
    player: kProvinceDraftOrdersHumanPlayer,
    ownUnitsById: const {},
    provincesById: provincesById,
    visibilityByTile: {tileKey: visibility},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

Game provinceDraftOrdersGame({
  required String id,
  required String tileKey,
  List<Unit> units = const [],
  List<Fleet> fleets = const [],
  List<Province>? oldWorldProvinces,
  RegionData? newWorld,
  Map<String, Map<String, int>>? spyRevealTurnsByPlayer,
  List<Player> players = const [kProvinceDraftOrdersHumanPlayer],
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces:
            oldWorldProvinces ??
            [
              provinceDraftOrdersProvince(
                id: kProvinceDraftOrdersFullProvinceId,
                displayName: 'DraftProv',
              ),
            ],
        units: units,
      ),
      newWorld: newWorld ?? const RegionData(),
      fleets: fleets,
      tileKeysByRegionAndProvince: {
        kProvinceDraftOrdersRegionId: {
          kProvinceDraftOrdersFullProvinceId: [tileKey],
        },
      },
      spyRevealTurnsByPlayer: spyRevealTurnsByPlayer ?? const {},
    ),
    players: players,
  );
}

/// Canonical [ProvinceSeaZoneDetailOverlay] host for draft-orders suites.
Future<void> pumpProvinceDraftOrdersOverlay(
  WidgetTester tester, {
  required Game game,
  required String tileKey,
  PlayerView? playerView,
  Orders draftOrders = const Orders(),
  TileVisibility regionVisibility = TileVisibility.visible,
  Set<String> greatPowerFactionIds = const {kProvinceDraftOrdersHumanId},
}) async {
  await tester.pumpWidget(
    buildAppShell(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      child: Scaffold(
        body: ProvinceSeaZoneDetailOverlay(
          game: game,
          region: provinceDraftOrdersRegion(
            visibility: regionVisibility,
            greatPowerFactionIds: greatPowerFactionIds,
          ),
          displayId: kProvinceDraftOrdersFullProvinceId,
          selectedTileKey: tileKey,
          humanPlayerId: kProvinceDraftOrdersHumanId,
          playerView:
              playerView ?? provinceDraftOrdersPlayerView(tileKey: tileKey),
          draftOrders: draftOrders,
        ),
      ),
    ),
  );
  await pumpProvinceDraftOrdersOverlayLayout(tester);
}
