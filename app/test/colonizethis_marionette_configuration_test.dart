import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/colonizethis_marionette_configuration.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();
  group('colonizethisCtWidgetIsInteractive', () {
    test('recognises primary Ct-* types', () {
      expect(colonizethisCtWidgetIsInteractive(CtNinePatchButton), isTrue);
      expect(colonizethisCtWidgetIsInteractive(CtActionTextButton), isTrue);
      expect(colonizethisCtWidgetIsInteractive(CtDropdown<String>), isTrue);
    });

    test('ignores layout widgets', () {
      expect(colonizethisCtWidgetIsInteractive(Padding), isFalse);
      expect(colonizethisCtWidgetIsInteractive(Container), isFalse);
    });
  });

  group('colonizethisExtractCtWidgetText', () {
    testWidgets('CtNinePatchButton exposes child label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CtNinePatchButton(
              onPressed: () {},
              child: const Text('New Game'),
            ),
          ),
        ),
      );

      final element = tester.element(find.byType(CtNinePatchButton));
      expect(colonizethisExtractCtWidgetText(element), 'New Game');
    });

    testWidgets('CtActionTextButton exposes label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CtActionTextButton(
              onPressed: () {},
              label: 'Breakdown',
            ),
          ),
        ),
      );

      final element = tester.element(find.byType(CtActionTextButton));
      expect(colonizethisExtractCtWidgetText(element), 'Breakdown');
    });

    testWidgets('CtBackButton exposes semantic label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CtBackButton(semanticLabel: 'Back'),
          ),
        ),
      );

      final element = tester.element(find.byType(CtBackButton));
      expect(colonizethisExtractCtWidgetText(element), 'Back');
    });

    testWidgets('CtDropdown exposes selected value label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CtDropdown<String>(
              value: 'england',
              items: const ['england', 'france'],
              itemLabel: (value) => value == 'england' ? 'England' : 'France',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final element = tester.element(find.byType(CtDropdown<String>));
      expect(colonizethisExtractCtWidgetText(element), 'England');
    });

    testWidgets('CtDangerTextButton prefers semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CtDangerTextButton(
              onPressed: () {},
              label: 'Reset',
              semanticLabel: 'Reset allocation',
            ),
          ),
        ),
      );

      final element = tester.element(find.byType(CtDangerTextButton));
      expect(colonizethisExtractCtWidgetText(element), 'Reset allocation');
    });
  });
}
