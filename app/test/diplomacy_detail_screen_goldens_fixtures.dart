// Fixtures for diplomacy detail screen goldens (Refs #3753 / #4734 Slice F).

import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_detail_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'golden_capture_harness.dart';

Widget diplomacyDetailGoldenHost({
  required Game game,
  required String humanPlayerId,
  required String factionId,
  required String factionDisplayName,
  required FactionKind kind,
  required Key boundaryKey,
  DiplomacyRelation? relation,
}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    center: false,
    useScaffold: false,
    includeLocalizations: true,
    wrapInProviderScope: true,
    child: DiplomacyDetailScreen(
      game: game,
      humanPlayerId: humanPlayerId,
      factionId: factionId,
      factionDisplayName: factionDisplayName,
      kind: kind,
      relation: relation ?? getRelation(game, humanPlayerId, factionId),
    ),
  );
}

Game diplomacyDetailGoldenColonyTribeGame() {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  final home = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'Home',
    ownerId: 'gp1',
  );
  final tribeProvince = Province(
    id: '$nw|t1prov',
    regionId: nw,
    displayName: 'Tribe Land',
    ownerId: 't1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 6),
    oldWorld: RegionData(provinces: [home], units: const []),
    newWorld: RegionData(provinces: [tribeProvince], units: const []),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  return Game(
    id: 'diplo-detail-golden-colony-tribe',
    worldState: world,
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    tribes: const [Tribe(id: 't1', displayName: 'Powhatan')],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 't1', score: 60),
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', score: 40),
    ],
    overtureStates: const [
      OvertureState(gpId: 'gp1', targetId: 't1', stage: OvertureStage.embassy),
    ],
    colonyStates: const [
      ColonyState(tribeId: 't1', colonyOfGpId: 'gp1', sinceTurn: 5),
    ],
    boycottStates: const [
      BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 6),
    ],
    diplomaticHistoryEvents: const [
      DiplomaticEvent(
        turn: 5,
        intraTurnIndex: 0,
        type: DiplomaticEventType.overtureAccepted,
        participants: {'gp1', 't1'},
        fromFactionId: 'gp1',
        toFactionId: 't1',
        overtureStage: OvertureStage.embassy,
      ),
    ],
  );
}

Game diplomacyDetailGoldenSubsidizedMinorGame() {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  const minorProvinceId = '$nw|m1prov';
  const tileA = '$minorProvinceId|0|0';
  const tileB = '$minorProvinceId|1|0';
  final home = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'Home',
    ownerId: 'gp1',
  );
  final minorProvince = Province(
    id: minorProvinceId,
    regionId: nw,
    displayName: 'Bavaria Coast',
    ownerId: 'm1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 8),
    oldWorld: RegionData(provinces: [home], units: const []),
    newWorld: RegionData(provinces: [minorProvince], units: const []),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
    purchasedTilesByTileKey: const {tileA: 'gp1', tileB: 'gp1'},
    tileKeysByRegionAndProvince: const {
      nw: {
        minorProvinceId: [tileA, tileB],
      },
    },
  );
  return Game(
    id: 'diplo-detail-golden-subsidized-minor',
    worldState: world,
    players: const [Player(id: 'gp1', displayName: 'Albion', isHuman: true)],
    minorNations: const [MinorNation(id: 'm1', displayName: 'Bavaria')],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'm1', score: 80),
    ],
    overtureStates: const [
      OvertureState(gpId: 'gp1', targetId: 'm1', stage: OvertureStage.embassy),
    ],
    subsidyStates: const [
      SubsidyState(payerId: 'gp1', targetId: 'm1', percent: 10),
    ],
    diplomaticHistoryEvents: const [
      DiplomaticEvent(
        turn: 7,
        intraTurnIndex: 0,
        type: DiplomaticEventType.subsidySet,
        participants: {'gp1', 'm1'},
        fromFactionId: 'gp1',
        toFactionId: 'm1',
        amount: 10,
      ),
    ],
  );
}
