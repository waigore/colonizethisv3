import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpTopBar(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: Scaffold(
          body: Column(children: <Widget>[child]),
        ),
      ),
    );
    await tester.pump();
  }

  DecoratedBox topBarSurface(WidgetTester tester) {
    return tester.widget<DecoratedBox>(
      find.byKey(const ValueKey<String>('ctTopBarSurface')),
    );
  }

  group('CtTopBar visual contract (R11)', () {
    testWidgets('renders at the documented 36px height', (tester) async {
      await pumpTopBar(tester, const CtTopBar(title: 'Production'));
      final SizedBox sized = tester.widget<SizedBox>(
        find.byKey(const ValueKey<String>('ctTopBarHeightBox')),
      );
      expect(sized.height, CtTopBar.height);
      expect(CtTopBar.height, 36);
    });

    testWidgets('paints CtGradients.topBarGradient on the surface', (
      tester,
    ) async {
      await pumpTopBar(tester, const CtTopBar(title: 'Production'));
      final BoxDecoration deco =
          topBarSurface(tester).decoration as BoxDecoration;
      expect(deco.gradient, CtGradients.topBarGradient);
    });

    testWidgets(
      'caps the surface with a 1px --accent-dim bottom border',
      (tester) async {
        await pumpTopBar(tester, const CtTopBar(title: 'Production'));
        final BoxDecoration deco =
            topBarSurface(tester).decoration as BoxDecoration;
        final Border border = deco.border! as Border;
        expect(border.top, BorderSide.none);
        expect(border.left, BorderSide.none);
        expect(border.right, BorderSide.none);
        expect(border.bottom.color, EditorialMonoclePalette.accentDim);
        expect(border.bottom.width, CtTopBar.borderWidth);
        expect(CtTopBar.borderWidth, 1);
      },
    );

    testWidgets(
      'renders the title text in the --accent text token',
      (tester) async {
        await pumpTopBar(tester, const CtTopBar(title: 'Production'));
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
      await pumpTopBar(tester, const CtTopBar(title: 'Production'));
      expect(
        find.descendant(
          of: find.byType(CtTopBar),
          matching: find.byType(CtBackButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'omits the CtBackButton when showBackButton is false (negative path)',
      (tester) async {
        await pumpTopBar(
          tester,
          const CtTopBar(title: 'Production', showBackButton: false),
        );
        expect(
          find.descendant(
            of: find.byType(CtTopBar),
            matching: find.byType(CtBackButton),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'omits the backButtonLabel when showBackButton is false (negative path)',
      (tester) async {
        await pumpTopBar(
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
            matching: find.text('Map'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'still renders the title and trailing slot when showBackButton is false',
      (tester) async {
        await pumpTopBar(
          tester,
          const CtTopBar(
            title: 'Production',
            showBackButton: false,
            trailing: SizedBox(
              key: ValueKey<String>('ctTopBarTestTrailing'),
              width: 24,
              height: 24,
            ),
          ),
        );
        expect(
          find.descendant(
            of: find.byType(CtTopBar),
            matching: find.text('Production'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('ctTopBarTestTrailing')),
          findsOneWidget,
        );
      },
    );
  });

  group('CtTopBar slot composition', () {
    testWidgets('omits the back-button label when not supplied', (
      tester,
    ) async {
      await pumpTopBar(tester, const CtTopBar(title: 'Production'));
      expect(find.text('Map'), findsNothing);
    });

    testWidgets(
      'renders backButtonLabel in --muted next to the chevron when supplied',
      (tester) async {
        await pumpTopBar(
          tester,
          const CtTopBar(title: 'Production', backButtonLabel: 'Map'),
        );
        final Text label = tester.widget<Text>(
          find.descendant(
            of: find.byType(CtTopBar),
            matching: find.text('Map'),
          ),
        );
        expect(label.style!.color, EditorialMonoclePalette.muted);
      },
    );

    testWidgets(
      'backButtonLabel dims to 0.4 alpha when back button is disabled',
      (tester) async {
        await pumpTopBar(
          tester,
          const CtTopBar(
            title: 'Production',
            backButtonLabel: 'Map',
            backButtonEnabled: false,
          ),
        );
        final Text label = tester.widget<Text>(
          find.descendant(
            of: find.byType(CtTopBar),
            matching: find.text('Map'),
          ),
        );
        expect(label.style!.color!.a, closeTo(0.4, 1e-6));
      },
    );

    testWidgets('omits the icon slot when not supplied', (tester) async {
      await pumpTopBar(tester, const CtTopBar(title: 'Production'));
      expect(
        find.byKey(const ValueKey<String>('ctTopBarTestIcon')),
        findsNothing,
      );
    });

    testWidgets('renders the icon slot when supplied', (tester) async {
      await pumpTopBar(
        tester,
        const CtTopBar(
          title: 'Production',
          icon: SizedBox(
            key: ValueKey<String>('ctTopBarTestIcon'),
            width: 18,
            height: 18,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('ctTopBarTestIcon')),
        findsOneWidget,
      );
    });

    testWidgets('renders the trailing slot when supplied', (tester) async {
      await pumpTopBar(
        tester,
        const CtTopBar(
          title: 'Production',
          trailing: SizedBox(
            key: ValueKey<String>('ctTopBarTestTrailing'),
            width: 24,
            height: 24,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('ctTopBarTestTrailing')),
        findsOneWidget,
      );
    });
  });

  group('CtTopBar back-affordance wiring', () {
    testWidgets(
      'forwards onBackPressed to the embedded CtBackButton',
      (tester) async {
        int taps = 0;
        await pumpTopBar(
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
        int taps = 0;
        await pumpTopBar(
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
        await pumpTopBar(
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
