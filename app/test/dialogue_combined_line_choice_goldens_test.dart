// Widget goldens proving the collapsed single-step presentation for the
// blocking Jenny dialogue overlays (Refs #3628). Every blocking node is a
// narrative line immediately followed by a single trivial option
// (`-> Continue` / `-> I shall.`), so `CtDialogueView` collapses the line and
// the option into ONE `CtDialogShell` step: the narrative renders once above a
// single button labelled with the Yarn option text, and one tap advances the
// line and selects the sole option (no duplicate message-bearing step).
//
// Each test asserts both (a) the narrative text and the single option button
// render together at the FIRST dialogue body (structural finders, so the AC
// still holds when goldens are regenerated on another platform) and (b) the
// pixel baseline under `app/test/goldens/`. No advance tap is needed — the
// combined step is the first thing shown.
//
// Host: `configureGoldenSurface` + `wrapGoldenBoundary` from
// `support/golden_capture_harness.dart`; Yarn fakes from
// `support/yarn_test_fixtures.dart` (Refs #3952).
//
// SPEC: SPEC/ui/game-start-intro-overlay.md § Acceptance Criteria (Refs #3628
// AC-1/AC-3 golden coverage) and SPEC/ui/tribe-first-contact-overlay.md §
// Acceptance criteria (AC-11).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/intervention_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/tribe_first_contact_overlay.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'support/golden_capture_harness.dart';
import 'support/yarn_test_fixtures.dart';

/// Minimal [Game] with two GPs and one minor nation, sufficient to drive the
/// overture / intervention overlays through their phase-1 Yarn intro.
Game _minimalGame() {
  return Game(
    id: 'combined_golden_game',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false, treasury: 0),
    ],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Powhatan'),
    ],
  );
}

Future<void> _pumpDialogueGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Widget child,
}) async {
  await configureGoldenSurface(tester, size: const Size(600, 800));
  await tester.pumpWidget(
    wrapGoldenBoundary(
      boundaryKey: boundaryKey,
      center: false,
      useScaffold: false,
      child: child,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'OVL10001 collapsed-step golden: intro narrative renders once above the single "I shall." option (#3628)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('game_start_intro_combined_golden');

      await _pumpDialogueGolden(
        tester,
        boundaryKey: boundaryKey,
        child: GameStartIntroOverlay(
          assetBundle: YarnStringAssetBundle({
            kDialogueGameIntroAsset: kYarnGameStartIntroShort,
          }),
          onDismissed: () {},
          child: const ColoredBox(color: Color(0xFF101014)),
        ),
      );

      // Collapsed step (first body): narrative once + a single button labelled
      // with the Yarn option text "I shall." (not a generic Continue).
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.textContaining('imperialism'), findsOneWidget);
      expect(find.text('I shall.'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/dialogue_combined_game_start_intro_choice.png'),
      );
    },
  );

  testWidgets(
    'OVL80001 combined-step golden: scout narrative + tribe/capital stay above the Continue option (#3628)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'tribe_first_contact_combined_golden',
      );

      await _pumpDialogueGolden(
        tester,
        boundaryKey: boundaryKey,
        child: TribeFirstContactOverlay(
          tribeName: 'Powhatan',
          capitalName: 'Werowocomoco',
          assetBundle: YarnStringAssetBundle({
            kDialogueTribeFirstContactAsset: kYarnTribeFirstContactShort,
          }),
          onDismissed: () {},
          child: const ColoredBox(color: Color(0xFF101014)),
        ),
      );

      // Collapsed step (first body): scout narrative (with interpolated names)
      // renders once together with a single Continue option button.
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.textContaining('Scouts'), findsOneWidget);
      expect(find.textContaining('Powhatan'), findsOneWidget);
      expect(find.textContaining('Werowocomoco'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/dialogue_combined_tribe_first_contact_choice.png',
        ),
      );
    },
  );

  testWidgets(
    'Overture combined-step golden: intro narrative stays above the Continue option (#3628)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('overture_intro_combined_golden');

      await _pumpDialogueGolden(
        tester,
        boundaryKey: boundaryKey,
        child: OvertureDialogueOverlay(
          game: _minimalGame(),
          pendingOvertures: const [
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.embassy,
            ),
          ],
          assetBundle: YarnStringAssetBundle({
            kDialogueOvertureAsset: kYarnOvertureIntroShort,
          }),
          onDecisions: (_) {},
          child: const ColoredBox(color: Color(0xFF101014)),
        ),
      );

      // Collapsed step (first body): intro narrative once + a single Continue
      // option button.
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.textContaining('Envoys'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/dialogue_combined_overture_intro_choice.png'),
      );
    },
  );

  testWidgets(
    'Intervention combined-step golden: intro narrative stays above the Continue option (#3628)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('intervention_intro_combined_golden');

      await configureGoldenSurface(tester, size: const Size(600, 800));
      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: boundaryKey,
          center: false,
          useScaffold: false,
          child: InterventionDialogueOverlay(
            game: _minimalGame(),
            prompts: const [
              InterventionPrompt(
                aggressorGpId: 'gp2',
                defenderMinorOrTribeId: 'minor1',
                interveningGpId: 'gp1',
              ),
            ],
            assetBundle: YarnStringAssetBundle({
              kDialogueInterventionAsset: kYarnInterventionCombinedShort,
            }),
            onDecisions: (_) {},
            child: const ColoredBox(color: Color(0xFF101014)),
          ),
        ),
      );
      // The intervention flow chains several async setState hops (parse →
      // runner → startDialogue → onLineStart); pump repeatedly until the
      // intro line resolves rather than relying on a single fixed delay.
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        if (find.textContaining('Heavy tidings').evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Collapsed step (first body): intro narrative once + a single Continue
      // option button (the intro fixture is one line, so it collapses directly).
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.textContaining('Heavy tidings'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/dialogue_combined_intervention_intro_choice.png',
        ),
      );
    },
  );
}
