// Pins the `stalledBelowQuotaGpLeadPeaceTargets` branch table (Refs #2509
// § Observer goal phases (Full AI) — peace at-war Great Powers that lead by
// `kUnwinnableSoleGpMinProvinceDeficit` or more while below the observer quota).
//
// Sibling coverage that this file complements (but does not duplicate):
//
//   - `diplomacy_planner_below_quota_peace_test.dart` — three cases:
//     - GP-only frontier skips the invadable blocker even when the enemy leads.
//     - default-start (ownOw=7) skips a one-province lead (enemy=8).
//     - ownOw=8 with enemy=12 and a minor war returns `['gp4']`.
//     None pin the quota short-circuit, the default-start +2 positive row, the
//     post-default minLeadDeficit=1 negative boundary, multi-GP filtering, or
//     the GP-only "non-blocker still peaced" row.
//
// What this file pins that no sibling pins today:
//
//   1. **Quota short-circuit:** at exactly `kObserverConquestMinOwProvincesPerGp`
//      the list is empty even when an at-war GP leads by more than
//      `kUnwinnableSoleGpMinProvinceDeficit`.
//   2. **`minLeadDeficit` table:** default-start row requires lead **2** (positive
//      at own+2, negative at own+1); post-default row requires lead **1** (positive
//      at own+1, negative at tie).
//   3. **GP-only invadable blocker:** `primaryInvadableOldWorldGpBlocker` is
//      excluded while a non-blocker GP that still satisfies the deficit is kept.
//   4. **Collection guards:** minors in `atWarWith` are skipped; multiple GP
//      targets are sorted; a GP that does not meet the deficit is omitted.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/colonial_pressure.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _ownVsPartnerGame({
  required int ownProvinces,
  required int partnerProvinces,
  required String partnerId,
  String? extraGpId,
  int extraGpProvinces = 0,
  String? invadableOwnerId,
  String? minorId,
  bool atWarWithPartner = true,
  bool atWarWithExtraGp = true,
  bool atWarWithMinor = false,
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|gp_own_$i',
        regionId: 'oldWorld',
        ownerId: 'gp_own',
      ),
    for (var i = 1; i <= partnerProvinces; i++)
      Province(
        id: 'oldWorld|${partnerId}_$i',
        regionId: 'oldWorld',
        ownerId: partnerId,
      ),
    if (extraGpId != null)
      for (var i = 1; i <= extraGpProvinces; i++)
        Province(
          id: 'oldWorld|${extraGpId}_$i',
          regionId: 'oldWorld',
          ownerId: extraGpId,
        ),
    if (invadableOwnerId != null)
      Province(
        id: 'oldWorld|frontier',
        regionId: 'oldWorld',
        ownerId: invadableOwnerId,
      ),
    if (minorId != null)
      const Province(
        id: 'oldWorld|minor_hold',
        regionId: 'oldWorld',
        ownerId: 'minor1',
      ),
  ];

  final players = <Player>[
    const Player(id: 'gp_own', displayName: 'GP_OWN', isHuman: false),
    Player(id: partnerId, displayName: partnerId, isHuman: false),
    if (extraGpId != null)
      Player(id: extraGpId, displayName: extraGpId, isHuman: false),
  ];

  final minorNations = <MinorNation>[
    if (minorId != null) MinorNation(id: minorId, displayName: minorId),
  ];

  final relations = <DiplomacyRelation>[
    if (atWarWithPartner)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: partnerId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (extraGpId != null && atWarWithExtraGp)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: extraGpId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (minorId != null && atWarWithMinor)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: minorId,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  return Game(
    id: 'g-stalled-below-quota-${ownProvinces}_vs_$partnerProvinces',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: minorNations,
    diplomacyRelations: relations,
  );
}

AIWorldSnapshot _ownSnapshot({
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
  List<String> invadableProvinceIdsSorted = const [],
}) {
  return AIWorldSnapshot(
    playerId: 'gp_own',
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

void main() {
  group('stalledBelowQuotaGpLeadPeaceTargets — quota guard', () {
    test('empty at the observer OW quota even when enemy leads by 3+', () {
      final game = _ownVsPartnerGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp,
        partnerProvinces: kObserverConquestMinOwProvincesPerGp + 3,
        partnerId: 'gp_enemy',
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const ['gp_enemy'],
      );

      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'At kObserverConquestMinOwProvincesPerGp the below-quota lead-peace '
            'shortcut must not run (COLONIAL/DEVELOP paths own mop-up).',
      );
    });
  });

  group('stalledBelowQuotaGpLeadPeaceTargets — minLeadDeficit table', () {
    test('default-start empty when enemy leads by only 1 (needs 2)', () {
      final game = _ownVsPartnerGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp + 1,
        partnerId: 'gp_enemy',
        invadableOwnerId: 'minor1',
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const ['gp_enemy'],
        invadableProvinceIdsSorted: const ['oldWorld|frontier'],
      );

      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'own <= kObserverDefaultStartOldWorldProvincesPerGp uses '
            'minLeadDeficit=kUnwinnableSoleGpMinProvinceDeficit (2). '
            'Lead 1 must not peace.',
      );
    });

    test('default-start returns enemy when lead is exactly 2', () {
      final game = _ownVsPartnerGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        partnerProvinces:
            kObserverDefaultStartOldWorldProvincesPerGp +
            kUnwinnableSoleGpMinProvinceDeficit,
        partnerId: 'gp_enemy',
        invadableOwnerId: 'minor1',
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const ['gp_enemy'],
        invadableProvinceIdsSorted: const ['oldWorld|frontier'],
      );

      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        ['gp_enemy'],
      );
    });

    test('post-default empty when enemy ties OW count (needs 1)', () {
      const ownOw = kObserverDefaultStartOldWorldProvincesPerGp + 1;
      final game = _ownVsPartnerGame(
        ownProvinces: ownOw,
        partnerProvinces: ownOw,
        partnerId: 'gp_enemy',
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: ownOw,
        atWarWith: const ['gp_enemy'],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'When own > kObserverDefaultStartOldWorldProvincesPerGp the '
            'minLeadDeficit row is 1; enemyOw == own must not peace.',
      );
    });

    test('post-default returns enemy when lead is exactly 1', () {
      const ownOw = kObserverDefaultStartOldWorldProvincesPerGp + 1;
      final game = _ownVsPartnerGame(
        ownProvinces: ownOw,
        partnerProvinces: ownOw + 1,
        partnerId: 'gp_enemy',
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: ownOw,
        atWarWith: const ['gp_enemy'],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        ['gp_enemy'],
      );
    });
  });

  group('stalledBelowQuotaGpLeadPeaceTargets — GP-only blocker', () {
    test(
      'skips invadable blocker but keeps non-blocker GP with sufficient lead',
      () {
        final game = _ownVsPartnerGame(
          ownProvinces: 8,
          partnerProvinces: 9,
          partnerId: 'gp_blocker',
          extraGpId: 'gp_enemy',
          extraGpProvinces: 11,
          invadableOwnerId: 'gp_blocker',
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_blocker', 'gp_enemy'],
          invadableProvinceIdsSorted: const ['oldWorld|frontier'],
        );

        expect(
          stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
          ['gp_enemy'],
          reason:
              'On a GP-only frontier the invadable blocker is excluded even '
              'when it leads; a second GP that meets minLeadDeficit=1 must still '
              'be peaced.',
        );
      },
    );

    test('empty when sole at-war GP is the invadable blocker with lead 1', () {
      final game = _ownVsPartnerGame(
        ownProvinces: 8,
        partnerProvinces: 9,
        partnerId: 'gp_blocker',
        invadableOwnerId: 'gp_blocker',
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 8,
        atWarWith: const ['gp_blocker'],
        invadableProvinceIdsSorted: const ['oldWorld|frontier'],
      );

      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
      );
    });
  });

  group('stalledBelowQuotaGpLeadPeaceTargets — collection guards', () {
    test('skips minors in atWarWith', () {
      final game = _ownVsPartnerGame(
        ownProvinces: 8,
        partnerProvinces: 12,
        partnerId: 'gp_enemy',
        minorId: 'minor1',
        atWarWithMinor: true,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 8,
        atWarWith: const ['gp_enemy', 'minor1'],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        ['gp_enemy'],
      );
    });

    test('returns sorted GP targets that each meet the deficit', () {
      final game = _ownVsPartnerGame(
        ownProvinces: 6,
        partnerProvinces: 8,
        partnerId: 'gp_b',
        extraGpId: 'gp_a',
        extraGpProvinces: 9,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const ['gp_a', 'gp_b'],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        ['gp_a', 'gp_b'],
        reason:
            'Default-start minLeadDeficit=2: gp_b at +2 qualifies; gp_a at +3 '
            'qualifies; result must be sorted.',
      );
    });

    test('omits GP that leads by less than minLeadDeficit', () {
      final game = _ownVsPartnerGame(
        ownProvinces: 8,
        partnerProvinces: 8,
        partnerId: 'gp_weak',
        extraGpId: 'gp_strong',
        extraGpProvinces: 10,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 8,
        atWarWith: const ['gp_weak', 'gp_strong'],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );

      expect(
        stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot),
        ['gp_strong'],
      );
    });
  });
}
