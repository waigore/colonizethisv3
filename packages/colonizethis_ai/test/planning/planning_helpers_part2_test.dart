// Unit tests for `planning_helpers.dart` invadable-province ownership helpers
// (Refs #3717). Split out of `planning_helpers_test.dart` to keep each test
// file at or below the repo non-comment line limit
// (`repo.dart_file_non_comment_line_size`).
//
// Pins:
//   - `anyInvadableProvinceOwnedByMinor` — minor-owner presence scan over the
//     invadable frontier, `.any` short-circuit, absent/other-owner exclusion
//   - `anyInvadableProvinceOwnedByGreatPower` — GP-owner presence scan, same
//     short-circuit / exclusion contract
//   - `factionOwnsInvadableOldWorldProvince` — single-faction invadable-frontier
//     ownership scan, `.any` short-circuit, absent/other-owner exclusion
//   - `addInvadableProvinceMinorOwnersNotAtWar` — minor-owner collector skipping
//     unowned / non-minor / already-at-war provinces, set de-dup, pre-seeded set
//   - `mutualExhaustedGpStalemateSideQualifies` — per-side mutual-exhausted
//     below-quota GP stalemate qualification: min-OW floor, below-quota / stalled
//     bands, treasury / regiment exhaustion ceilings, unknown-faction exclusion
//   - `clampPhaseWeightUpperUnit` — `weight > 1.0 ? 1.0 : weight` upper-clamp:
//     caps above-ceiling weights, passes in-range / negative weights through,
//     and matches the inline ternary it replaces

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_ai/src/util/faction_query.dart'
    show isMinorFaction;
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        kMutualExhaustedGpRegimentMax,
        kMutualExhaustedGpStalemateMinOw,
        kMutualExhaustedGpTreasuryMax,
        kObserverConquestMinOwProvincesPerGp;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

Game _gameWithGps() {
  return Game(
    id: 'g-3717-planning-helpers-invadable',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(provinces: []),
      newWorld: const RegionData(provinces: []),
    ),
    players: const [
      Player(id: _gp1, displayName: 'GP1', isHuman: false),
      Player(id: _gp2, displayName: 'GP2', isHuman: false),
      Player(id: _gp3, displayName: 'GP3', isHuman: false),
    ],
    minorNations: const [MinorNation(id: _minor1, displayName: 'Minor1')],
    tribes: const [Tribe(id: _tribe1, displayName: 'Tribe1')],
  );
}

AIWorldSnapshot _snapshotWithInvadable(List<String> invadableProvinceIds) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: const ThreatSummary(atWarWith: []),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(invadableProvinceIdsSorted: invadableProvinceIds),
    economy: const EconomySummary(),
    relations: const {},
  );
}

const String _gpExhausted = 'gpExhausted';

// Single-Great-Power game whose treasury and standing-regiment totals are
// configurable so the mutual-exhausted side qualification can be probed at its
// economic / military exhaustion ceilings. `mutualExhaustedGpStalemateSideQualifies`
// reads the side's Old World count from its `ow` argument (not the game), so the
// fixture only has to back `Game.playerById` and `regimentCountForPlayer`.
Game _gameWithExhaustedGp({int treasury = 0, int regiments = 0}) {
  return Game(
    id: 'g-3717-mutual-exhausted-side',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(provinces: []),
      newWorld: const RegionData(provinces: []),
      armies: [
        Army(
          id: 'army-$_gpExhausted',
          ownerId: _gpExhausted,
          regionId: 'ow',
          stationedProvinceId: 'ow|home',
          regimentUnitIds: [for (var i = 0; i < regiments; i++) 'reg$i'],
        ),
      ],
    ),
    players: [
      Player(
        id: _gpExhausted,
        displayName: 'Exhausted GP',
        isHuman: false,
        treasury: treasury,
      ),
    ],
  );
}

void main() {
  group('anyInvadableProvinceOwnedByMinor (Refs #3717)', () {
    const String pA = 'provA';
    const String pB = 'provB';

    test('true when an invadable province is owned by a minor nation', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable([pA]);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: _minor1},
        ),
        isTrue,
      );
    });

    test('false when invadable provinces are owned only by GPs / tribes', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable([pA, pB]);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: _gp2, pB: _tribe1},
        ),
        isFalse,
      );
    });

    test('false when an invadable province owner is absent from the map', () {
      // Unowned / not-yet-mapped invadable province: lookup is null, no match.
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable([pA]);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {},
        ),
        isFalse,
      );
    });

    test('false when there are no invadable provinces', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable(const []);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: _minor1},
        ),
        isFalse,
      );
    });

    test('true when only a non-first invadable province is minor-owned', () {
      // The .any short-circuit must still find a minor owner that is not the
      // first scanned entry (GP first, minor second) -> deterministic true.
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable([pA, pB]);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: _gp2, pB: _minor1},
        ),
        isTrue,
      );
    });
  });

  group('anyInvadableProvinceOwnedByGreatPower (Refs #3717)', () {
    const String pA = 'provA';
    const String pB = 'provB';

    test('true when an invadable province is owned by a Great Power', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable([pA]);
      expect(
        anyInvadableProvinceOwnedByGreatPower(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: _gp2},
        ),
        isTrue,
      );
    });

    test(
      'false when invadable provinces are owned only by minors / tribes',
      () {
        final game = _gameWithGps();
        final snapshot = _snapshotWithInvadable([pA, pB]);
        expect(
          anyInvadableProvinceOwnedByGreatPower(
            game: game,
            snapshot: snapshot,
            provinceOwner: const {pA: _minor1, pB: _tribe1},
          ),
          isFalse,
        );
      },
    );

    test('false when an invadable province owner is absent from the map', () {
      // Unowned / not-yet-mapped invadable province: `?? ''` -> playerById null.
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable([pA]);
      expect(
        anyInvadableProvinceOwnedByGreatPower(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {},
        ),
        isFalse,
      );
    });

    test('false when there are no invadable provinces', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable(const []);
      expect(
        anyInvadableProvinceOwnedByGreatPower(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: _gp2},
        ),
        isFalse,
      );
    });

    test('true when only a non-first invadable province is GP-owned', () {
      // The .any short-circuit must still find a GP owner that is not the
      // first scanned entry (minor first, GP second) -> deterministic true.
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable([pA, pB]);
      expect(
        anyInvadableProvinceOwnedByGreatPower(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: _minor1, pB: _gp2},
        ),
        isTrue,
      );
    });
  });

  group('factionOwnsInvadableOldWorldProvince (Refs #3717)', () {
    const String pA = 'provA';
    const String pB = 'provB';

    test('true when the faction owns an invadable province', () {
      final snapshot = _snapshotWithInvadable([pA]);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {pA: _gp2},
          factionId: _gp2,
        ),
        isTrue,
      );
    });

    test('false when invadable provinces are owned by other factions', () {
      final snapshot = _snapshotWithInvadable([pA, pB]);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {pA: _gp3, pB: _minor1},
          factionId: _gp2,
        ),
        isFalse,
      );
    });

    test('false when the owner lookup is absent from the map', () {
      // Unowned / not-yet-mapped invadable province: lookup is null, no match.
      final snapshot = _snapshotWithInvadable([pA]);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {},
          factionId: _gp2,
        ),
        isFalse,
      );
    });

    test('false when there are no invadable provinces', () {
      final snapshot = _snapshotWithInvadable(const []);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {pA: _gp2},
          factionId: _gp2,
        ),
        isFalse,
      );
    });

    test('true when only a non-first invadable province is faction-owned', () {
      // The .any short-circuit must still find the faction owner that is not
      // the first scanned entry (other GP first, target second) -> true.
      final snapshot = _snapshotWithInvadable([pA, pB]);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {pA: _gp3, pB: _gp2},
          factionId: _gp2,
        ),
        isTrue,
      );
    });

    test('agrees with the inline scan it replaces (equivalence)', () {
      final snapshot = _snapshotWithInvadable([pA, pB]);
      for (final owner in <Map<String, String>>[
        const {},
        const {pA: _gp2},
        const {pA: _gp3, pB: _gp2},
        const {pA: _gp3, pB: _minor1},
      ]) {
        expect(
          factionOwnsInvadableOldWorldProvince(
            snapshot: snapshot,
            provinceOwner: owner,
            factionId: _gp2,
          ),
          snapshot.conquest.invadableProvinceIdsSorted.any(
            (pid) => owner[pid] == _gp2,
          ),
          reason: 'mismatch for provinceOwner=$owner',
        );
      }
    });
  });

  group('addInvadableProvinceMinorOwnersNotAtWar (Refs #3717)', () {
    const String pA = 'provA';
    const String pB = 'provB';
    const String pC = 'provC';
    const String _minor2 = 'minor2';

    Game gameWithTwoMinors() => Game(
      id: 'g-3717-minor-collector',
      worldState: WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: const RegionData(provinces: []),
        newWorld: const RegionData(provinces: []),
      ),
      players: const [Player(id: _gp1, displayName: 'GP1', isHuman: false)],
      minorNations: const [
        MinorNation(id: _minor1, displayName: 'Minor1'),
        MinorNation(id: _minor2, displayName: 'Minor2'),
      ],
      tribes: const [Tribe(id: _tribe1, displayName: 'Tribe1')],
    );

    AIWorldSnapshot snapshot(List<String> invadable, List<String> atWarWith) =>
        AIWorldSnapshot(
          playerId: _gp1,
          threats: ThreatSummary(atWarWith: atWarWith),
          opportunities: const OpportunitySummary(),
          conquest: ConquestSummary(invadableProvinceIdsSorted: invadable),
          economy: const EconomySummary(),
          relations: const {},
        );

    test('collects minor owners of invadable provinces not already at war', () {
      final into = <String>{};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: gameWithTwoMinors(),
        snapshot: snapshot([pA, pB], const []),
        provinceOwner: const {pA: _minor1, pB: _minor2},
        into: into,
      );
      expect(into, <String>{_minor1, _minor2});
    });

    test('skips minors already at war', () {
      final into = <String>{};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: gameWithTwoMinors(),
        snapshot: snapshot([pA, pB], [_minor1]),
        provinceOwner: const {pA: _minor1, pB: _minor2},
        into: into,
      );
      expect(into, <String>{_minor2});
    });

    test('skips Great-Power, tribe, and unowned invadable provinces', () {
      final into = <String>{};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: gameWithTwoMinors(),
        snapshot: snapshot([pA, pB, pC], const []),
        // pA: GP, pB: tribe, pC: absent from the owner map (null lookup).
        provinceOwner: const {pA: _gp1, pB: _tribe1},
        into: into,
      );
      expect(into, isEmpty);
    });

    test('adds nothing when there are no invadable provinces', () {
      final into = <String>{};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: gameWithTwoMinors(),
        snapshot: snapshot(const [], const []),
        provinceOwner: const {pA: _minor1},
        into: into,
      );
      expect(into, isEmpty);
    });

    test('preserves pre-seeded entries and de-duplicates via set', () {
      // Mirrors the plateau decider seeding adjacent-owner candidates first.
      final into = <String>{_minor1};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: gameWithTwoMinors(),
        snapshot: snapshot([pA, pB], const []),
        provinceOwner: const {pA: _minor1, pB: _minor2},
        into: into,
      );
      expect(into, <String>{_minor1, _minor2});
    });

    test('agrees with the inline collector loop it replaces (equivalence)', () {
      final game = gameWithTwoMinors();
      for (final atWar in <List<String>>[
        const [],
        [_minor1],
        [_minor1, _minor2],
      ]) {
        for (final owner in <Map<String, String>>[
          const {},
          const {pA: _minor1, pB: _minor2},
          const {pA: _gp1, pB: _minor2},
          const {pA: _tribe1, pB: _minor1},
        ]) {
          final snap = snapshot([pA, pB], atWar);
          final viaHelper = <String>{};
          addInvadableProvinceMinorOwnersNotAtWar(
            game: game,
            snapshot: snap,
            provinceOwner: owner,
            into: viaHelper,
          );
          final viaInline = <String>{};
          for (final pid in snap.conquest.invadableProvinceIdsSorted) {
            final o = owner[pid];
            if (o == null ||
                !isMinorFaction(game, o) ||
                snap.threats.atWarWith.contains(o)) {
              continue;
            }
            viaInline.add(o);
          }
          expect(
            viaHelper,
            viaInline,
            reason: 'mismatch for atWar=$atWar owner=$owner',
          );
        }
      }
    });
  });

  group('orderTargetIsAtWarInvadableBlocker (Refs #3717)', () {
    const Player gp = Player(id: _gp2, displayName: 'GP2', isHuman: false);

    AIWorldSnapshot snapshotAtWar(List<String> atWarWith) => AIWorldSnapshot(
      playerId: _gp1,
      threats: ThreatSummary(atWarWith: atWarWith),
      opportunities: const OpportunitySummary(),
      conquest: const ConquestSummary(),
      economy: const EconomySummary(),
      relations: const {},
    );

    test('true when target is the at-war primary invadable GP blocker', () {
      expect(
        orderTargetIsAtWarInvadableBlocker(
          targetGp: gp,
          snapshot: snapshotAtWar(const [_gp2]),
          targetFactionId: _gp2,
          invadableBlocker: _gp2,
        ),
        isTrue,
      );
    });

    test('false when the target is not a Great Power (targetGp null)', () {
      expect(
        orderTargetIsAtWarInvadableBlocker(
          targetGp: null,
          snapshot: snapshotAtWar(const [_gp2]),
          targetFactionId: _gp2,
          invadableBlocker: _gp2,
        ),
        isFalse,
      );
    });

    test('false when there is no primary invadable blocker', () {
      expect(
        orderTargetIsAtWarInvadableBlocker(
          targetGp: gp,
          snapshot: snapshotAtWar(const [_gp2]),
          targetFactionId: _gp2,
          invadableBlocker: null,
        ),
        isFalse,
      );
    });

    test('false when the order target is not the blocker', () {
      expect(
        orderTargetIsAtWarInvadableBlocker(
          targetGp: gp,
          snapshot: snapshotAtWar(const [_gp2, _gp3]),
          targetFactionId: _gp2,
          invadableBlocker: _gp3,
        ),
        isFalse,
      );
    });

    test('false when the blocker target is not currently at war', () {
      expect(
        orderTargetIsAtWarInvadableBlocker(
          targetGp: gp,
          snapshot: snapshotAtWar(const [_gp3]),
          targetFactionId: _gp2,
          invadableBlocker: _gp2,
        ),
        isFalse,
      );
    });
  });

  group('mutualExhaustedGpStalemateSideQualifies (Refs #3717)', () {
    // 8 OW provinces sits in the late-stalled "8-9 plateau": at/above the
    // min-OW floor, below the observer quota (10), and inside the stall band
    // (<= 9), so it satisfies the three OW gates simultaneously.
    final int qualifyingOw = kMutualExhaustedGpStalemateMinOw;

    test('true at the min-OW / treasury / regiment exhaustion boundary', () {
      final game = _gameWithExhaustedGp(
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
      final game = _gameWithExhaustedGp();
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
      final game = _gameWithExhaustedGp();
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
      final game = _gameWithExhaustedGp(
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
      final game = _gameWithExhaustedGp(
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
      final game = _gameWithExhaustedGp(
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

  group('clampPhaseWeightUpperUnit (Refs #3717)', () {
    test('caps weights above the unit ceiling to 1.0', () {
      expect(clampPhaseWeightUpperUnit(1.5), 1.0);
      expect(clampPhaseWeightUpperUnit(2.0), 1.0);
      expect(clampPhaseWeightUpperUnit(100.0), 1.0);
    });

    test('returns the boundary weight 1.0 unchanged (strict > ceiling)', () {
      expect(clampPhaseWeightUpperUnit(1.0), 1.0);
    });

    test('passes through in-range weights below the ceiling unchanged', () {
      expect(clampPhaseWeightUpperUnit(0.0), 0.0);
      expect(clampPhaseWeightUpperUnit(0.05), 0.05);
      expect(clampPhaseWeightUpperUnit(0.6), 0.6);
      expect(clampPhaseWeightUpperUnit(0.999), 0.999);
    });

    test(
      'does not lower-clamp — negative inputs pass through (callers guard '
      '<= 0.0 themselves)',
      () {
        expect(clampPhaseWeightUpperUnit(-0.5), -0.5);
      },
    );

    test('matches the inline ternary it replaces for representative weights', () {
      for (final w in <double>[-1.0, 0.0, 0.05, 0.5, 1.0, 1.0001, 3.0]) {
        expect(clampPhaseWeightUpperUnit(w), w > 1.0 ? 1.0 : w);
      }
    });
  });
}
