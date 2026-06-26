// Direct unit coverage for the shared EXPAND stalled-expansion peace pivot
// resolver `resolveStalledMinorOrGpBlockerPivot` (Refs #3717 expand-peace
// scoring-skeleton dedup).
//
// The resolver is the single source of truth for the
// `provinceOwner = getProvinceOwnerMap(game)` →
// `minorsOwnInvadable = anyInvadableProvinceOwnedByMinor(...)` →
// `gpBlockerFocus = isStalledOldWorldGpBlockerFocus(...)` →
// `if (!minorsOwnInvadable && !gpBlockerFocus) return <empty>;` skeleton that
// was duplicated verbatim across `stalledStrongerGpBlockerPeaceTarget` and
// `stalledExpansionDistractionPeaceTargets`. These tests pin both pivot arms
// (minor-on-frontier and stalled GP-blocker-focus), the not-applicable
// short-circuit, equivalence with the underlying predicates the resolver
// composes, and determinism (Refs #2509 Must-have #7).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp4';
const String _gpBlocker = 'gp3';
const String _minor1 = 'minor1';

Game _pivotGame({
  required List<Province> provinces,
  required List<String> atWarFactionIds,
  List<MinorNation> minorNations = const [],
  Set<String> extraGpIds = const {},
}) {
  final playerIds = <String>{
    _gpOwn,
    ...extraGpIds,
    for (final id in atWarFactionIds)
      if (id.startsWith('gp')) id,
  };
  return Game(
    id: 'g-3717-pivot-${provinces.length}',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: [
      for (final id in playerIds)
        Player(id: id, displayName: id.toUpperCase(), isHuman: false),
    ],
    minorNations: minorNations,
    diplomacyRelations: [
      for (final id in atWarFactionIds)
        DiplomacyRelation(
          factionId1: _gpOwn,
          factionId2: id,
          state: RelationState.atWar,
          score: 10,
        ),
    ],
  );
}

AIWorldSnapshot _ownSnapshot({
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
  required List<String> invadableProvinceIdsSorted,
}) {
  return AIWorldSnapshot(
    playerId: _gpOwn,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

List<Province> _ownedOldWorld(String ownerId, int count) => [
  for (var i = 0; i < count; i++)
    Province(id: 'oldWorld|${ownerId}_$i', regionId: 'oldWorld', ownerId: ownerId),
];

void main() {
  group('resolveStalledMinorOrGpBlockerPivot — pivot applies', () {
    test('minor owns invadable frontier → minorsOwnInvadable arm', () {
      final game = _pivotGame(
        provinces: [
          ..._ownedOldWorld(_gpOwn, 7),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        atWarFactionIds: const [_gpBlocker],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      final pivot = resolveStalledMinorOrGpBlockerPivot(
        game: game,
        snapshot: snapshot,
      );

      expect(pivot, isNotNull);
      expect(pivot!.minorsOwnInvadable, isTrue);
      // Minor on the frontier ⇒ frontier is not GP-only ⇒ no GP-blocker focus.
      expect(pivot.gpBlockerFocus, isFalse);
      expect(pivot.provinceOwner['oldWorld|inv1'], _minor1);
    });

    test('GP-only below-quota frontier → gpBlockerFocus arm', () {
      final game = _pivotGame(
        provinces: [
          ..._ownedOldWorld(_gpOwn, 7),
          ..._ownedOldWorld(_gpBlocker, 10),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _gpBlocker,
          ),
        ],
        atWarFactionIds: const [_gpBlocker],
        extraGpIds: const {_gpBlocker},
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      final pivot = resolveStalledMinorOrGpBlockerPivot(
        game: game,
        snapshot: snapshot,
      );

      expect(pivot, isNotNull);
      expect(pivot!.minorsOwnInvadable, isFalse);
      expect(pivot.gpBlockerFocus, isTrue);
      expect(pivot.provinceOwner['oldWorld|inv1'], _gpBlocker);
    });
  });

  group('resolveStalledMinorOrGpBlockerPivot — pivot does not apply', () {
    test('unowned invadable frontier → null (neither arm fires)', () {
      final game = _pivotGame(
        provinces: [
          ..._ownedOldWorld(_gpOwn, 7),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: null,
          ),
        ],
        atWarFactionIds: const [_gpBlocker],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      expect(
        resolveStalledMinorOrGpBlockerPivot(game: game, snapshot: snapshot),
        isNull,
        reason:
            'No minor owns invadable land and the frontier is not GP-only '
            '(unowned) ⇒ neither pivot arm applies.',
      );
    });

    test('empty invadable frontier → null', () {
      final game = _pivotGame(
        provinces: _ownedOldWorld(_gpOwn, 7),
        atWarFactionIds: const [_gpBlocker],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const [],
      );

      expect(
        resolveStalledMinorOrGpBlockerPivot(game: game, snapshot: snapshot),
        isNull,
      );
    });
  });

  group('resolveStalledMinorOrGpBlockerPivot — equivalence + determinism', () {
    test('fields equal the predicates the resolver composes', () {
      final game = _pivotGame(
        provinces: [
          ..._ownedOldWorld(_gpOwn, 7),
          ..._ownedOldWorld(_gpBlocker, 10),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _gpBlocker,
          ),
        ],
        atWarFactionIds: const [_gpBlocker],
        extraGpIds: const {_gpBlocker},
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      final pivot = resolveStalledMinorOrGpBlockerPivot(
        game: game,
        snapshot: snapshot,
      );

      expect(pivot, isNotNull);
      expect(
        pivot!.gpBlockerFocus,
        isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
      );
      expect(
        pivot.minorsOwnInvadable,
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: pivot.provinceOwner,
        ),
      );
    });

    test('identical results on repeat', () {
      final game = _pivotGame(
        provinces: [
          ..._ownedOldWorld(_gpOwn, 7),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        atWarFactionIds: const [_gpBlocker],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [_gpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      final first = resolveStalledMinorOrGpBlockerPivot(
        game: game,
        snapshot: snapshot,
      );
      final second = resolveStalledMinorOrGpBlockerPivot(
        game: game,
        snapshot: snapshot,
      );

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.minorsOwnInvadable, second!.minorsOwnInvadable);
      expect(first.gpBlockerFocus, second.gpBlockerFocus);
      expect(first.provinceOwner, equals(second.provinceOwner));
    });
  });
}
