// Labour Controls upkeep and Requires gists (Refs #4734 Slice G).
// Cost/affordance gists: production_labour_tier_gist_test.dart.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_labour_section_test_support.dart';
import 'production_labour_test_fixtures.dart';
import 'production_labour_tier_gist_support.dart';

void main() {
  suppressLogsForTests();

  group('Labour Controls upkeep and Requires gists (Refs #4734 Slice G)', () {
    testWidgets(
      'upkeep gist uses labour per turn and consumption food/luxury',
      (tester) async {
        await pumpProductionLabourSection(
          tester,
          player: productionLabourSectionGpWithPool(
            peasants: 1,
            techUnlocked: productionLabourFullLabourTech,
          ),
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(
                  const ValueKey<String>('production_labour_upkeep_peasants'),
                ),
              )
              .data,
          '1 labour / turn · Grain or Meat',
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(
                  const ValueKey<String>(
                    'production_labour_upkeep_apprentices',
                  ),
                ),
              )
              .data,
          '4 labour / turn · Grain + Meat · Refined sugar',
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(
                  const ValueKey<String>('production_labour_upkeep_journeymen'),
                ),
              )
              .data,
          '6 labour / turn · Grain + Meat · Cigars',
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(
                  const ValueKey<String>('production_labour_upkeep_masters'),
                ),
              )
              .data,
          '8 labour / turn · Grain + Meat · Fur hats',
        );
      },
    );

    testWidgets(
      'tech-locked trained tier shows Requires: display names, not ids or (locked)',
      (tester) async {
        await pumpProductionLabourSection(
          tester,
          player: productionLabourSectionGpWithPool(peasants: 1),
        );
        final requires = tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'production_labour_requires_apprentices',
                ),
              ),
            )
            .data;
        expect(requires, startsWith('Requires: '));
        expect(requires, contains(techDisplayName(kTechIdApprenticeWorkers)));
        expect(requires, contains(techDisplayName(kTechIdSugarRefining)));
        expect(requires, isNot(contains(kTechIdApprenticeWorkers)));
        expect(find.textContaining('(locked)'), findsNothing);
        final plus = tester.widget<InkWell>(
          find.descendant(
            of: find.byKey(
              const ValueKey<String>('production_labour_plus_apprentices'),
            ),
            matching: find.byType(InkWell),
          ),
        );
        expect(plus.onTap, isNull);
      },
    );

    testWidgets('320 dp viewport wraps without overflow and keeps + aligned', (
      tester,
    ) async {
      await pumpProductionLabourSection(
        tester,
        player: productionLabourSectionGpWithPool(
          peasants: 1,
          apprentices: 1,
          treasury: 200,
          stockpile: {
            CommodityCatalog.fabric.id: 2,
            CommodityCatalog.paper.id: 2,
          },
          techUnlocked: productionLabourApprenticeTech,
        ),
        width: 320,
        height: 640,
      );
      expect(tester.takeException(), isNull);
      final peasantPlus = tester.getCenter(
        find.byKey(const ValueKey<String>('production_labour_plus_peasants')),
      );
      final apprenticePlus = tester.getCenter(
        find.byKey(
          const ValueKey<String>('production_labour_plus_apprentices'),
        ),
      );
      expect(apprenticePlus.dx, closeTo(peasantPlus.dx, 0.5));
    });
  });
}
