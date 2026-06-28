// Widget tests pinning the CtDropdown trigger chevron rotation visual
// contract (R5d) per SPEC/ui/pixel-art-ui-catalog.md and issue #2859 S6.
//
// The R5d contract states: when the picker opens, the chevron rotates 180°
// (chevron-down → chevron-up) over 120 ms using `Curves.easeOut`. When the
// picker closes, it rotates back over the same duration. The chevron colour
// resolves to `--accent-dim` from `EditorialMonoclePalette` (no hex
// literals).
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  group('CtDropdown chevron rotation (Refs #2859 R5d / S6)', () {
    Widget hostDropdown({
      required String? value,
      required ValueChanged<String?> onChanged,
    }) {
      return buildAppShell(
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              child: CtDropdown<String>(
                value: value,
                items: const ['England', 'France'],
                hint: 'Select nation',
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      );
    }

    AnimatedRotation findChevron(WidgetTester tester) {
      final finder = find.byKey(CtDropdown.kChevronAnimatedRotationKey);
      expect(finder, findsOneWidget);
      return tester.widget<AnimatedRotation>(finder);
    }

    Icon findChevronIcon(WidgetTester tester) {
      final iconFinder = find.descendant(
        of: find.byKey(CtDropdown.kChevronAnimatedRotationKey),
        matching: find.byType(Icon),
      );
      expect(iconFinder, findsOneWidget);
      return tester.widget<Icon>(iconFinder);
    }

    testWidgets(
      'AC closed state: trigger chevron is chevron-down at 0 turns',
      (WidgetTester tester) async {
        await tester.pumpWidget(hostDropdown(value: null, onChanged: (_) {}));
        await tester.pumpAndSettle();

        final chevron = findChevron(tester);
        expect(chevron.turns, 0.0);
        expect(chevron.duration, const Duration(milliseconds: 120));
        expect(chevron.curve, Curves.easeOut);

        final icon = findChevronIcon(tester);
        expect(icon.icon, Icons.expand_more);
        expect(icon.size, 16);
        expect(icon.color, EditorialMonoclePalette.accentDim);
      },
    );

    testWidgets(
      'AC open state: tapping the trigger rotates the chevron to 0.5 turns (180°)',
      (WidgetTester tester) async {
        await tester.pumpWidget(hostDropdown(value: null, onChanged: (_) {}));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Select nation'));
        await tester.pump();

        final chevron = findChevron(tester);
        expect(
          chevron.turns,
          0.5,
          reason:
              'Open picker should target 0.5 turns (chevron-down → chevron-up).',
        );
        expect(chevron.duration, const Duration(milliseconds: 120));

        // Drain the open picker so the test does not leak a route.
        await tester.tap(find.text('England').last);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'AC closes again: dismissing the picker rotates the chevron back to 0 turns',
      (WidgetTester tester) async {
        String? selected;
        await tester.pumpWidget(
          hostDropdown(value: null, onChanged: (v) => selected = v),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Select nation'));
        await tester.pumpAndSettle();
        // Confirm we are open: the picker rows are mounted.
        expect(find.text('England'), findsOneWidget);

        await tester.tap(find.text('England'));
        await tester.pumpAndSettle();

        expect(selected, 'England');
        final chevron = findChevron(tester);
        expect(
          chevron.turns,
          0.0,
          reason:
              'After picker close, chevron should return to chevron-down (0 turns).',
        );
        expect(chevron.duration, const Duration(milliseconds: 120));
      },
    );

    testWidgets(
      'AC negative — chevron never rotates while the picker is closed',
      (WidgetTester tester) async {
        await tester.pumpWidget(hostDropdown(value: null, onChanged: (_) {}));
        await tester.pumpAndSettle();

        final initial = findChevron(tester).turns;
        // Pump a few frames without any tap; rotation target must not shift.
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump(const Duration(milliseconds: 60));
        expect(findChevron(tester).turns, initial);
      },
    );

    testWidgets(
      'AC negative — chevron icon is not painted in a non-palette hex colour',
      (WidgetTester tester) async {
        await tester.pumpWidget(hostDropdown(value: null, onChanged: (_) {}));
        await tester.pumpAndSettle();

        final icon = findChevronIcon(tester);
        // Hard-coded light-theme primaries are regressions per
        // colonizethis-ui-design.mdc. Pin the colour to the canonical token.
        expect(icon.color, isNotNull);
        expect(icon.color, isNot(equals(const Color(0xFFF5F5DC))));
        expect(icon.color, equals(EditorialMonoclePalette.accentDim));
      },
    );

    testWidgets(
      'AC negative — dismissing the picker via barrier still resets the chevron',
      (WidgetTester tester) async {
        await tester.pumpWidget(hostDropdown(value: null, onChanged: (_) {}));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Select nation'));
        await tester.pumpAndSettle();
        expect(findChevron(tester).turns, 0.5);

        // Tap outside the dialog content to dismiss via barrier.
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(findChevron(tester).turns, 0.0);
      },
    );
  });
}
