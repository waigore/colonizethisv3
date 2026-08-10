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

    test('matches isBelowObserverConquestQuota(ownOw) across a range', () {
      for (var ow = 0; ow <= kObserverConquestMinOwProvincesPerGp + 3; ow++) {
        expect(
          isOwnOldWorldBelowConquestQuota(_snapshotWithOwnOw(ow)),
          isBelowObserverConquestQuota(ow),
          reason: 'mismatch for ownOw=$ow',
        );
      }
    });
  });

  group('oldWorldProvinceLeadOver (Refs #3717)', () {
    test('positive when the faction owns more than the own OW count', () {
      final game = planningOwTechHelpersGameOwning({_gp2: 5});
      expect(
        oldWorldProvinceLeadOver(
          game: game,
          snapshot: _snapshotWithOwnOw(3),
          factionId: _gp2,
        ),
        2,
      );
    });

    test('negative (deficit view) when the faction owns fewer', () {
      final game = planningOwTechHelpersGameOwning({_gp2: 1});
      expect(
        oldWorldProvinceLeadOver(
          game: game,
          snapshot: _snapshotWithOwnOw(4),
          factionId: _gp2,
        ),
        -3,
      );
    });

    test('zero when the faction owns exactly the own OW count', () {
      final game = planningOwTechHelpersGameOwning({_gp2: 4});
      expect(
        oldWorldProvinceLeadOver(
          game: game,
          snapshot: _snapshotWithOwnOw(4),
          factionId: _gp2,
        ),
        0,
      );
    });

    test('counts only the queried faction (other owners excluded)', () {
      final game = planningOwTechHelpersGameOwning({_gp2: 6, _gp3: 9});
      expect(
        oldWorldProvinceLeadOver(
          game: game,
          snapshot: _snapshotWithOwnOw(2),
          factionId: _gp2,
        ),
        4,
      );
    });

    test('unowned faction yields a pure deficit (count 0)', () {
      final game = planningOwTechHelpersGameOwning({_gp2: 3});
      expect(
        oldWorldProvinceLeadOver(
          game: game,
          snapshot: _snapshotWithOwnOw(5),
          factionId: _gp3,
        ),
        -5,
      );
    });

    test('deterministic for fixed inputs', () {
      final game = planningOwTechHelpersGameOwning({_gp2: 7});
      final snapshot = _snapshotWithOwnOw(3);
      final a = oldWorldProvinceLeadOver(
        game: game,
        snapshot: snapshot,
        factionId: _gp2,
      );
      final b = oldWorldProvinceLeadOver(
        game: game,
        snapshot: snapshot,
        factionId: _gp2,
      );
      expect(a, 4);
      expect(b, a);
    });
  });

  group('mutualExhaustedGpStalemateSideQualifies (Refs #3717)', () {
    // 8 OW provinces sits in the late-stalled "8-9 plateau": at/above the
    // min-OW floor, below the observer quota (10), and inside the stall band
    // (<= 9), so it satisfies the three OW gates simultaneously.
    final int qualifyingOw = kMutualExhaustedGpStalemateMinOw;

    test('true at the min-OW / treasury / regiment exhaustion boundary', () {
      final game = planningOwTechHelpersGameWithExhaustedGp(
        treasury: kMutualExhaustedGpTreasuryMax,
        regiments: kMutualExhaustedGpRegimentMax,
      );
      expect(
        mutualExhaustedGpStalemateSideQualifies(
          game: game,
          factionId: _gpExhausted,
          ow: qualifyingOw,
        ),
        isTrue,
      );
    });

    test('false below the min-OW floor (even while stalled and below quota)', () {
      final game = planningOwTechHelpersGameWithExhaustedGp();
      expect(
        mutualExhaustedGpStalemateSideQualifies(
          game: game,
          factionId: _gpExhausted,
          ow: kMutualExhaustedGpStalemateMinOw - 1,
        ),
        isFalse,
      );
    });

    test('false at the observer conquest quota (not below quota / not stalled)', () {
      final game = planningOwTechHelpersGameWithExhaustedGp();
      expect(
        mutualExhaustedGpStalemateSideQualifies(
          game: game,
          factionId: _gpExhausted,
          ow: kObserverConquestMinOwProvincesPerGp,
        ),
        isFalse,
      );
    });

    test('false when treasury exceeds the exhaustion ceiling', () {
      final game = planningOwTechHelpersGameWithExhaustedGp(
        treasury: kMutualExhaustedGpTreasuryMax + 1,
      );
      expect(
        mutualExhaustedGpStalemateSideQualifies(
          game: game,
          factionId: _gpExhausted,
          ow: qualifyingOw,
        ),
        isFalse,
      );
    });

    test('false when standing regiments exceed the exhaustion ceiling', () {
      final game = planningOwTechHelpersGameWithExhaustedGp(
        regiments: kMutualExhaustedGpRegimentMax + 1,
      );
      expect(
        mutualExhaustedGpStalemateSideQualifies(
          game: game,
          factionId: _gpExhausted,
          ow: qualifyingOw,
        ),
        isFalse,
      );
    });

    test('false for a faction id that does not resolve to a Great Power', () {
      final game = planningOwTechHelpersGameWithExhaustedGp(
        treasury: kMutualExhaustedGpTreasuryMax,
        regiments: kMutualExhaustedGpRegimentMax,
      );
      expect(
        mutualExhaustedGpStalemateSideQualifies(
          game: game,
          factionId: 'ghost',
          ow: qualifyingOw,
        ),
        isFalse,
      );
    });
  });
}
