// Default-start GP peace target matrix rows (Refs #4310 Slice D).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'expand_phase_peace_matrix_target_decider_start_support.dart';

void registerExpandPeaceTargetDeciderDefaultStartCases() {
  runExpandPeaceTargetDeciderMatrixCases(
    'defaultStartGpPeaceTargets (truth table)',
    defaultStartGpPeaceTargets,
    <ExpandPeaceTargetDeciderMatrixCase>[
      ExpandPeaceTargetDeciderMatrixCase(
        name: 'not below quota -> empty (OW = quota)',
        owProvinces: const [
          Province(
            id: 'oldWorld|gp2_a',
            regionId: 'oldWorld',
            ownerId: kExpandPeaceMatrixGp2,
          ),
        ],
        players: kExpandPeaceMatrixDefaultGpRoster,
        tribes: const [Tribe(id: kExpandPeaceMatrixTribe1, displayName: 'T1')],
        playerId: kExpandPeaceMatrixGp1,
        ownOw: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [kExpandPeaceMatrixGp2],
        invadable: const ['oldWorld|gp2_a'],
        reason:
            'At quota the EXPAND default-start pivot is no longer in scope; the '
            'helper must return empty so the COLONIAL peace rules govern '
            'post-quota wars.',
      ),
      ExpandPeaceTargetDeciderMatrixCase(
        name: 'ownOw above ceiling with no uninvaded minor -> empty',
        owProvinces: const [
          Province(
            id: 'oldWorld|gp2_a',
            regionId: 'oldWorld',
            ownerId: kExpandPeaceMatrixGp2,
          ),
        ],
        players: kExpandPeaceMatrixDefaultGpRoster,
        tribes: const [Tribe(id: kExpandPeaceMatrixTribe1, displayName: 'T1')],
        playerId: kExpandPeaceMatrixGp1,
        ownOw: kStalledOldWorldProvinceThreshold,
        atWarWith: const [kExpandPeaceMatrixGp2],
        invadable: const ['oldWorld|gp2_a'],
        reason:
            'Without an uninvaded minor on the map the ceiling is 8 OW, so OW=9 '
            'must NOT engage the pivot — there is no minor front to pivot to.',
      ),
      ExpandPeaceTargetDeciderMatrixCase(
        name:
            'ownOw at ceiling WITH uninvaded minor -> non-blocker GPs returned',
        owProvinces: const [
          Province(
            id: 'oldWorld|m1_a',
            regionId: 'oldWorld',
            ownerId: kExpandPeaceMatrixMinor1,
          ),
        ],
        players: kExpandPeaceMatrixDefaultGpRoster,
        tribes: const [Tribe(id: kExpandPeaceMatrixTribe1, displayName: 'T1')],
        minorNations: const [
          MinorNation(id: kExpandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        playerId: kExpandPeaceMatrixGp1,
        ownOw: kStalledOldWorldProvinceThreshold,
        atWarWith: const [kExpandPeaceMatrixGp2],
        invadable: const ['oldWorld|m1_a'],
        expected: const [kExpandPeaceMatrixGp2],
        reason:
            'With an uninvaded minor on the map the ceiling extends to 9 OW and '
            'the lone non-blocker GP must be returned; the only invadable OW is '
            'minor-owned so the frontier is not GP-only and the blocker is null.',
      ),
      ExpandPeaceTargetDeciderMatrixCase(
        name: '!gpOnlyFrontier -> blocker null -> all GPs returned',
        owProvinces: const [
          Province(
            id: 'oldWorld|gp2_a',
            regionId: 'oldWorld',
            ownerId: kExpandPeaceMatrixGp2,
          ),
          Province(
            id: 'oldWorld|m1_a',
            regionId: 'oldWorld',
            ownerId: kExpandPeaceMatrixMinor1,
          ),
        ],
        players: kExpandPeaceMatrixDefaultGpRoster,
        tribes: const [Tribe(id: kExpandPeaceMatrixTribe1, displayName: 'T1')],
        minorNations: const [
          MinorNation(id: kExpandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        playerId: kExpandPeaceMatrixGp1,
        ownOw: kObserverDefaultStartOldWorldProvincesPerGp + 1,
        atWarWith: const [kExpandPeaceMatrixGp2, kExpandPeaceMatrixGp3],
        invadable: const ['oldWorld|gp2_a', 'oldWorld|m1_a'],
        expected: const [kExpandPeaceMatrixGp2, kExpandPeaceMatrixGp3],
        reason:
            'When the frontier mixes GP and minor owners no GP qualifies as the '
            'blocker (the minor pivot is available), so every at-war GP is peaced '
            'in ascending factionId order.',
      ),
      ExpandPeaceTargetDeciderMatrixCase(
        name:
            'gpOnlyFrontier with multiple GPs at war -> only blocker excluded',
        owProvinces: const [
          Province(
            id: 'oldWorld|gp2_a',
            regionId: 'oldWorld',
            ownerId: kExpandPeaceMatrixGp2,
          ),
        ],
        players: kExpandPeaceMatrixDefaultGpRoster,
        tribes: const [Tribe(id: kExpandPeaceMatrixTribe1, displayName: 'T1')],
        playerId: kExpandPeaceMatrixGp1,
        ownOw: kObserverDefaultStartOldWorldProvincesPerGp + 1,
        atWarWith: const [kExpandPeaceMatrixGp2, kExpandPeaceMatrixGp3],
        invadable: const ['oldWorld|gp2_a'],
        expected: const [kExpandPeaceMatrixGp3],
        reason:
            'On a GP-only frontier the blocker (gp2) holds the only winnable OW '
            'front and must be preserved; remaining GP wars (gp3) are peaced.',
      ),
      ExpandPeaceTargetDeciderMatrixCase(
        name: 'non-GP factions filtered out of returned list',
        owProvinces: const [
          Province(
            id: 'oldWorld|m1_a',
            regionId: 'oldWorld',
            ownerId: kExpandPeaceMatrixMinor1,
          ),
        ],
        players: kExpandPeaceMatrixDefaultGpRoster,
        tribes: const [Tribe(id: kExpandPeaceMatrixTribe1, displayName: 'T1')],
        minorNations: const [
          MinorNation(id: kExpandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        playerId: kExpandPeaceMatrixGp1,
        ownOw: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [kExpandPeaceMatrixGp2, kExpandPeaceMatrixTribe1],
        invadable: const ['oldWorld|m1_a'],
        expected: const [kExpandPeaceMatrixGp2],
        reason:
            'Tribes and minors are not Great Powers; the helper is the GP arm of '
            'the EXPAND default-start peace pivot and must pass non-GP factions '
            'through to their own sibling helpers.',
      ),
      ExpandPeaceTargetDeciderMatrixCase(
        name: 'empty atWarWith -> empty',
        owProvinces: const [
          Province(
            id: 'oldWorld|gp2_a',
            regionId: 'oldWorld',
            ownerId: kExpandPeaceMatrixGp2,
          ),
        ],
        players: kExpandPeaceMatrixDefaultGpRoster,
        tribes: const [Tribe(id: kExpandPeaceMatrixTribe1, displayName: 'T1')],
        playerId: kExpandPeaceMatrixGp1,
        ownOw: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [],
        invadable: const ['oldWorld|gp2_a'],
        reason:
            'Empty `atWarWith` means there is nothing to peace, even at default '
            'start size — the helper must not synthesize new peace targets out '
            'of the player roster.',
      ),
      ExpandPeaceTargetDeciderMatrixCase(
        name: 'atWarWith returned in ascending factionId order',
        owProvinces: const [
          Province(
            id: 'oldWorld|gp1_a',
            regionId: 'oldWorld',
            ownerId: kExpandPeaceMatrixGp1,
          ),
        ],
        players: kExpandPeaceMatrixDefaultGpRoster,
        tribes: const [Tribe(id: kExpandPeaceMatrixTribe1, displayName: 'T1')],
        playerId: kExpandPeaceMatrixGp1,
        ownOw: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [
          kExpandPeaceMatrixGp4,
          kExpandPeaceMatrixGp2,
          kExpandPeaceMatrixGp3,
        ],
        expected: const [
          kExpandPeaceMatrixGp2,
          kExpandPeaceMatrixGp3,
          kExpandPeaceMatrixGp4,
        ],
        reason:
            'The helper must sort returned faction ids ascending so downstream '
            'order generation is deterministic for a fixed seed.',
      ),
      ExpandPeaceTargetDeciderMatrixCase(
        name: 'identical inputs produce identical peace target list',
        owProvinces: const [
          Province(
            id: 'oldWorld|gp2_a',
            regionId: 'oldWorld',
            ownerId: kExpandPeaceMatrixGp2,
          ),
        ],
        players: kExpandPeaceMatrixDefaultGpRoster,
        tribes: const [Tribe(id: kExpandPeaceMatrixTribe1, displayName: 'T1')],
        playerId: kExpandPeaceMatrixGp1,
        ownOw: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [
          kExpandPeaceMatrixGp2,
          kExpandPeaceMatrixGp3,
          kExpandPeaceMatrixGp4,
        ],
        invadable: const ['oldWorld|gp2_a'],
        expected: const [kExpandPeaceMatrixGp3, kExpandPeaceMatrixGp4],
        reason:
            'On a GP-only frontier (gp2 owns the sole invadable OW) the blocker '
            'gp2 is excluded; the remaining GP wars resolve to the deterministic '
            'ascending list.',
      ),
    ],
  );

  // --- quotaMetFutileBelowQuotaGpPeaceTargets (default 4-GP + minor1 + ---
  // --- tribe1 roster, gp1, explicit invadable frontier). ---
}
