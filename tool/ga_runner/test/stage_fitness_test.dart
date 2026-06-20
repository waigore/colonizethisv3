import 'package:colonizethis_test/test.dart';

import 'package:ga_runner/config/ga_config.dart';
import 'package:ga_runner/fitness/stage_fitness.dart';

void main() {
  group('meanStageFitness', () {
    test('returns 0.0 when all games failed', () {
      expect(meanStageFitness(<double>[]), 0.0);
    });

    test('returns arithmetic mean of scored games', () {
      expect(meanStageFitness(<double>[10, 20]), 15.0);
    });
  });

  group('combineStageFitness', () {
    const weights = StageFitnessWeights(twoPlayer: 0.5, sevenGp: 0.5);

    test('returns two-player only when 7-GP stage skipped', () {
      expect(
        combineStageFitness(
          twoPlayerFitness: 0.0,
          sevenGpFitness: null,
          weights: weights,
          sevenGpSkipped: true,
        ),
        0.0,
      );
    });

    test('weighted mean when both stages run', () {
      expect(
        combineStageFitness(
          twoPlayerFitness: 100,
          sevenGpFitness: 50,
          weights: weights,
          sevenGpSkipped: false,
        ),
        75.0,
      );
    });

    test('asymmetric weights normalize by sum', () {
      expect(
        combineStageFitness(
          twoPlayerFitness: 100,
          sevenGpFitness: 0,
          weights: const StageFitnessWeights(twoPlayer: 1, sevenGp: 1),
          sevenGpSkipped: false,
        ),
        50.0,
      );
    });
  });
}
