// Widget tests pinning the CtDropdown compact flat L&F contract
// (Refs #4062) per SPEC/ui/pixel-art-ui-catalog.md § CtDropdown and
// SPEC/ui/mockups/DLG10001-leader-selection-dialog.html `.dropdown-wrapper`.
//
// Trigger: 34 dp visual min-height, 12 px label, flat `--bg-deep`, 1 px
// `--border`, 10 px chevron, no nine-patch chrome. Hit target ≥ 44 dp via
// invisible expansion (mobile-adaptation § 1). Picker rows ~32 dp flat.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  group('CtDropdown compact flat L&F (Refs #4062)', () {
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

    testWidgets(
      'AC positive — trigger visual is ~34 dp, flat bg-deep, 1 px border, '
      '12 px label, 10 px chevron, no nine-patch',
      (WidgetTester tester) async {
        await tester.pumpWidget(hostDropdown(value: null, onChanged: (_) {}));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(CtDropdown<String>),
            matching: find.byType(CtNinePatchButton),
          ),
          findsNothing,
          reason: 'Compact trigger must not use CtNinePatchButton chrome.',
        );

        final visualFinder = find.byKey(CtDropdown.kCtDropdownTriggerVisualKey);
        expect(visualFinder, findsOneWidget);
        final visualSize = tester.getSize(visualFinder);
        expect(
          visualSize.height,
          closeTo(kCtDropdownTriggerVisualMinHeight, 0.5),
          reason: 'Trigger visual height must be ~34 dp.',
        );

        final visual = tester.widget<DecoratedBox>(visualFinder);
        final decoration = visual.decoration as BoxDecoration;
        expect(decoration.color, EditorialMonoclePalette.bgDeep);
        expect(decoration.border, isA<Border>());
        final border = decoration.border! as Border;
        expect(border.top.color, EditorialMonoclePalette.border);
        expect(border.top.width, 1);

        final label = tester.widget<Text>(find.text('Select nation'));
        expect(label.style?.fontSize, kCtDropdownLabelFontSize);
        expect(label.style?.color, EditorialMonoclePalette.fg);

        final iconFinder = find.descendant(
          of: find.byKey(CtDropdown.kChevronAnimatedRotationKey),
          matching: find.byType(Icon),
        );
        final icon = tester.widget<Icon>(iconFinder);
        expect(icon.size, kCtDropdownChevronSize);
        expect(icon.color, EditorialMonoclePalette.accentDim);
      },
    );

    testWidgets(
      'AC positive — hit target is ≥ kMinTouchTargetSize while visual stays '
      '~34 dp',
      (WidgetTester tester) async {
        await tester.pumpWidget(hostDropdown(value: null, onChanged: (_) {}));
        await tester.pumpAndSettle();

        final hitFinder = find.byKey(CtDropdown.kCtDropdownTriggerHitTargetKey);
        expect(hitFinder, findsOneWidget);
        final hitSize = tester.getSize(hitFinder);
        expect(hitSize.height, greaterThanOrEqualTo(kMinTouchTargetSize));
        expect(hitSize.width, greaterThanOrEqualTo(kMinTouchTargetSize));

        final visualSize = tester.getSize(
          find.byKey(CtDropdown.kCtDropdownTriggerVisualKey),
        );
        expect(
          visualSize.height,
          closeTo(kCtDropdownTriggerVisualMinHeight, 0.5),
        );

        // Parent layout contribution stays at the visual height (OverflowBox
        // must not inflate the CtDropdown's reported layout height).
        final dropdownSize = tester.getSize(find.byType(CtDropdown<String>));
        expect(
          dropdownSize.height,
          closeTo(kCtDropdownTriggerVisualMinHeight, 0.5),
          reason:
              'Invisible hit expansion must not change parent layout height.',
        );
      },
    );

    testWidgets(
      'AC positive — picker rows are compact flat (~32 dp), not nine-patch',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostDropdown(value: 'England', onChanged: (_) {}),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('England').first);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(ListView),
            matching: find.byType(CtNinePatchButton),
          ),
          findsNothing,
          reason: 'Picker rows must not use CtNinePatchButton chrome.',
        );

        final selectedFinder = find.byKey(
          CtDropdown.kCtDropdownPickerSelectedRowKey,
        );
        expect(selectedFinder, findsOneWidget);
        final selectedSize = tester.getSize(selectedFinder);
        expect(
          selectedSize.height,
          greaterThanOrEqualTo(kCtDropdownPickerRowVisualMinHeight),
        );
        // Compact: well below the old 48 dp nine-patch default.
        expect(selectedSize.height, lessThan(48));

        await tester.tap(find.text('England').last);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'AC negative — trigger does not paint a light-theme parchment fill',
      (WidgetTester tester) async {
        await tester.pumpWidget(hostDropdown(value: null, onChanged: (_) {}));
        await tester.pumpAndSettle();

        final visual = tester.widget<DecoratedBox>(
          find.byKey(CtDropdown.kCtDropdownTriggerVisualKey),
        );
        final decoration = visual.decoration as BoxDecoration;
        expect(decoration.color, isNot(equals(const Color(0xFFF5F5DC))));
        expect(decoration.color, equals(EditorialMonoclePalette.bgDeep));
      },
    );

    testWidgets(
      'AC hover/open — border lifts to --accent while picker is open',
      (WidgetTester tester) async {
        await tester.pumpWidget(hostDropdown(value: null, onChanged: (_) {}));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Select nation'));
        await tester.pump();

        final visual = tester.widget<DecoratedBox>(
          find.byKey(CtDropdown.kCtDropdownTriggerVisualKey),
        );
        final border = (visual.decoration as BoxDecoration).border! as Border;
        expect(border.top.color, EditorialMonoclePalette.accent);

        await tester.tap(find.text('England').last);
        await tester.pumpAndSettle();
      },
    );
  });
}
