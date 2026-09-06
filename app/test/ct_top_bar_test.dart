import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_top_bar_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtTopBar visual contract (R11)', () {
    testWidgets('renders at the documented 36px height', (tester) async {
      await pumpCtTopBar(tester, kCtTopBarProduction);
      final SizedBox sized = tester.widget<SizedBox>(
        find.byKey(const ValueKey<String>('ctTopBarHeightBox')),
      );
      expect(sized.height, CtTopBar.height);
      expect(CtTopBar.height, 36);
    });

    testWidgets('paints CtGradients.topBarGradient on the surface', (
      tester,
    ) async {
      await pumpCtTopBar(tester, kCtTopBarProduction);
      final BoxDecoration deco =
          ctTopBarSurface(tester).decoration as BoxDecoration;
      expect(deco.gradient, CtGradients.topBarGradient);
    });

    testWidgets(
      'caps the surface with a 1px --accent-dim bottom border',
      (tester) async {
        await pumpCtTopBar(tester, kCtTopBarProduction);
        expectCtTopBarAccentDimBottomBorder(
          ctTopBarSurface(tester).decoration as BoxDecoration,
        );
      },
    );

    testWidgets(
      'renders the title text in the --accent text token',
      (tester) async {
        await pumpCtTopBar(tester, kCtTopBarProduction);
        final Text titleText = tester.widget<Text>(
          find.descendant(
            of: find.byType(CtTopBar),
            matching: find.text('Production'),
          ),
        );
        expect(titleText.style!.color, EditorialMonoclePalette.accent);
      },
    );

    testWidgets('renders a leading CtBackButton by default', (tester) async {
      await pumpCtTopBar(tester, kCtTopBarProduction);
      expect(
        find.descendant(
          of: find.byType(CtTopBar),
          matching: find.byType(CtBackButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'omits back affordance chrome when showBackButton is false (negative path)',
      (tester) async {
        await pumpCtTopBar(
          tester,
          const CtTopBar(
            title: 'Production',
            backButtonLabel: 'Map',
            showBackButton: false,
          ),
        );
        expect(
          find.descendant(
            of: find.byType(CtTopBar),
            matching: find.byType(CtBackButton),
          ),
          findsNothing,
        );
        expect(find.text('Map'), findsNothing);
      },
    );

    testWidgets(
      'still renders the title and trailing slot when showBackButton is false',
      (tester) async {
        await pumpCtTopBar(
          tester,
          const CtTopBar(
            title: 'Production',
            showBackButton: false,
            trailing: SizedBox(
              key: kCtTopBarTestTrailingKey,
              width: 24,
              height: 24,
            ),
          ),
        );
        expect(find.text('Production'), findsOneWidget);
        expect(find.byKey(kCtTopBarTestTrailingKey), findsOneWidget);
      },
    );
  });

  // Slot composition + back wiring: ct_top_bar_slots_and_back_test.dart
}
