// Pins the first-naval-transport bootstrap helpers and orchestrator
// build-pick behaviour (Refs #2847 Phase 3).
//
// When the treasury-recovery resource-need override is active and the GP
// owns no cargo-capable ships, `_appendEconomyBuildOrders` must keep ship
// candidates in the build pick and suppress the regiment-only
// `militaryRebuildCrisis` short-circuit so `pickBuildOrder` can select a
// cargo hull under `CargoPreference.strongCargo`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../domain_planner_test_fake_api.dart';

const String _nationId = 'gp3';
const String _owHome = 'oldWorld|gp3_0';
const String _owMinor = 'oldWorld|minor1';

const List<BuildUnitOrder> _galleonAndGrenadiers = [
  BuildUnitOrder(
    unitType: 'galleon',
    isMilitary: false,
    spawnProvinceId: _owHome,
  ),
  BuildUnitOrder(
    unitType: 'grenadiers',
    isMilitary: true,
    spawnProvinceId: _owHome,
  ),
];

Game _bootstrapGame({int treasury = 0, List<Fleet> fleets = const []}) {
  return Game(
    id: 'g-2847-first-naval-bootstrap',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 20),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|gp3_$i',
              regionId: 'oldWorld',
              ownerId: _nationId,
            ),
          const Province(
            id: _owMinor,
            regionId: 'oldWorld',
            ownerId: 'minor1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      fleets: fleets,
      armies: const [
        Army(
          id: 'home_gp3',
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: _owHome,
          regimentUnitIds: const [],
          isHomeArmy: true,
        ),
      ],
    ),
    players: [
      Player(
        id: _nationId,
        displayName: 'GP3',
        isHuman: false,
        treasury: treasury,
        capitalProvinceId: _owHome,
      ),
    ],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Minor'),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: _nationId,
        factionId2: 'minor1',
        state: RelationState.atWar,
        score: -100,
      ),
    ],
  );
}

AIWorldSnapshot _bootstrapSnapshot({int treasury = 0}) {
  return AIWorldSnapshot(
    playerId: _nationId,
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: 7,
      invadableProvinceIdsSorted: [_owMinor],
      provincesToVictory: 20,
    ),
    colonial: const ColonialSummary(
      newWorldProvincesOwned: 0,
      invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
    ),
    economy: EconomySummary(treasury: treasury),
    threats: const ThreatSummary(atWarWith: ['minor1']),
    opportunities: const OpportunitySummary(),
    relations: const {},
  );
}

void main() {
  group('resolvePhaseFirstNavalTransportBootstrapActive (Refs #2847)', () {
    test('override active with zero fleets returns true', () {
      final game = _bootstrapGame();
      const expandPlan = ExpandEconomyPlan(
        forceCheapestRegimentBuild: true,
        boostTreasuryRecoveryCargo: true,
      );
      expect(
        resolvePhaseFirstNavalTransportBootstrapActive(
          game: game,
          snapshot: _bootstrapSnapshot(),
          expandEconomyPlan: expandPlan,
          playerId: _nationId,
        ),
        isTrue,
      );
    });

    test('inactive when GP already owns a cargo-capable hull', () {
      final game = _bootstrapGame(
        fleets: [
          Fleet(
            id: 'fleet_1',
            ownerId: _nationId,
            regionId: 'oldWorld',
            inPortAtProvinceId: _owHome,
            ships: const [
              ShipInstance(id: 'ship_1', typeId: 'galleon'),
            ],
          ),
        ],
      );
      const expandPlan = ExpandEconomyPlan(
        forceCheapestRegimentBuild: false,
        boostTreasuryRecoveryCargo: true,
      );
      expect(
        resolvePhaseFirstNavalTransportBootstrapActive(
          game: game,
          snapshot: _bootstrapSnapshot(),
          expandEconomyPlan: expandPlan,
          playerId: _nationId,
        ),
        isFalse,
      );
    });

    test(
      'resource-need override inactive when treasury is non-zero '
      '(Refs #2924)',
      () {
        const expandPlan = ExpandEconomyPlan(
          forceCheapestRegimentBuild: false,
          boostTreasuryRecoveryCargo: true,
        );
        expect(
          resolvePhaseNwTreasuryRecoveryResourceNeedOverrideActive(
            snapshot: _bootstrapSnapshot(treasury: 50),
            expandEconomyPlan: expandPlan,
          ),
          isFalse,
        );
      },
    );

    test(
      'bootstrap stays active below regiment threshold after partial '
      'seller credits (Refs #2924 Path F)',
      () {
        final game = _bootstrapGame(treasury: 500);
        const expandPlan = ExpandEconomyPlan(
          forceCheapestRegimentBuild: true,
          boostTreasuryRecoveryCargo: true,
        );
        expect(
          resolvePhaseFirstNavalTransportBootstrapActive(
            game: game,
            snapshot: _bootstrapSnapshot(treasury: 500),
            expandEconomyPlan: expandPlan,
            playerId: _nationId,
          ),
          isTrue,
          reason:
              'Partial world-market credits must not end cargo bootstrap '
              'before the GP owns a cargo-capable hull.',
        );
      },
    );

    test(
      'bootstrap active for mid-below-quota zero-NW GP without '
      'boostTreasuryRecoveryCargo (Refs #2924 Path F)',
      () {
        final game = _bootstrapGame(treasury: 5000);
        const expandPlan = ExpandEconomyPlan.defaultPlan;
        expect(
          resolvePhaseFirstNavalTransportBootstrapActive(
            game: game,
            snapshot: _bootstrapSnapshot(treasury: 5000),
            expandEconomyPlan: expandPlan,
            playerId: _nationId,
          ),
          isTrue,
        );
      },
    );

    test(
      'bootstrap active for mid-below-quota zero-NW GP even above '
      'regiment threshold (Refs #2924 Path F)',
      () {
        final game = _bootstrapGame(treasury: 5000);
        const expandPlan = ExpandEconomyPlan(
          forceCheapestRegimentBuild: true,
          boostTreasuryRecoveryCargo: true,
        );
        expect(
          resolvePhaseFirstNavalTransportBootstrapActive(
            game: game,
            snapshot: _bootstrapSnapshot(treasury: 5000),
            expandEconomyPlan: expandPlan,
            playerId: _nationId,
          ),
          isTrue,
          reason:
              'gp3–gp6 band must prioritise the first cargo hull before '
              'spending high starting treasury on regiments.',
        );
      },
    );

    test(
      'bootstrap inactive once treasury reaches regiment threshold '
      '(Refs #2924)',
      () {
        final threshold = cheapestRegimentBuildTreasuryCost();
        final game = _bootstrapGame(treasury: threshold);
        const expandPlan = ExpandEconomyPlan(
          forceCheapestRegimentBuild: false,
          boostTreasuryRecoveryCargo: true,
        );
        expect(
          resolvePhaseFirstNavalTransportBootstrapActive(
            game: game,
            snapshot: _bootstrapSnapshot(treasury: threshold),
            expandEconomyPlan: expandPlan,
            playerId: _nationId,
          ),
          isTrue,
          reason: 'At exactly threshold, mid-below-quota zero-NW band still '
              'requires cargo until a hull exists.',
        );
      },
    );

    test(
      'bootstrap inactive above threshold for at-quota GP (Refs #2924)',
      () {
        final game = Game(
          id: 'g-at-quota',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 20),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 10; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: _nationId,
                  ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: _nationId,
              displayName: 'GP3',
              isHuman: false,
              treasury: 5000,
              capitalProvinceId: 'oldWorld|gp3_0',
            ),
          ],
        );
        const expandPlan = ExpandEconomyPlan(
          forceCheapestRegimentBuild: false,
          boostTreasuryRecoveryCargo: true,
        );
        final snapshot = AIWorldSnapshot(
          playerId: _nationId,
          conquest: const ConquestSummary(
            oldWorldProvincesOwned: 10,
            invadableProvinceIdsSorted: [],
            provincesToVictory: 20,
          ),
          colonial: const ColonialSummary(newWorldProvincesOwned: 0),
          economy: const EconomySummary(treasury: 5000),
          threats: const ThreatSummary(),
          opportunities: const OpportunitySummary(),
          relations: const {},
        );
        expect(
          resolvePhaseFirstNavalTransportBootstrapActive(
            game: game,
            snapshot: snapshot,
            expandEconomyPlan: expandPlan,
            playerId: _nationId,
          ),
          isFalse,
        );
      },
    );
  });

  group(
    'runDomainPlannersWithOutcome build pick under bootstrap (Refs #2847)',
    () {
      test(
        'bootstrap selects a cargo ship instead of regiment-only crisis pick',
        () {
          final game = _bootstrapGame();
          const topology = MapTopology(nodes: [], edges: []);
          final view = buildPlayerView(game, topology, _nationId);
          final snapshot = _bootstrapSnapshot();

          const phasePlan = PhasePlanOutcome(
            phase: ObserverGoalPhase.expand,
            expandEconomyPlan: ExpandEconomyPlan(
              forceCheapestRegimentBuild: true,
              boostTreasuryRecoveryCargo: true,
            ),
            priorityWeights: PhasePriorityWeights(
              oldWorldConquest: 0.95,
              newWorldAcquisition: kPhasePriorityNwTreasuryRecoveryFloor,
              oldWorldCivilian: 0.90,
              newWorldCivilian: 0.10,
            ),
          );

          const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
            work: [],
            build: _galleonAndGrenadiers,
            move: [],
            research: [],
            navalMove: [],
            navalMission: [],
          );

          final outcome = runDomainPlannersWithOutcome(
            game: game,
            topology: topology,
            nationId: _nationId,
            view: view,
            snapshot: snapshot,
            config: const AIConfig(
              leaderId: 'henry',
              personalityId: 'navigator',
              hiddenAgendaId: 'navigator',
            ),
            primaryGoal: StrategicGoal.expand,
            seeds: AISeedBundle.fromTurnSeed(2847001),
            suggestionAPI: fakeApi,
            economyPlan: const EconomyPlan(
              productionAssignments: [],
              cargoPreference: CargoPreference.strongCargo,
            ),
            phasePlan: phasePlan,
          );

          final builds =
              outcome.orders.buildUnitOrdersByPlayerId[_nationId] ?? const [];
          expect(builds, isNotEmpty);
          expect(
            builds.first.unitType,
            'galleon',
            reason:
                'Under first-naval-transport bootstrap the build pick must '
                'prefer a cargo-capable ship over the regiment-only '
                'militaryRebuildCrisis short-circuit.',
          );
        },
      );
    },
  );
}
