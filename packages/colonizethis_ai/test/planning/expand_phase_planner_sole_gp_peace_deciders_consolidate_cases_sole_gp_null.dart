// Topic-split cases from `expand_phase_planner_sole_gp_peace_deciders_consolidate_cases` (Refs #4669 Slice B).
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import 'expand_phase_planner_sole_gp_peace_deciders_support.dart';

void registerExpandSoleGpPeaceDecidersConsolidateSoleGpNullCases() {
  group('consolidateGainsSoleGpPeaceTarget — sole-GP-null branch', () {
    test('returns null when no Great Powers are at war (only a minor)', () {
      // Minor-only at-war state: soleAtWarGreatPowerId is null, the
      // canonical consolidate shortcut must short-circuit.
      final game = Game(
        id: 'g-consolidate-only-minor-at-war-canonical',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
          oldWorld: RegionData(
            provinces: [
              for (
                var i = 0;
                i < kObserverConquestConsolidateMinOwProvinces;
                i++
              )
                Province(
                  id: 'oldWorld|${soleGpPeaceGpOwn}_$i',
                  regionId: 'oldWorld',
                  ownerId: soleGpPeaceGpOwn,
                ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: soleGpPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: soleGpPeaceMinor1, displayName: 'M1'),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: soleGpPeaceGpOwn,
            factionId2: soleGpPeaceMinor1,
            state: RelationState.atWar,
            score: 10,
          ),
        ],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
        atWarWith: const [soleGpPeaceMinor1],
      );
      expect(
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'soleAtWarGreatPowerId is null when only a minor is at war, '
            'so the canonical consolidate shortcut must short-circuit '
            'before evaluating OW counts.',
      );
    });

    test('returns null when two Great Powers are at war', () {
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverConquestConsolidateMinOwProvinces,
        partnerProvinces: 1,
        extraGpId: soleGpPeaceGpThird,
        extraGpProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
        atWarWith: const [soleGpPeaceGpPartner, soleGpPeaceGpThird],
      );
      expect(
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Two GP wars violate the sole-GP precondition; the canonical '
            'consolidate shortcut must defer to multi-front collectors.',
      );
    });
  });

}
