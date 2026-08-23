// Pins the first-naval-transport bootstrap helpers and orchestrator
// build-pick behaviour (Refs #2847 Phase 3).
//
// When the treasury-recovery resource-need override is active and the GP
// owns no cargo-capable ships, `_appendEconomyBuildOrders` must keep ship
// candidates in the build pick and suppress the regiment-only
// `militaryRebuildCrisis` short-circuit so `pickBuildOrder` can select a
// cargo hull under `CargoPreference.strongCargo`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/economy_satellite_test_support.dart';

const String _nationId = economyNavalBootstrapNationId;
const String _owHome = economyNavalBootstrapHome;
const String _owMinor = economyNavalBootstrapMinor;

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

void registerPhasePlannerEconomyFirstNavalTransportBootstrapTailCases() {

  group('resolvePhaseFirstNavalTransportBootstrapActive (Refs #2847)', () {
    test(
      'bootstrap active for mid-below-quota zero-NW GP even above '
      'regiment threshold (Refs #2924 Path F)',
      () {
        final game = economyNavalBootstrapGame(treasury: 5000);
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
        final game = economyNavalBootstrapGame(treasury: threshold);
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
          final game = economyNavalBootstrapGame();
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
            DomainPlannerInput(
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
              options: OrchestratorOptions(phasePlan: phasePlan),
            ),
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
