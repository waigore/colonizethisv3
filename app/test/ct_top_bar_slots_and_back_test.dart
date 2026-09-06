// CtTopBar slot composition and back-affordance tests (Refs #4734 Slice H).
// Visual contract: ct_top_bar_test.dart.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_top_bar_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtTopBar slot composition', () {
    testWidgets('omits the back-button label when not supplied', (
      tester,
    ) async {
      await pumpCtTopBar(tester, kCtTopBarProduction);
      expect(find.text('Map'), findsNothing);
    });

    testWidgets(
      'renders backButtonLabel in --muted next to the chevron when supplied',
      (tester) async {
        await pumpCtTopBar(tester, kCtTopBarProductionWithMapLabel);
        final Text label = tester.widget<Text>(find.text('Map'));
        expect(label.style!.color, EditorialMonoclePalette.muted);
      },
    );

    testWidgets(
      'backButtonLabel dims to 0.4 alpha when back button is disabled',
      (tester) async {
        await pumpCtTopBar(
          tester,
          const CtTopBar(
            title: 'Production',
            backButtonLabel: 'Map',
            backButtonEnabled: false,
          ),
        );
        final Text label = tester.widget<Text>(find.text('Map'));
        expect(label.style!.color!.a, closeTo(0.4, 1e-6));
      },
    );

    testWidgets('omits the icon slot when not supplied', (tester) async {
      await pumpCtTopBar(tester, kCtTopBarProduction);
      expect(find.byKey(kCtTopBarTestIconKey), findsNothing);
    });

    testWidgets('renders the icon slot when supplied', (tester) async {
      await pumpCtTopBar(
        tester,
        const CtTopBar(
          title: 'Production',
          icon: SizedBox(
            key: kCtTopBarTestIconKey,
            width: 18,
            height: 18,
          ),
        ),
      );
      expect(find.byKey(kCtTopBarTestIconKey), findsOneWidget);
    });

    testWidgets('renders the trailing slot when supplied', (tester) async {
      await pumpCtTopBar(
        tester,
        const CtTopBar(
          title: 'Production',
          trailing: SizedBox(
            key: kCtTopBarTestTrailingKey,
            width: 24,
            height: 24,
          ),
        ),
      );
      expect(find.byKey(kCtTopBarTestTrailingKey), findsOneWidget);
    });
  });

  group('CtTopBar back-affordance wiring', () {
    testWidgets(
      'forwards onBackPressed to the embedded CtBackButton',
      (tester) async {
        var taps = 0;
        await pumpCtTopBar(
          tester,
          CtTopBar(
            title: 'Production',
            onBackPressed: () => taps++,
          ),
        );
        await tester.tap(find.byType(CtBackButton));
        expect(taps, 1);
      },
    );

    testWidgets(
      'disabled back button does not invoke onBackPressed (negative path)',
      (tester) async {
        var taps = 0;
        await pumpCtTopBar(
          tester,
          CtTopBar(
            title: 'Production',
            backButtonEnabled: false,
            onBackPressed: () => taps++,
          ),
        );
        await tester.tap(find.byType(CtBackButton), warnIfMissed: false);
        expect(taps, 0);
      },
    );

    testWidgets(
      'forwards backButtonSemanticLabel to the embedded CtBackButton',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpCtTopBar(
          tester,
          CtTopBar(
            title: 'Production',
            backButtonSemanticLabel: 'Return to map',
            onBackPressed: () {},
          ),
        );
        expect(find.bySemanticsLabel('Return to map'), findsOneWidget);
        expect(find.bySemanticsLabel('Back'), findsNothing);
        handle.dispose();
      },
    );
  });
}
