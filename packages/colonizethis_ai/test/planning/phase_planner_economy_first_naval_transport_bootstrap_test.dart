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
import 'phase_planner_economy_first_naval_transport_bootstrap_tail_cases.dart';

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

void main() {
  group('resolvePhaseFirstNavalTransportBootstrapActive (Refs #2847)', () {
    test('override active with zero fleets returns true', () {
      final game = economyNavalBootstrapGame();
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
      final game = economyNavalBootstrapGame(
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
        final game = economyNavalBootstrapGame(treasury: 500);
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
        final game = economyNavalBootstrapGame(treasury: 5000);
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
    },
  );

  registerPhasePlannerEconomyFirstNavalTransportBootstrapTailCases();
}
