// Scenario table + fixtures for province Offer Peace standing goldens (Refs #4479).

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TerrainType;
import 'package:colonizethis_logic/colonizethis_logic.dart' show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';

import 'golden_capture_harness.dart';

const String provinceOfferPeaceGoldenHumanId = 'gp1';
const String provinceOfferPeaceGoldenRivalId = 'gp2';
const String provinceOfferPeaceGoldenProvinceId = 'oldWorld|p1';
const String provinceOfferPeaceGoldenTileKey = 'oldWorld|p1|0|0';

class ProvinceOfferPeaceStandingGoldenCase {
  const ProvinceOfferPeaceStandingGoldenCase({
    required this.name,
    required this.goldenFile,
    required this.showStanding,
    this.atWar = false,
    this.showAlliance = false,
    this.showOfferPeace = false,
    this.offerPeaceEnabled = false,
    this.offerPeacePending = false,
  });

  final String name;
  final String goldenFile;
  final bool showStanding;
  final bool atWar;
  final bool showAlliance;
  final bool showOfferPeace;
  final bool offerPeaceEnabled;
  final bool offerPeacePending;
}

const List<ProvinceOfferPeaceStandingGoldenCase>
    provinceOfferPeaceStandingWideCases = [
  ProvinceOfferPeaceStandingGoldenCase(
    name: 'at war Offer Peace enabled',
    goldenFile: 'goldens/province_overlay_owner_standing_at_war.png',
    showStanding: true,
    atWar: true,
    showOfferPeace: true,
    offerPeaceEnabled: true,
  ),
  ProvinceOfferPeaceStandingGoldenCase(
    name: 'at war Offer Peace pending',
    goldenFile: 'goldens/province_overlay_owner_standing_pending.png',
    showStanding: true,
    atWar: true,
    showOfferPeace: true,
    offerPeaceEnabled: true,
    offerPeacePending: true,
  ),
  ProvinceOfferPeaceStandingGoldenCase(
    name: 'at peace',
    goldenFile: 'goldens/province_overlay_owner_standing_at_peace.png',
    showStanding: true,
  ),
  ProvinceOfferPeaceStandingGoldenCase(
    name: 'at peace ALLIANCE',
    goldenFile: 'goldens/province_overlay_owner_standing_alliance.png',
    showStanding: true,
    showAlliance: true,
  ),
  ProvinceOfferPeaceStandingGoldenCase(
    name: 'hidden own',
    goldenFile: 'goldens/province_overlay_owner_standing_hidden.png',
    showStanding: false,
  ),
];

Game provinceOfferPeaceGoldenRivalOwnedGame() {
  return Game(
    id: 'g_standing_golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceOfferPeaceGoldenProvinceId,
            regionId: 'oldWorld',
            ownerId: provinceOfferPeaceGoldenRivalId,
            townTileKey: provinceOfferPeaceGoldenTileKey,
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {provinceOfferPeaceGoldenTileKey: 'grain'},
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          provinceOfferPeaceGoldenProvinceId: [provinceOfferPeaceGoldenTileKey],
        },
      },
      playerVisibilityByTile: {
        provinceOfferPeaceGoldenHumanId: {
          provinceOfferPeaceGoldenTileKey: 'fullyVisible',
        },
      },
    ),
    players: const [
      Player(
        id: provinceOfferPeaceGoldenHumanId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: '',
        treasury: 5000,
      ),
      Player(
        id: provinceOfferPeaceGoldenRivalId,
        displayName: 'Rival',
        isHuman: false,
        capitalProvinceId: provinceOfferPeaceGoldenProvinceId,
      ),
    ],
    minorNations: const [],
    tribes: const [],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: provinceOfferPeaceGoldenHumanId,
        factionId2: provinceOfferPeaceGoldenRivalId,
        state: RelationState.atWar,
        score: 20,
      ),
    ],
  );
}

RegionMapViewData provinceOfferPeaceGoldenRegion() {
  return const RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
    height: 1,
    cellSize: 16,
    cells: [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainType: TerrainType.hills,
        ownerFactionId: provinceOfferPeaceGoldenRivalId,
        provinceDisplayName: 'Rival Province',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: [],
    portMarkers: [],
    factionColors: {},
    greatPowerFactionIds: {
      provinceOfferPeaceGoldenHumanId,
      provinceOfferPeaceGoldenRivalId,
    },
    terrainColors: {},
    provincePoliticalOwnerByPrefixedProvinceId: {
      provinceOfferPeaceGoldenProvinceId: provinceOfferPeaceGoldenRivalId,
    },
  );
}

Future<void> pumpProvinceOfferPeaceStandingGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size surface,
  required Size overlaySize,
  required ProvinceOfferPeaceStandingGoldenCase c,
}) async {
  await configureGoldenSurface(tester, size: surface);
  configureGoldenView(tester, physicalSize: surface, devicePixelRatio: 1.0);
  final game = provinceOfferPeaceGoldenRivalOwnedGame();
  await tester.pumpWidget(
    wrapGoldenBoundary(
      boundaryKey: boundaryKey,
      includeLocalizations: true,
      child: SizedBox(
        width: overlaySize.width,
        height: overlaySize.height,
        child: ProvinceSeaZoneDetailOverlay(
          game: game,
          region: provinceOfferPeaceGoldenRegion(),
          displayId: provinceOfferPeaceGoldenProvinceId,
          selectedTileKey: provinceOfferPeaceGoldenTileKey,
          humanPlayerId: provinceOfferPeaceGoldenHumanId,
          playerView: buildPlayerView(
            game,
            const MapTopology(),
            provinceOfferPeaceGoldenHumanId,
          ),
          omniscientDetail: true,
          showOwnerStanding: c.showStanding,
          ownerStandingAtWar: c.atWar,
          showOwnerAllianceBadge: c.showAlliance,
          showOfferPeaceControl: c.showOfferPeace,
          offerPeaceEnabled: c.offerPeaceEnabled,
          offerPeacePending: c.offerPeacePending,
          onOfferPeaceTap: () {},
          onClose: () {},
        ),
      ),
    ),
  );
  await pumpForGolden(tester);
}
