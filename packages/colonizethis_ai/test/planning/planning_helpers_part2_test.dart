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

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_ai/src/util/faction_query.dart'
    show isMinorFaction;
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
}
