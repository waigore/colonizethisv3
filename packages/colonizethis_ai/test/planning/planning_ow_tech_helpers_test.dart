// Unit tests for `planning_ow_tech_helpers.dart` (Refs #3941 topic split).
// Pins tech-steal posture, own-OW projections, and mutual-exhausted GP gates.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        isBelowObserverConquestQuota,
        isStalledOldWorldExpansion,
        kMutualExhaustedGpRegimentMax,
        kMutualExhaustedGpStalemateMinOw,
        kMutualExhaustedGpTreasuryMax,
        kObserverConquestMinOwProvincesPerGp,
        kStalledOldWorldProvinceThreshold;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/planning_ow_tech_helpers_test_support.dart';
import 'planning_ow_tech_helpers_tail_cases.dart';

const String _gp1 = planningOwTechHelpersGp1;
const String _gp2 = planningOwTechHelpersGp2;
const String _gp3 = planningOwTechHelpersGp3;
const String _gpExhausted = planningOwTechHelpersGpExhausted;

AIWorldSnapshot _snapshotWithOwnOw(int oldWorldProvincesOwned) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: const ThreatSummary(atWarWith: []),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(oldWorldProvincesOwned: oldWorldProvincesOwned),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('unlockedTechCount (Refs #3793)', () {
    test('counts only true-flagged techs; null/empty map is 0', () {
      expect(
        unlockedTechCount(
          const Player(id: _gp1, displayName: 'GP1', isHuman: false),
        ),
        0,
      );
      expect(
        unlockedTechCount(
          const Player(
            id: _gp1,
            displayName: 'GP1',
            isHuman: false,
            techUnlocked: {'a': true, 'b': true, 'c': false},
          ),
        ),
        2,
      );
    });
  });

  group('isPursuingTechStealPosture (Refs #3793, AC4c)', () {
    test('true when a rival GP leads by at least the deficit', () {
      // gp1 owns 2 techs; gp2 owns 4 → lead 2 >= deficit 1 → posture.
      final game = planningOwTechHelpersGameWithTechs({_gp1: 2, _gp2: 4, _gp3: 1});
      expect(isPursuingTechStealPosture(game, _gp1), isTrue);
    });

    test('true at exactly the default deficit (lead of 1)', () {
      final game = planningOwTechHelpersGameWithTechs({_gp1: 3, _gp2: 4});
      expect(isPursuingTechStealPosture(game, _gp1), isTrue);
    });

    test('false when the active GP leads or is tied with every rival', () {
      // gp1 is the most advanced; no rival leads it.
      final leadGame = planningOwTechHelpersGameWithTechs({_gp1: 5, _gp2: 4, _gp3: 2});
      expect(isPursuingTechStealPosture(leadGame, _gp1), isFalse);
      // Parity with the top rival → lead 0 < deficit 1 → no posture.
      final tiedGame = planningOwTechHelpersGameWithTechs({_gp1: 4, _gp2: 4});
      expect(isPursuingTechStealPosture(tiedGame, _gp1), isFalse);
    });

    test('false when there are no rival Great Powers', () {
      final game = planningOwTechHelpersGameWithTechs({_gp1: 0});
      expect(isPursuingTechStealPosture(game, _gp1), isFalse);
    });

    test('false for an unknown active player id', () {
      final game = planningOwTechHelpersGameWithTechs({_gp1: 1, _gp2: 9});
      expect(isPursuingTechStealPosture(game, 'nobody'), isFalse);
    });

    test('ignores minor nations and tribes (not Player rivals)', () {
      // Only gp1 is a Player; minors/tribes carry no tech state and are not
      // rivals, so a lone GP is never behind.
      final game = planningOwTechHelpersGameWithTechs({_gp1: 0});
      expect(isPursuingTechStealPosture(game, _gp1), isFalse);
    });

    test('deterministic for fixed inputs', () {
      final game = planningOwTechHelpersGameWithTechs({_gp1: 1, _gp2: 5});
      final a = isPursuingTechStealPosture(game, _gp1);
      final b = isPursuingTechStealPosture(game, _gp1);
      expect(a, isTrue);
      expect(b, a);
    });
  });

  group('isOwnOldWorldExpansionStalled (Refs #3717)', () {
    test('true inside the stalled OW band (0 < ow <= threshold)', () {
      expect(isOwnOldWorldExpansionStalled(_snapshotWithOwnOw(1)), isTrue);
      expect(
        isOwnOldWorldExpansionStalled(
          _snapshotWithOwnOw(kStalledOldWorldProvinceThreshold),
        ),
        isTrue,
      );
    });

    test('false at zero OW and above the stall band (negative cases)', () {
      expect(isOwnOldWorldExpansionStalled(_snapshotWithOwnOw(0)), isFalse);
      expect(
        isOwnOldWorldExpansionStalled(
          _snapshotWithOwnOw(kStalledOldWorldProvinceThreshold + 1),
        ),
        isFalse,
      );
    });

    test('matches isStalledOldWorldExpansion(ownOw) across a range', () {
      for (var ow = 0; ow <= kStalledOldWorldProvinceThreshold + 3; ow++) {
        expect(
          isOwnOldWorldExpansionStalled(_snapshotWithOwnOw(ow)),
          isStalledOldWorldExpansion(ow),
          reason: 'mismatch for ownOw=$ow',
        );
      }
    });
  });

  group('isOwnOldWorldBelowConquestQuota (Refs #3717)', () {
    test('true below the observer conquest quota', () {
      expect(isOwnOldWorldBelowConquestQuota(_snapshotWithOwnOw(0)), isTrue);
      expect(
        isOwnOldWorldBelowConquestQuota(
          _snapshotWithOwnOw(kObserverConquestMinOwProvincesPerGp - 1),
        ),
        isTrue,
      );
    });

    test('false at and above the quota (boundary negative cases)', () {
      expect(
        isOwnOldWorldBelowConquestQuota(
          _snapshotWithOwnOw(kObserverConquestMinOwProvincesPerGp),
        ),
        isFalse,
      );
      expect(
        isOwnOldWorldBelowConquestQuota(
          _snapshotWithOwnOw(kObserverConquestMinOwProvincesPerGp + 5),
        ),
        isFalse,
      );
    });
  });

  registerPlanningOwTechHelpersTailCases();
}
