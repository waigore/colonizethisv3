/// Spy / pending-cost trade scenario Game builders for orchestrator pins
/// (Refs #3122 / #3834 / #3972).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_orchestrator_quota_consts.dart';

/// Refs #3122 pending-cost trade recompute orchestrator fixture.
Game buildOrchestratorPendingCostTradeScenarioGame({
  required int treasury,
  required Stockpile stockpile,
  String id = 'g-3122-orchestrator-pending-cost',
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 30),
      oldWorld: RegionData(
        provinces: <Province>[
          for (final provinceId in kGp1OwProvincesBelowQuota)
            Province(
              id: provinceId,
              regionId: 'oldWorld',
              ownerId: kOrchestratorGp1NationId,
            ),
          const Province(
            id: kOrchestratorOwMinorProvince,
            regionId: 'oldWorld',
            ownerId: kOrchestratorMinorId,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: <Province>[]),
      armies: const <Army>[
        Army(
          id: 'home_a',
          ownerId: kOrchestratorGp1NationId,
          regionId: 'oldWorld',
          stationedProvinceId: kOrchestratorOwHomeProvince,
          regimentUnitIds: <String>[],
          isHomeArmy: true,
        ),
      ],
    ),
    players: <Player>[
      Player(
        id: kOrchestratorGp1NationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'napoleon',
        capitalProvinceId: kOrchestratorOwHomeProvince,
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 5),
        treasury: treasury,
      ),
    ],
    minorNations: const <MinorNation>[
      MinorNation(id: kOrchestratorMinorId, displayName: 'Minor One'),
    ],
    overtureStates: const <OvertureState>[
      OvertureState(
        gpId: kOrchestratorGp1NationId,
        targetId: kOrchestratorMinorId,
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kOrchestratorGp1NationId,
        factionId2: kOrchestratorMinorId,
        state: RelationState.atWar,
        score: -100,
      ),
    ],
    worldMarketState: WorldMarketState.withDefaultPrices(const <String, int>{
      'timber': 20,
      'iron': 20,
      'fabric': 10,
      'wool': 50,
      'cotton': 50,
    }),
  );
}

/// Refs #3834 Spy civilian-work orchestrator wiring fixture.
Game buildOrchestratorSpyPhaseWiringScenarioGame({
  required String id,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 30),
      oldWorld: RegionData(
        provinces: const <Province>[
          Province(
            id: kOrchestratorSpyOwnProvince,
            regionId: 'oldWorld',
            ownerId: kOrchestratorGp1NationId,
          ),
        ],
        units: <Unit>[
          Unit(
            id: kOrchestratorSpyUnitId,
            type: kUnitTypeSpy,
            ownerId: kOrchestratorGp1NationId,
            locationProvinceId: kOrchestratorSpyOwnProvince,
            tileKey: kOrchestratorSpyCounterSpyTile,
          ),
        ],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: const <String, Map<String, String>>{
        kOrchestratorGp1NationId: <String, String>{
          kOrchestratorSpyCounterSpyTile: 'fullyVisible',
        },
      },
      tileKeysByRegionAndProvince: const <String, Map<String, List<String>>>{
        'oldWorld': <String, List<String>>{
          kOrchestratorSpyOwnProvince: <String>[
            kOrchestratorSpyCounterSpyTile,
          ],
        },
      },
    ),
    players: const <Player>[
      Player(
        id: kOrchestratorGp1NationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'victoria',
        capitalProvinceId: kOrchestratorSpyOwnProvince,
      ),
    ],
  );
}

