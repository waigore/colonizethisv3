// Widget tests pinning SPEC/ui/victory-overlay.md § Narrow viewport (Refs
// #2870 S8 Req 17). Verifies that below the canonical in-game shell narrow
// breakpoint (`kNarrowBreakpoint` = 600 dp) the action row stacks vertically
// in a `Column` and the laurel row paints at the smaller `24` dp font size,
// while at default (≥ 600 dp) widths the `Wrap` action layout and the `28`
// dp laurel font size are preserved (regression guard).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/victory_overlay.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/panel_test_fixtures.dart';

Widget _wrapPanel({
  required ct_models.Game game,
  required ct_models.VictoryState victory,
  required ct_models.AppEventBus bus,
  required Size viewportSize,
}) {
  // Explicit MediaQuery override pins the viewport width that
  // `MediaQuery.sizeOf(context).width < kNarrowBreakpoint` reads in
  // `VictoryPanel.build`, mirroring `diplomacy_panel_narrow_layout_test.dart`.
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: viewportSize),
      child: Scaffold(
        body: Center(
          child: VictoryPanel(
            game: game,
            victory: victory,
            bus: bus,
          ),
        ),
      ),
    ),
  );
}

Future<void> _bindStandardSurface(WidgetTester tester) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(900, 1600));
}

void main() {
  suppressLogsForTests();

  late ct_models.Game game;
  late String winnerPlayerId;
  late ct_models.AppEventBus victoryTestBus;

  setUp(() {
    ct_models.AppEventBus.reset();
    victoryTestBus = ct_models.AppEventBus.create();
    game = buildVictoryPanelTestGame();
    winnerPlayerId = game.players.first.id;
  });

  tearDown(() {
    ct_models.AppEventBus.reset();
  });

  ct_models.VictoryState buildVictory({int turnNumber = 12}) {
    return ct_models.VictoryState(
      winnerPlayerId: winnerPlayerId,
      type: ct_models.VictoryType.military,
      turnNumber: turnNumber,
    );
  }

  group('VictoryPanel narrow viewport (Refs #2870 S8 Req 17)', () {
    testWidgets(
      'narrow 320 dp: action row uses a vertical Column, no Wrap on actions',
      (WidgetTester tester) async {
        await _bindStandardSurface(tester);
        await tester.pumpWidget(
          _wrapPanel(
            game: game,
            victory: buildVictory(),
            bus: victoryTestBus,
            viewportSize: const Size(320, 800),
          ),
        );
        await tester.pumpAndSettle();

        // The two CtNinePatchButtons must still render (panel content stable).
        expect(find.byType(CtNinePatchButton), findsNWidgets(2));

        // The action cluster should be a Column whose direct children include
        // both CtNinePatchButtons. There must be no Wrap widget enclosing
        // the action buttons at narrow widths.
        final Finder actionWrap = find.descendant(
          of: find.byType(VictoryPanel),
          matching: find.byType(Wrap),
        );
        expect(
          actionWrap,
          findsNothing,
          reason:
              'SPEC/ui/victory-overlay.md § Narrow viewport: at viewport '
              'width < kNarrowBreakpoint (= 600 dp) the action row stacks '
              'vertically in a Column; the wide-layout Wrap must not be '
              'rendered.',
        );
      },
    );

    testWidgets(
      'narrow 599 dp (just below breakpoint): laurel row renders at the '
      'narrow font size (24 px)',
      (WidgetTester tester) async {
        await _bindStandardSurface(tester);
        await tester.pumpWidget(
          _wrapPanel(
            game: game,
            victory: buildVictory(),
            bus: victoryTestBus,
            viewportSize: const Size(kNarrowBreakpoint - 1, 800),
          ),
        );
        await tester.pumpAndSettle();

        // The laurel row paints three Text glyphs sharing one TextStyle whose
        // fontSize must equal the narrow constant. We pick the first glyph
        // (the left ☜ ornament) and read its style.
        final Text leftLaurel = tester
            .widget<Text>(find.text('\u269C').first);
        expect(
          leftLaurel.style?.fontSize,
          VictoryPanel.laurelFontSizeNarrow,
          reason:
              'SPEC/ui/victory-overlay.md § Narrow viewport pins laurel '
              'fontSize to VictoryPanel.laurelFontSizeNarrow (24 dp) at '
              'viewport widths below kNarrowBreakpoint.',
        );
      },
    );

    testWidgets(
      'narrow 320 dp: View final state still dismisses the overlay',
      (WidgetTester tester) async {
        await _bindStandardSurface(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(320, 800)),
              child: Scaffold(
                body: Stack(
                  children: <Widget>[
                    VictoryOverlay(
                      game: game,
                      victory: buildVictory(turnNumber: 7),
                      bus: victoryTestBus,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('MILITARY VICTORY'), findsOneWidget);
        await tester.tap(find.text('View final state'));
        await tester.pumpAndSettle();
        expect(
          find.text('MILITARY VICTORY'),
          findsNothing,
          reason:
              'Narrow Column action layout must keep the View final state '
              'CtNinePatchButton tappable; dismiss flow stays identical to '
              'the wide-layout regression test.',
        );
      },
    );
  });

  group('VictoryPanel wide viewport (regression guard)', () {
    testWidgets(
      'wide 900 dp: action row uses Wrap (regression pin for the pre-#2870 '
      'flex-wrap mockup behaviour)',
      (WidgetTester tester) async {
        await _bindStandardSurface(tester);
        await tester.pumpWidget(
          _wrapPanel(
            game: game,
            victory: buildVictory(),
            bus: victoryTestBus,
            viewportSize: const Size(900, 1200),
          ),
        );
        await tester.pumpAndSettle();

        // The wide layout must render exactly one Wrap widget directly under
        // VictoryPanel — the action cluster.
        final Finder actionWrap = find.descendant(
          of: find.byType(VictoryPanel),
          matching: find.byType(Wrap),
        );
        expect(
          actionWrap,
          findsOneWidget,
          reason:
              'At viewport width ≥ kNarrowBreakpoint (= 600 dp) the action '
              'row mirrors the mockup .victory-actions { flex-wrap:wrap } '
              'rule via a Wrap widget; the narrow Column must not be used.',
        );
        final Wrap wrap = tester.widget<Wrap>(actionWrap);
        // Both CtNinePatchButtons must be direct children of the Wrap.
        expect(
          wrap.children.whereType<CtNinePatchButton>(),
          hasLength(2),
          reason:
              'Wide-layout Wrap must hold both action CtNinePatchButtons '
              'directly so flex-wrap can collapse onto a second run when '
              'the panel\'s 460 dp ceiling is too tight.',
        );
      },
    );

    testWidgets(
      'wide 900 dp: laurel row renders at the wide font size (28 px) '
      '(regression guard for pre-#2870 fontSize: 28)',
      (WidgetTester tester) async {
        await _bindStandardSurface(tester);
        await tester.pumpWidget(
          _wrapPanel(
            game: game,
            victory: buildVictory(),
            bus: victoryTestBus,
            viewportSize: const Size(900, 1200),
          ),
        );
        await tester.pumpAndSettle();

        final Text leftLaurel = tester
            .widget<Text>(find.text('\u269C').first);
        expect(
          leftLaurel.style?.fontSize,
          VictoryPanel.laurelFontSizeWide,
          reason:
              'SPEC/ui/victory-overlay.md § Narrow viewport pins the '
              'wide-layout laurel fontSize to VictoryPanel.laurelFontSizeWide '
              '(28 dp) so the pre-#2870 default rendering does not regress.',
        );
      },
    );
  });
}
