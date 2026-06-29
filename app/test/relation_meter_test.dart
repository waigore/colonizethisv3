// Widget + color tests for the 10-step gradient RelationMeter.
// SPEC/ui/components/relation-meter.md, SPEC/game/diplomacy.md
// § Player-facing relation display — 10-step relation meter (Refs #3753 R13).

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show relationMeterStepCount, relationScoreToMeterStep;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/relation_meter.dart';

Widget _host(num score) => MaterialApp(
  home: Scaffold(body: Center(child: RelationMeter(score: score))),
);

Finder _activeStep(int step) => find.byKey(
  ValueKey<String>(
    '${RelationMeter.kRelationMeterActiveStepKeyPrefix}$step',
  ),
);

void main() {
  suppressLogsForTests();

  group('relationMeterStepColor', () {
    test('endpoints reuse the canonical danger/success tokens', () {
      expect(relationMeterStepColor(1), EditorialMonoclePalette.danger);
      expect(
        relationMeterStepColor(relationMeterStepCount),
        EditorialMonoclePalette.success,
      );
    });

    test('clamps out-of-range steps to the gradient endpoints', () {
      expect(relationMeterStepColor(0), relationMeterStepColor(1));
      expect(
        relationMeterStepColor(relationMeterStepCount + 5),
        relationMeterStepColor(relationMeterStepCount),
      );
    });

    test('every step resolves to a distinct gradient color', () {
      final Set<int> values = <int>{};
      for (int step = 1; step <= relationMeterStepCount; step++) {
        values.add(relationMeterStepColor(step).toARGB32());
      }
      expect(values.length, relationMeterStepCount);
    });
  });

  group('RelationMeter widget', () {
    testWidgets('renders one segment per ladder step', (tester) async {
      await tester.pumpWidget(_host(55));
      expect(find.byType(Container), findsNWidgets(relationMeterStepCount));
    });

    testWidgets('indicator lands on the step covering the hidden score', (
      tester,
    ) async {
      for (final num score in <num>[0, 35, 55, 90, 100]) {
        await tester.pumpWidget(_host(score));
        final int step = relationScoreToMeterStep(score);
        expect(
          _activeStep(step),
          findsOneWidget,
          reason: 'score $score must indicate step $step',
        );
      }
    });

    testWidgets('never renders the numeric score as text', (tester) async {
      await tester.pumpWidget(_host(73.4));
      expect(find.textContaining('73'), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('exposes a semantics label naming the relation word', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(0)); // step 1 → Hostile
      expect(
        find.bySemanticsLabel('Relation: Hostile'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
