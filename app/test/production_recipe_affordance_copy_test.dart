// Player-facing Allocation affordance copy. Refs #4717.

import 'package:colonizethis_app/features/game/widgets/production/production_recipe_affordance.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_recipe_affordance_copy.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  group('formatProductionRecipeAffordanceCopy (Refs #4717)', () {
    test('positive cap limited by commodity', () {
      final copy = formatProductionRecipeAffordanceCopy(
        l10n: l10n,
        affordance: const RecipeAffordance(
          maxDesiredOutput: 12,
          limitingLabel: 'Timber',
        ),
        maxAchievable: 12,
      );

      expect(copy.displayText, 'Up to 12, limited by Timber');
      expect(copy.displayText, isNot(contains('·')));
      expect(copy.displayText.toLowerCase(), isNot(contains('bottleneck')));
      expect(copy.semanticsLabel, contains(copy.tooltipMessage));
    });

    test('positive cap limited by labour this turn', () {
      final copy = formatProductionRecipeAffordanceCopy(
        l10n: l10n,
        affordance: const RecipeAffordance(
          maxDesiredOutput: 8,
          limitingLabel: kRecipeAffordanceLabourLabel,
        ),
        maxAchievable: 8,
      );

      expect(copy.displayText, 'Up to 8, limited by labour this turn');
      expect(copy.displayText, isNot(contains('Labour')));
    });

    test('positive cap limited by per-turn panel cap', () {
      final copy = formatProductionRecipeAffordanceCopy(
        l10n: l10n,
        affordance: const RecipeAffordance(
          maxDesiredOutput: 50,
          limitingLabel: 'Timber',
          capLimited: true,
        ),
        maxAchievable: 50,
      );

      expect(copy.displayText, 'Up to 50, limited by the per-turn panel cap');
      expect(copy.displayText, isNot(contains('Timber')));
    });

    test('zero cap short of commodity', () {
      final copy = formatProductionRecipeAffordanceCopy(
        l10n: l10n,
        affordance: const RecipeAffordance(
          maxDesiredOutput: 0,
          limitingLabel: 'Timber',
        ),
        maxAchievable: 0,
      );

      expect(copy.displayText, 'Cannot run — short of Timber');
    });

    test('zero cap not enough labour left this turn', () {
      final copy = formatProductionRecipeAffordanceCopy(
        l10n: l10n,
        affordance: const RecipeAffordance(
          maxDesiredOutput: 0,
          limitingLabel: kRecipeAffordanceLabourLabel,
        ),
        maxAchievable: 0,
      );

      expect(copy.displayText, 'Cannot run — not enough labour left this turn');
      expect(copy.displayText.toLowerCase(), isNot(contains('no labour')));
    });
  });
}
