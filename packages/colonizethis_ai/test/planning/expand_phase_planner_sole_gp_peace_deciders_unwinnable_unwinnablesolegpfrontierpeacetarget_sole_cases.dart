// unwinnableSoleGpFrontierPeaceTarget — sole-enemy guard (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_sole_gp_peace_deciders_support.dart';

void
registerSoleGpPeaceDecidersUnwinnableUnwinnablesolegpfrontierpeacetargetSoleCases() {
  group('unwinnableSoleGpFrontierPeaceTarget — sole-enemy guard', () {
    test('returns null when zero Great Powers are at war (only a minor)', () {
      // Builds an explicit minor-only at-war state: gp_own has minor1 in
      // its threats.atWarWith but no GP foes. `soleAtWarGreatPowerId`
      // returns null after `playerById` filters the minor out, so the
      // forced peace path must short-circuit before any deficit
      // comparison.
      final game = Game(
        id: 'g-unwinnable-only-minor-at-war-canonical',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 5; i++)
                Province(
                  id: 'oldWorld|${soleGpPeaceGpOwn}_$i',
                  regionId: 'oldWorld',
                  ownerId: soleGpPeaceGpOwn,
                ),
              for (var i = 1; i <= 12; i++)
                Province(
                  id: 'oldWorld|${soleGpPeaceMinor1}_$i',
                  regionId: 'oldWorld',
                  ownerId: soleGpPeaceMinor1,
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
            score: 30,
          ),
        ],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 5,
        atWarWith: const [soleGpPeaceMinor1],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Only a minor is in threats.atWarWith; soleAtWarGreatPowerId '
            'returns null and the canonical forced sole-GP-frontier peace '
            'path must short-circuit. A regression that broadened "sole '
            'GP at war" to "sole faction at war" would return "minor1" '
            'here.',
      );
    });

    test('returns null when two Great Powers are at war (multi-front)', () {
      // Two GPs in atWarWith collapses soleAtWarGreatPowerId to null;
      // the canonical forced peace path must defer to multi-front
      // diplomacy collectors.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 6,
        partnerProvinces: 12,
        extraGpId: soleGpPeaceGpThird,
        extraGpProvinces: 12,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [soleGpPeaceGpPartner, soleGpPeaceGpThird],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Two GP wars violate the sole-enemy contract; the canonical '
            'forced sole-GP-frontier peace path must defer to multi-front '
            'diplomacy selection rather than unilaterally peace one GP.',
      );
    });
  });
}
