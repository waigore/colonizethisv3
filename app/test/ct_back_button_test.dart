import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpBackButton(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: Scaffold(
          body: Center(child: child),
        ),
      ),
    );
    await tester.pump();
  }

  AnimatedContainer bodyContainer(WidgetTester tester) {
    return tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey<String>('ctBackButtonBody')),
    );
  }

  Color bodyColor(WidgetTester tester) {
    final AnimatedContainer container = bodyContainer(tester);
    final BoxDecoration deco = container.decoration! as BoxDecoration;
    return deco.color!;
  }

  Icon chevronIcon(WidgetTester tester) {
    return tester.widget<Icon>(
      find.descendant(
        of: find.byType(CtBackButton),
        matching: find.byIcon(Icons.chevron_left),
      ),
    );
  }

  group('CtBackButton visual contract (R11a)', () {
    testWidgets('renders a 28x28 tap target with a 16px chevron', (
      tester,
    ) async {
      await pumpBackButton(tester, CtBackButton(onPressed: () {}));
      final Size size = tester.getSize(find.byType(CtBackButton));
      expect(size.width, CtBackButton.size);
      expect(size.height, CtBackButton.size);
      expect(CtBackButton.size, 28);
      final Icon icon = chevronIcon(tester);
      expect(icon.size, CtBackButton.glyphSize);
      expect(CtBackButton.glyphSize, 16);
    });

    testWidgets(
      'default state: --accent-dim glyph + transparent background',
      (tester) async {
        await pumpBackButton(tester, CtBackButton(onPressed: () {}));
        expect(chevronIcon(tester).color, EditorialMonoclePalette.accentDim);
        expect(bodyColor(tester).a, 0);
      },
    );

    testWidgets(
      'hover state: glyph --accent + --surface-lite background @ 40%',
      (tester) async {
        await pumpBackButton(tester, CtBackButton(onPressed: () {}));
        final TestGesture gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(tester.getCenter(find.byType(CtBackButton)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(chevronIcon(tester).color, EditorialMonoclePalette.accent);
        final Color bg = bodyColor(tester);
        expect(
          bg.a,
          closeTo(CtBackButton.hoverBackgroundAlpha, 1e-6),
        );
      },
    );

    testWidgets(
      'pressed state: glyph --accent-bright + --surface-lite background @ 60%',
      (tester) async {
        await pumpBackButton(tester, CtBackButton(onPressed: () {}));
        final TestGesture press = await tester.startGesture(
          tester.getCenter(find.byType(CtBackButton)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          chevronIcon(tester).color,
          EditorialMonoclePalette.accentBright,
        );
        expect(
          bodyColor(tester).a,
          closeTo(CtBackButton.pressedBackgroundAlpha, 1e-6),
        );

        await press.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'enabled animation duration matches the documented 120ms ease-out',
      (tester) async {
        await pumpBackButton(tester, CtBackButton(onPressed: () {}));
        final AnimatedContainer container = bodyContainer(tester);
        expect(container.duration, CtBackButton.animationDuration);
        expect(container.duration, const Duration(milliseconds: 120));
        expect(container.curve, CtBackButton.animationCurve);
        expect(container.curve, Curves.easeOut);
      },
    );

    testWidgets('disabled (enabled: false) renders 0.4 opacity', (
      tester,
    ) async {
      await pumpBackButton(
        tester,
        const CtBackButton(enabled: false),
      );
      final Opacity opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(CtBackButton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, CtBackButton.disabledOpacity);
      expect(opacity.opacity, 0.4);
    });

    testWidgets(
      'disabled does not render a tap detector (negative path)',
      (tester) async {
        await pumpBackButton(
          tester,
          const CtBackButton(enabled: false),
        );
        expect(
          find.descendant(
            of: find.byType(CtBackButton),
            matching: find.byType(GestureDetector),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(CtBackButton),
            matching: find.byType(MouseRegion),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('disabled freezes animation (duration = Duration.zero)', (
      tester,
    ) async {
      await pumpBackButton(
        tester,
        const CtBackButton(enabled: false),
      );
      expect(bodyContainer(tester).duration, Duration.zero);
    });

    testWidgets('enabled wraps without an Opacity (negative path)', (
      tester,
    ) async {
      await pumpBackButton(tester, CtBackButton(onPressed: () {}));
      expect(
        find.descendant(
          of: find.byType(CtBackButton),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });
  });

  group('CtBackButton tap behaviour', () {
    testWidgets('custom onPressed is invoked once per tap', (tester) async {
      int taps = 0;
      await pumpBackButton(
        tester,
        CtBackButton(onPressed: () => taps++),
      );
      await tester.tap(find.byType(CtBackButton));
      expect(taps, 1);
    });

    testWidgets(
      'null onPressed defaults to Navigator.maybePop()',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemes.editorialMonocle,
            home: Builder(
              builder: (BuildContext context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const Scaffold(
                              body: Center(child: CtBackButton()),
                            ),
                          ),
                        );
                      },
                      child: const Text('open'),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        expect(find.byType(CtBackButton), findsOneWidget);

        await tester.tap(find.byType(CtBackButton));
        await tester.pumpAndSettle();
        expect(find.byType(CtBackButton), findsNothing);
      },
    );

    testWidgets('disabled does not invoke onPressed (negative path)', (
      tester,
    ) async {
      int taps = 0;
      await pumpBackButton(
        tester,
        CtBackButton(enabled: false, onPressed: () => taps++),
      );
      await tester.tap(find.byType(CtBackButton), warnIfMissed: false);
      expect(taps, 0);
    });
  });

  group('CtBackButton accessibility', () {
    testWidgets(
      'default semantic label is the R11a literal "Back"',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpBackButton(tester, CtBackButton(onPressed: () {}));
        expect(
          find.bySemanticsLabel('Back'),
          findsOneWidget,
        );
        handle.dispose();
      },
    );

    testWidgets(
      'custom semanticLabel replaces the default',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpBackButton(
          tester,
          CtBackButton(
            onPressed: () {},
            semanticLabel: 'Return',
          ),
        );
        expect(find.bySemanticsLabel('Return'), findsOneWidget);
        expect(find.bySemanticsLabel('Back'), findsNothing);
        handle.dispose();
      },
    );
  });
}
