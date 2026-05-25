// Pins `mutualExhaustedBelowQuotaGpStalematePeaceTargets` from issue #2509.
//
// SPEC (`SPEC/ai/ai-architecture.md` § Diplomacy targeting): when both sides of
// a sole at-war GP pair are mutual-plateau peers below the observer quota AND
// both are exhausted in regiments (≤ `kMutualExhaustedGpRegimentMax`) AND
// treasury (≤ `kMutualExhaustedGpTreasuryMax`), the helper peaces the blocker
// even on a GP-only invadable frontier so both sides rebuild before re-engaging
// (observer seed-42 gp3/gp4 3-regiment 0-treasury turn-100 stalemate).
//
// Coverage:
//   - Positive: gp3-like and gp4-like exhausted-plateau fixture → peer enemy.
//   - Negative: ownOw at quota → empty.
//   - Negative: ownOw outside stalled band → empty.
//   - Negative: own treasury above ceiling → empty.
//   - Negative: own regiments above ceiling → empty.
//   - Negative: enemy treasury above ceiling → empty.
//   - Negative: enemy regiments above ceiling → empty.
//   - Negative: not sole GP war (two GPs at war) → empty.
//   - Negative: mutual gap > 1 OW province → empty.
//   - Determinism: identical inputs → identical outputs across calls.
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _ownNationId = 'gp4';
const _enemyNationId = 'gp3';

const _ownOwProvinces = <String>[
  'oldWorld|gp4_1',
  'oldWorld|gp4_2',
  'oldWorld|gp4_3',
  'oldWorld|gp4_4',
  'oldWorld|gp4_5',
  'oldWorld|gp4_6',
  'oldWorld|gp4_7',
  'oldWorld|gp4_8',
];

const _enemyOwProvinces = <String>[
  'oldWorld|gp3_1',
  'oldWorld|gp3_2',
  'oldWorld|gp3_3',
  'oldWorld|gp3_4',
  'oldWorld|gp3_5',
  'oldWorld|gp3_6',
  'oldWorld|gp3_7',
  'oldWorld|gp3_8',
  'oldWorld|gp3_9',
];

Game _exhaustedStalemateGame({
  int ownTreasury = 0,
  int enemyTreasury = 0,
  List<String> ownRegimentIds = const <String>['u_gp4_a', 'u_gp4_b', 'u_gp4_c'],
  List<String> enemyRegimentIds = const <String>[
    'u_gp3_a',
    'u_gp3_b',
    'u_gp3_c',
  ],
  List<String> extraOwnOwProvinces = const <String>[],
  List<String> extraEnemyOwProvinces = const <String>[],
  List<DiplomacyRelation> diplomacyRelations = const <DiplomacyRelation>[
    DiplomacyRelation(
      factionId1: _ownNationId,
      factionId2: _enemyNationId,
      state: RelationState.atWar,
      score: 20,
    ),
  ],
  List<Player>? playersOverride,
}) {
  final ownerships = <Province>[
    for (final id in _ownOwProvinces)
      Province(id: id, regionId: 'oldWorld', ownerId: _ownNationId),
    for (final id in extraOwnOwProvinces)
      Province(id: id, regionId: 'oldWorld', ownerId: _ownNationId),
    for (final id in _enemyOwProvinces)
      Province(id: id, regionId: 'oldWorld', ownerId: _enemyNationId),
    for (final id in extraEnemyOwProvinces)
      Province(id: id, regionId: 'oldWorld', ownerId: _enemyNationId),
  ];
  return Game(
    id: 'g-2509-mutual-exhausted-stalemate',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 95),
      oldWorld: RegionData(provinces: ownerships),
      newWorld: const RegionData(),
      armies: [
        Army(
          id: 'army_$_ownNationId',
          ownerId: _ownNationId,
          regionId: 'oldWorld',
          stationedProvinceId: _ownOwProvinces.first,
          regimentUnitIds: List<String>.unmodifiable(ownRegimentIds),
          isHomeArmy: true,
        ),
        Army(
          id: 'army_$_enemyNationId',
          ownerId: _enemyNationId,
          regionId: 'oldWorld',
          stationedProvinceId: _enemyOwProvinces.first,
          regimentUnitIds: List<String>.unmodifiable(enemyRegimentIds),
          isHomeArmy: true,
        ),
      ],
    ),
    players:
        playersOverride ??
        [
          Player(
            id: _ownNationId,
            displayName: 'GP4',
            isHuman: false,
            treasury: ownTreasury,
          ),
          Player(
            id: _enemyNationId,
            displayName: 'GP3',
            isHuman: false,
            treasury: enemyTreasury,
          ),
        ],
    diplomacyRelations: diplomacyRelations,
  );
}

AIWorldSnapshot _snapshotForOwn({
  int ownOw = 8,
  List<String> atWarWith = const <String>[_enemyNationId],
}) {
  return AIWorldSnapshot(
    playerId: _ownNationId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: ownOw,
      invadableProvinceIdsSorted: const <String>[],
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('mutualExhaustedBelowQuotaGpStalematePeaceTargets', () {
    test('positive: gp3/gp4-like exhausted plateau peaces the peer enemy', () {
      final game = _exhaustedStalemateGame();
      final snapshot = _snapshotForOwn();

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, [_enemyNationId]);
    });

    test('negative: own GP already at observer quota returns empty', () {
      final game = _exhaustedStalemateGame(
        extraOwnOwProvinces: const ['oldWorld|gp4_9', 'oldWorld|gp4_10'],
      );
      final snapshot = _snapshotForOwn(ownOw: 10);

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: own GP outside stalled OW band returns empty', () {
      final game = _exhaustedStalemateGame();
      final snapshot = AIWorldSnapshot(
        playerId: _ownNationId,
        threats: const ThreatSummary(atWarWith: [_enemyNationId]),
        opportunities: const OpportunitySummary(),
        conquest: const ConquestSummary(
          oldWorldProvincesOwned: 0,
          invadableProvinceIdsSorted: <String>[],
        ),
        economy: const EconomySummary(),
        relations: const {},
      );

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: own OW below late-stalled floor returns empty', () {
      // Trim ownership so the own side holds fewer than
      // `kMutualExhaustedGpStalemateMinOw` (8) OW provinces. The early-game /
      // collapsed-survival case is handled by `criticalWeakGpSurvivalPeaceTargets`,
      // not the mutual-exhausted helper.
      final base = _exhaustedStalemateGame();
      final reduced = Game(
        id: 'g-2509-mutual-exhausted-floor',
        worldState: WorldState(
          turnState: base.worldState.turnState,
          oldWorld: RegionData(
            provinces: [
              for (final p in base.worldState.oldWorld.provinces)
                if (p.ownerId != _ownNationId ||
                    int.parse(p.id.split('_').last) <
                        kMutualExhaustedGpStalemateMinOw - 1)
                  p,
            ],
          ),
          newWorld: const RegionData(),
          armies: base.worldState.armies,
        ),
        players: base.players,
        diplomacyRelations: base.diplomacyRelations,
      );
      // Own side now holds 7 OW provinces (< floor 8) but is still otherwise
      // in the stalled band.
      final snapshot = _snapshotForOwn(ownOw: 7);

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: reduced,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: own treasury above ceiling returns empty', () {
      final game = _exhaustedStalemateGame(
        ownTreasury: kMutualExhaustedGpTreasuryMax + 1,
      );
      final snapshot = _snapshotForOwn();

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: own regiments above ceiling returns empty', () {
      final tooManyRegiments = <String>[
        for (var i = 0; i < kMutualExhaustedGpRegimentMax + 1; i++) 'u_gp4_$i',
      ];
      final game = _exhaustedStalemateGame(ownRegimentIds: tooManyRegiments);
      final snapshot = _snapshotForOwn();

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: enemy treasury above ceiling returns empty', () {
      final game = _exhaustedStalemateGame(
        enemyTreasury: kMutualExhaustedGpTreasuryMax + 1,
      );
      final snapshot = _snapshotForOwn();

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: enemy regiments above ceiling returns empty', () {
      final tooManyEnemyRegiments = <String>[
        for (var i = 0; i < kMutualExhaustedGpRegimentMax + 1; i++) 'u_gp3_$i',
      ];
      final game = _exhaustedStalemateGame(
        enemyRegimentIds: tooManyEnemyRegiments,
      );
      final snapshot = _snapshotForOwn();

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: two GP wars (not sole) returns empty', () {
      final game = _exhaustedStalemateGame(
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: _ownNationId,
            factionId2: _enemyNationId,
            state: RelationState.atWar,
            score: 20,
          ),
          DiplomacyRelation(
            factionId1: _ownNationId,
            factionId2: 'gp5',
            state: RelationState.atWar,
            score: 20,
          ),
        ],
        playersOverride: const [
          Player(id: _ownNationId, displayName: 'GP4', isHuman: false),
          Player(id: _enemyNationId, displayName: 'GP3', isHuman: false),
          Player(id: 'gp5', displayName: 'GP5', isHuman: false),
        ],
      );
      final snapshot = _snapshotForOwn(
        atWarWith: const [_enemyNationId, 'gp5'],
      );

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: game,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test('negative: gap > 1 OW province returns empty', () {
      // Drop enemy base ownership down to 6 provinces. snapshot ownOw=8 stays
      // (helper's own-side reads from snapshot). Game-state enemy province
      // count read by `provinceCountOwnedBy` is now 6, so gap = |6-8| = 2 → 1
      // greater than the helper's tolerance, must return empty.
      final fullGame = _exhaustedStalemateGame();
      final droppedIds = <String>{
        _enemyOwProvinces[7],
        _enemyOwProvinces[8],
        _enemyOwProvinces[6],
      };
      final reducedGame = Game(
        id: 'g-2509-mutual-exhausted-stalemate-gap',
        worldState: WorldState(
          turnState: fullGame.worldState.turnState,
          oldWorld: RegionData(
            provinces: [
              for (final p in fullGame.worldState.oldWorld.provinces)
                if (!droppedIds.contains(p.id)) p,
            ],
          ),
          newWorld: const RegionData(),
          armies: fullGame.worldState.armies,
        ),
        players: fullGame.players,
        diplomacyRelations: fullGame.diplomacyRelations,
      );
      final snapshot = _snapshotForOwn();

      final targets = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
        game: reducedGame,
        snapshot: snapshot,
      );

      expect(targets, isEmpty);
    });

    test(
      'determinism: repeated calls return identical results (must-have #7)',
      () {
        final game = _exhaustedStalemateGame();
        final snapshot = _snapshotForOwn();

        final a = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final b = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final c = mutualExhaustedBelowQuotaGpStalematePeaceTargets(
          game: game,
          snapshot: snapshot,
        );

        expect(a, [_enemyNationId]);
        expect(b, a);
        expect(c, a);
      },
    );
  });

  group('mutual-exhausted stalemate wiring into peace orchestration', () {
    test(
      'collectStalledGreatPowerPeaceTargets keeps the blocker for the exhausted-plateau case',
      () {
        // The helper participates in the zero-regiment blocker override set,
        // so even with the enemy classified as the primary invadable OW GP
        // blocker (`isOldWorldGpOnlyInvadableFrontier` + below-quota), peace
        // is produced. Without this wiring, the blocker would be filtered out
        // of the final target set.
        //
        // Trim the enemy base from 9 to 8 so adding the invadable frontier
        // province keeps the enemy at 9 OW (below quota, mutual-plateau peer
        // for this GP at 8 OW).
        final game = _exhaustedStalemateGame();
        final gameWithInvadable = Game(
          id: 'g-2509-mutual-exhausted-blocker-keep',
          worldState: WorldState(
            turnState: game.worldState.turnState,
            oldWorld: RegionData(
              provinces: [
                for (final p in game.worldState.oldWorld.provinces)
                  if (p.id != _enemyOwProvinces.last) p,
                const Province(
                  id: 'oldWorld|frontier',
                  regionId: 'oldWorld',
                  ownerId: _enemyNationId,
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: game.worldState.armies,
          ),
          players: game.players,
          diplomacyRelations: game.diplomacyRelations,
        );
        final snapshot = AIWorldSnapshot(
          playerId: _ownNationId,
          threats: const ThreatSummary(atWarWith: [_enemyNationId]),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(
            oldWorldProvincesOwned: 8,
            invadableProvinceIdsSorted: <String>['oldWorld|frontier'],
          ),
          economy: const EconomySummary(),
          relations: const {},
        );

        final targets = collectStalledGreatPowerPeaceTargets(
          game: gameWithInvadable,
          snapshot: snapshot,
        );

        expect(
          targets,
          contains(_enemyNationId),
          reason:
              'Mutually-exhausted plateau must peace the GP blocker even when '
              'it owns the sole invadable frontier (Refs #2509).',
        );
      },
    );

    test(
      'collectStalledGreatPowerPeaceTargets without exhaustion still peaces plateau peer',
      () {
        // Negative control for mutual exhaustion only: treasury/regiment guards
        // reject `mutualExhaustedBelowQuotaGpStalematePeaceTargets`, but
        // `nearQuotaHoldPeaceTargets` still peaces mutual-plateau peers on a
        // GP-only cleared frontier (Refs #2509).
        final game = _exhaustedStalemateGame(
          ownTreasury: kMutualExhaustedGpTreasuryMax + 100,
          enemyTreasury: kMutualExhaustedGpTreasuryMax + 100,
          ownRegimentIds: const [
            'u_gp4_a',
            'u_gp4_b',
            'u_gp4_c',
            'u_gp4_d',
            'u_gp4_e',
            'u_gp4_f',
            'u_gp4_g',
            'u_gp4_h',
          ],
          enemyRegimentIds: const [
            'u_gp3_a',
            'u_gp3_b',
            'u_gp3_c',
            'u_gp3_d',
            'u_gp3_e',
            'u_gp3_f',
            'u_gp3_g',
            'u_gp3_h',
          ],
        );
        final gameWithInvadable = Game(
          id: 'g-2509-mutual-exhausted-control',
          worldState: WorldState(
            turnState: game.worldState.turnState,
            oldWorld: RegionData(
              provinces: [
                for (final p in game.worldState.oldWorld.provinces)
                  if (p.id != _enemyOwProvinces.last) p,
                const Province(
                  id: 'oldWorld|frontier',
                  regionId: 'oldWorld',
                  ownerId: _enemyNationId,
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: game.worldState.armies,
          ),
          players: game.players,
          diplomacyRelations: game.diplomacyRelations,
        );
        final snapshot = AIWorldSnapshot(
          playerId: _ownNationId,
          threats: const ThreatSummary(atWarWith: [_enemyNationId]),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(
            oldWorldProvincesOwned: 8,
            invadableProvinceIdsSorted: <String>['oldWorld|frontier'],
          ),
          economy: const EconomySummary(),
          relations: const {},
        );

        final exhaustedTargets =
            mutualExhaustedBelowQuotaGpStalematePeaceTargets(
              game: gameWithInvadable,
              snapshot: snapshot,
            );
        expect(
          exhaustedTargets,
          isEmpty,
          reason: 'Exhaustion guard must reject well-resourced GPs.',
        );

        final targets = collectStalledGreatPowerPeaceTargets(
          game: gameWithInvadable,
          snapshot: snapshot,
        );

        expect(
          targets,
          contains(_enemyNationId),
          reason:
              'Mutual-plateau near-quota hold peace applies even without '
              'regiment/treasury exhaustion on a GP-only cleared frontier.',
        );
      },
    );
  });
}
