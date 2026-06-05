// Unit tests for the EXPAND feedstock-tile acquisition conquest army-move
// target bias selection contract `selectFeedstockBiasedBestArmyMove`
// (`packages/colonizethis_ai/lib/src/planning/conquest_planner.dart`)
// (Refs #2847 § H8-extraction seller feedstock-tile acquisition;
// SPEC/ai/economy-planner.md
// § EXPAND feedstock-tile acquisition conquest army-move target bias).
//
// This is the army-move consumer of the topology-derived target
// `expandSellerFeedstockTileAcquisitionTarget`: a flagged below-quota zero-NW
// lock-recovery seller is always on the stalled-expansion army-move path, where
// the stalled selection helpers pick the highest-scoring candidate army move.
// The bias re-breaks an EXACT score tie toward the move that targets the
// feedstock conquest target province, so the field army marches onto the
// specific Old World feedstock province the seller must acquire. The tiebreak
// never overrides a strictly higher-scored destination and never fires when the
// target is null (every player whose acquisition residual is inactive — so the
// +6 Old World conquest baseline GPs gp1/gp2 are never redirected).

import 'package:colonizethis_ai/src/planning/conquest_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

ArmyMoveOrder _move(String destination, {String armyId = 'field_a'}) =>
    ArmyMoveOrder(armyId: armyId, destinationProvinceId: destination);

void main() {
  group(
    'selectFeedstockBiasedBestArmyMove '
    '(Refs #2847 § EXPAND feedstock-tile acquisition conquest army-move '
    'target bias)',
    () {
      test(
        'exact score tie -> feedstock-target candidate wins over the '
        'first-in-iteration non-feedstock candidate',
        () {
          final m1 = _move('oldWorld|m1');
          final m2 = _move('oldWorld|m2');
          // Both score equally; m1 comes first in iteration order, so the
          // unbiased argmax would keep m1. The bias must redirect to m2.
          final selected = selectFeedstockBiasedBestArmyMove(
            candidates: [m1, m2],
            score: (_) => 10.0,
            feedstockConquestTarget: 'oldWorld|m2',
          );
          expect(
            selected,
            same(m2),
            reason:
                'On an exact score tie the feedstock-target move (m2) wins '
                'the tiebreak over the lexicographically / iteration-first '
                'non-feedstock incumbent (m1).',
          );
        },
      );

      test(
        'strictly higher non-feedstock score is never overridden by the '
        'feedstock tiebreak',
        () {
          final m1 = _move('oldWorld|m1');
          final m2 = _move('oldWorld|m2');
          final selected = selectFeedstockBiasedBestArmyMove(
            candidates: [m1, m2],
            score: (move) =>
                move.destinationProvinceId == 'oldWorld|m1' ? 20.0 : 10.0,
            feedstockConquestTarget: 'oldWorld|m2',
          );
          expect(
            selected,
            same(m1),
            reason:
                'The tiebreak only breaks exact ties; it never overrides a '
                'strictly higher-scored destination (m1 at 20 beats the '
                'feedstock m2 at 10).',
          );
        },
      );

      test(
        'null feedstock target -> prior first-in-iteration argmax on ties '
        '(+6 baseline GPs never redirected)',
        () {
          final m1 = _move('oldWorld|m1');
          final m2 = _move('oldWorld|m2');
          final selected = selectFeedstockBiasedBestArmyMove(
            candidates: [m1, m2],
            score: (_) => 10.0,
            feedstockConquestTarget: null,
          );
          expect(
            selected,
            same(m1),
            reason:
                'With no flagged-seller target the selection is the prior '
                'strict score > best argmax (first-in-iteration wins ties), '
                'so a non-flagged GP keeps its unbiased pick.',
          );
        },
      );

      test(
        'feedstock incumbent is retained against a later equally-scored '
        'non-feedstock candidate',
        () {
          final m2 = _move('oldWorld|m2');
          final m1 = _move('oldWorld|m1');
          // m2 (the feedstock target) appears first; m1 ties later.
          final selected = selectFeedstockBiasedBestArmyMove(
            candidates: [m2, m1],
            score: (_) => 10.0,
            feedstockConquestTarget: 'oldWorld|m2',
          );
          expect(
            selected,
            same(m2),
            reason:
                'A feedstock-target incumbent is retained when a later '
                'candidate only ties its score.',
          );
        },
      );

      test('empty candidates -> null', () {
        final selected = selectFeedstockBiasedBestArmyMove(
          candidates: const <ArmyMoveOrder>[],
          score: (_) => 1.0,
          feedstockConquestTarget: 'oldWorld|m2',
        );
        expect(selected, isNull);
      });

      test('determinism: identical inputs yield identical output', () {
        final m1 = _move('oldWorld|m1');
        final m2 = _move('oldWorld|m2');
        final m3 = _move('oldWorld|m3');
        ArmyMoveOrder? run() => selectFeedstockBiasedBestArmyMove(
          candidates: [m1, m2, m3],
          score: (move) =>
              move.destinationProvinceId == 'oldWorld|m3' ? 5.0 : 10.0,
          feedstockConquestTarget: 'oldWorld|m2',
        );
        final first = run();
        final second = run();
        expect(first, same(m2));
        expect(second, same(m2), reason: 'Same inputs -> same output.');
      });
    },
  );
}
