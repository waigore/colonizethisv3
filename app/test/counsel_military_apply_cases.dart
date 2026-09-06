// Fixtures for military counsel apply unit tests (Refs #4734 Slice E, #4307).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show ArmyMovePickerDestination;

import 'panel_fixtures/train.dart';
import 'panel_test_fixtures.dart';

const kCounselMilitaryApplyPlayerId = kPanelTestHumanPlayerId;
const kCounselMilitaryApplyUnitType = 'peasant_levies';
const kCounselMilitaryInvadeFrom = 'oldWorld|p_from';
const kCounselMilitaryInvadeDest = 'oldWorld|p_invade';
const kCounselMilitaryInvadeRivalId = 'gp2';
const kCounselMilitaryInvadeArmyId = 'a_move';

MapTopology counselMilitaryApplyTrainTopology() => const MapTopology(
      nodes: [
        TopologyNode(
          id: 'oldWorld|cap',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'oldWorld|p2',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: [TopologyEdge(id1: 'oldWorld|cap', id2: 'oldWorld|p2')],
    );

MapTopology counselMilitaryInvadeTopology() => const MapTopology(
      nodes: [
        TopologyNode(
          id: kCounselMilitaryInvadeFrom,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: kCounselMilitaryInvadeDest,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: [
        TopologyEdge(id1: kCounselMilitaryInvadeFrom, id2: kCounselMilitaryInvadeDest),
      ],
    );

Game counselMilitaryInvadeGame({bool homeArmy = false}) {
  return buildPanelTestGame(
    players: [
      Player(
        id: kCounselMilitaryApplyPlayerId,
        displayName: 'Human',
        isHuman: true,
      ),
      const Player(
        id: kCounselMilitaryInvadeRivalId,
        displayName: 'Rival',
        isHuman: false,
      ),
    ],
    oldWorldProvinces: const [
      Province(
        id: kCounselMilitaryInvadeFrom,
        regionId: 'oldWorld',
        ownerId: kCounselMilitaryApplyPlayerId,
        displayName: 'Origin',
      ),
      Province(
        id: kCounselMilitaryInvadeDest,
        regionId: 'oldWorld',
        ownerId: kCounselMilitaryInvadeRivalId,
        displayName: 'Enemy Border',
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'u1',
        type: 'musketeers',
        ownerId: kCounselMilitaryApplyPlayerId,
        locationProvinceId: kCounselMilitaryInvadeFrom,
      ),
    ],
    armies: [
      Army(
        id: kCounselMilitaryInvadeArmyId,
        ownerId: kCounselMilitaryApplyPlayerId,
        regionId: 'oldWorld',
        stationedProvinceId: kCounselMilitaryInvadeFrom,
        regimentUnitIds: const ['u1'],
        isHomeArmy: homeArmy,
      ),
    ],
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        kCounselMilitaryInvadeFrom: ['oldWorld|p_from|0|0'],
        kCounselMilitaryInvadeDest: ['oldWorld|p_invade|0|0'],
      },
    },
    playerVisibilityByTile: const {
      kCounselMilitaryApplyPlayerId: {
        'oldWorld|p_from|0|0': 'fullyVisible',
        'oldWorld|p_invade|0|0': 'fullyVisible',
      },
    },
  );
}

MilitaryCounselRecommendation counselMilitaryInvadeRecommendation() {
  return MilitaryCounselRecommendation(
    recommendationId:
        'invade:$kCounselMilitaryInvadeArmyId:$kCounselMilitaryInvadeDest',
    kind: MilitaryCounselRecommendationKind.invade,
    rankScore: 5,
    briefReasonKey: MilitaryCounselReasonKey.declareWarInvasion,
    detailReasonKeys: const [MilitaryCounselReasonKey.declareWarInvasion],
    isHighlight: true,
    armyId: kCounselMilitaryInvadeArmyId,
    destinationProvinceId: kCounselMilitaryInvadeDest,
    destinationProvinceLabel: 'Enemy Border',
    ownerFactionId: kCounselMilitaryInvadeRivalId,
    requiresDeclareWar: true,
    invasionIntel: const MilitaryCounselInvasionIntelSummary(
      intelLevel: MilitaryCounselInvasionIntelLevel.unknown,
    ),
  );
}

ArmyMovePickerDestination counselMilitaryInvasionDestination({
  bool requiresWar = true,
}) {
  return ArmyMovePickerDestination(
    fullProvinceId: kCounselMilitaryInvadeDest,
    provinceLabel: 'Enemy Border',
    regionId: 'oldWorld',
    ownerFactionId: kCounselMilitaryInvadeRivalId,
    isPlayerOwned: false,
    requiresDeclareWarOnConfirm: requiresWar,
  );
}
