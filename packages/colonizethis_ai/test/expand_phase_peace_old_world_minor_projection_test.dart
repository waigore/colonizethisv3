// Refs #3393 Phase 6b (slice 8) — behaviour-preserving migration of the three
// EXPAND-phase peace-decider old-world "any minor owns a province" scans onto
// `ProvinceOwnerCache` (SPEC/program/worldstate-projection.md § Phase 6b
// slice 8). The production sites
// (`belowQuotaPeerGpPeaceTargets`,`canPivotFromSoleGpWarAfterPeace`,
// `stalledStrongerGpBlockerPeaceTarget`) now share a single
// `_anyMinorOwnsOldWorldProvince(game)` helper backed by
// `ProvinceOwnerCache.ownsAnyInRegion(minorId, kRegionOldWorld)`. These tests
// pin that the projection-backed predicate returns exactly the boolean the
// prior nested `oldWorld.provinces.any((p) => p.ownerId is a minor id)` scan
// produced. The helper is library-private, so the tests replicate both the
// old and new predicates and assert they agree (the same approach used by the
// slice-7 migration test).

import 'package:colonizethis_logic/ai_api.dart'
    show ProvinceOwnerCache, kRegionOldWorld;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Old (pre-migration) predicate shared by the three EXPAND-phase peace
/// deciders: a nested O(provinces x minors) old-world owner scan.
bool _manualAnyMinorOwnsOldWorld(Game game) =>
    game.worldState.oldWorld.provinces.any(
      (p) =>
          p.ownerId != null &&
          p.ownerId!.isNotEmpty &&
          game.minorNations.any((m) => m.id == p.ownerId),
    );

/// New (slice 8) projection-backed predicate: equivalent to the production
/// `_anyMinorOwnsOldWorldProvince` helper.
bool _projectionAnyMinorOwnsOldWorld(Game game) => game.minorNations.any(
  (m) => ProvinceOwnerCache.of(game.worldState).ownsAnyInRegion(
    m.id,
    kRegionOldWorld,
  ),
);

void main() {
  group('EXPAND-phase peace old-world minor projection (slice 8)', () {
    Game gameWith({
      required String? oldWorldExtraOwner,
      required String newWorldMinorOwner,
    }) => Game(
      id: 'g-slice8',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            // Always owned by a non-minor great power.
            const Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'gp1',
            ),
            Province(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              ownerId: oldWorldExtraOwner,
            ),
          ],
        ),
        newWorld: RegionData(
          provinces: [
            Province(
              id: 'newWorld|n1',
              regionId: 'newWorld',
              ownerId: newWorldMinorOwner,
            ),
          ],
        ),
      ),
      players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
      minorNations: const [
        MinorNation(id: 'minor1', displayName: 'M1'),
        MinorNation(id: 'minor2', displayName: 'M2'),
      ],
    );

    test('true when a minor owns an old-world province (non-minor also owns)', () {
      // minor1 owns oldWorld|p2 (in addition to the non-minor gp1 holding
      // oldWorld|p1); minor2 owns only a new-world province.
      final game = gameWith(
        oldWorldExtraOwner: 'minor1',
        newWorldMinorOwner: 'minor2',
      );

      expect(_projectionAnyMinorOwnsOldWorld(game), isTrue);
      expect(
        _projectionAnyMinorOwnsOldWorld(game),
        _manualAnyMinorOwnsOldWorld(game),
      );
    });

    test('false when only a non-minor owns old-world provinces', () {
      // Both old-world provinces are owned by the non-minor gp1; minor1 and
      // minor2 own only new-world provinces (minor2 here).
      final game = gameWith(
        oldWorldExtraOwner: 'gp1',
        newWorldMinorOwner: 'minor2',
      );

      expect(_projectionAnyMinorOwnsOldWorld(game), isFalse);
      expect(
        _projectionAnyMinorOwnsOldWorld(game),
        _manualAnyMinorOwnsOldWorld(game),
      );
    });

    test('false when the extra old-world province is unowned (null)', () {
      // oldWorld|p2 is unowned; gp1 (non-minor) owns oldWorld|p1; no minor
      // owns any old-world province.
      final game = gameWith(
        oldWorldExtraOwner: null,
        newWorldMinorOwner: 'minor2',
      );

      expect(_projectionAnyMinorOwnsOldWorld(game), isFalse);
      expect(
        _projectionAnyMinorOwnsOldWorld(game),
        _manualAnyMinorOwnsOldWorld(game),
      );
    });
  });
}
