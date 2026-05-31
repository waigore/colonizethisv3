// Pins the dark editorial-monocle chrome contract for
// `InterventionDialogueOverlay` per:
//
//   - SPEC/ui/screens/pending-intervention-overlay.md § Dark editorial-monocle
//     chrome (#2867 S9).
//   - SPEC/ui/pixel-art-ui-catalog.md § Dialog scrim (canonical
//     `EditorialMonoclePalette.dialogScrim`).
//   - Issue #2867 R1 (universal dialog pattern — dark scrim, CtDialogShell)
//     and R2 / R26b (Pending Intervention title in `--accent` + CtBrassDivider).
//
// The choice-picker and Yarn-active phases require a fully-loaded Yarn
// project and an async dialogue runner. To keep this test deterministic
// (and avoid pumping a live Yarn timeline), every phase routes through the
// shared private chrome helper `_buildScrimmedShell` in the production
// widget. Exercising the **degraded error path** (forced via a failing
// asset bundle) therefore proves the chrome contract for every phase: the
// scrim, title key + color, and brass divider key are produced by that
// single helper.
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/dialogue/intervention_dialogue_overlay.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future.error(StateError('missing intervention yarn'));
  }
}

const Game _kFixtureGame = Game(
  id: 'iv_dark_chrome',
  worldState: WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(),
    newWorld: RegionData(),
  ),
  players: [
    Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
    Player(id: 'gp2', displayName: 'Aggressor', isHuman: false, treasury: 0),
  ],
  minorNations: [
    MinorNation(id: 'minor1', displayName: 'Minor 1'),
  ],
);

const List<InterventionPrompt> _kFixturePrompts = [
  InterventionPrompt(
    aggressorGpId: 'gp2',
    defenderMinorOrTribeId: 'minor1',
    interveningGpId: 'gp1',
  ),
];

Future<void> _pumpDegradedOverlay(
  WidgetTester tester, {
  Size surfaceSize = const Size(900, 900),
}) async {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.editorialMonocle,
      home: InterventionDialogueOverlay(
        game: _kFixtureGame,
        prompts: _kFixturePrompts,
        skipIntroForTest: true,
        assetBundle: _FailingAssetBundle(),
        onDecisions: (_) {},
        child: const Scaffold(body: Text('child')),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  suppressLogsForTests();

  group('InterventionDialogueOverlay dark editorial-monocle chrome', () {
    testWidgets(
      'scrim resolves to EditorialMonoclePalette.dialogScrim '
      '(no Colors.black54 leak; #2867 R1)',
      (WidgetTester tester) async {
        await _pumpDegradedOverlay(tester);

        // Confirm the degraded panel is on screen so we're inspecting the
        // chrome of the same dialog the player would actually see.
        expect(
          find.textContaining('Could not load intervention dialogue'),
          findsOneWidget,
        );

        final Finder shellFinder = find.byType(CtDialogShell);
        expect(shellFinder, findsOneWidget);
        final Material scrim = tester.widget<Material>(
          find
              .ancestor(of: shellFinder, matching: find.byType(Material))
              .first,
        );
        expect(scrim.color, EditorialMonoclePalette.dialogScrim);
        expect(scrim.color, isNot(Colors.black54));
      },
    );

    testWidgets(
      'title carries stable key, reads "Pending Intervention", and renders '
      'in --accent with fontSize × 0.05 letter-spacing (#2867 R2/R26b)',
      (WidgetTester tester) async {
        await _pumpDegradedOverlay(tester);

        final Finder titleFinder = find.byKey(
          const ValueKey<String>(kInterventionOverlayTitleKey),
        );
        expect(titleFinder, findsOneWidget);
        final Text title = tester.widget<Text>(titleFinder);
        expect(title.data, 'Pending Intervention');
        expect(title.style?.color, EditorialMonoclePalette.accent);
        final double fontSize = title.style?.fontSize ?? 16;
        expect(
          title.style?.letterSpacing,
          closeTo(fontSize * 0.05, 0.0001),
        );
      },
    );

    testWidgets(
      'CtBrassDivider renders below the title with the stable key '
      '(#2867 R26b)',
      (WidgetTester tester) async {
        await _pumpDegradedOverlay(tester);

        final Finder dividerFinder = find.byKey(
          const ValueKey<String>(kInterventionOverlayBrassDividerKey),
        );
        expect(dividerFinder, findsOneWidget);
        expect(
          dividerFinder.evaluate().single.widget,
          isA<CtBrassDivider>(),
        );
      },
    );

    testWidgets(
      'degraded error panel body remains reachable beneath the new chrome '
      '(no regression vs the pre-#2867 degraded fallback)',
      (WidgetTester tester) async {
        await _pumpDegradedOverlay(tester);

        expect(
          find.textContaining('Could not load intervention dialogue'),
          findsOneWidget,
        );
        expect(find.text('Continue'), findsOneWidget);
      },
    );

    testWidgets(
      'overlay subtree contains no AlertDialog/ListTile/Card chrome and no '
      'Material descendant uses Colors.black54 (#2867 R1 negative guard)',
      (WidgetTester tester) async {
        await _pumpDegradedOverlay(tester);

        final Finder overlay = find.byType(InterventionDialogueOverlay);
        expect(
          find.descendant(of: overlay, matching: find.byType(AlertDialog)),
          findsNothing,
        );
        expect(
          find.descendant(of: overlay, matching: find.byType(ListTile)),
          findsNothing,
        );
        expect(
          find.descendant(of: overlay, matching: find.byType(Card)),
          findsNothing,
        );

        for (final Element element in find
            .descendant(of: overlay, matching: find.byType(Material))
            .evaluate()) {
          final Material material = element.widget as Material;
          expect(
            material.color,
            isNot(Colors.black54),
            reason:
                'Legacy Colors.black54 scrim must not leak into the overlay; '
                'use EditorialMonoclePalette.dialogScrim per #2867 R1.',
          );
        }
      },
    );
  });
}
