/// Pins SPEC/ui contracts for the dialogue Jenny-adapter and the three
/// pixel-art dialogue overlays.
///
/// Tracks:
///
/// - `SPEC/ui/ct-dialogue-view.md` (Jenny `DialogueView` subclass that drives
///   line / choice presentation via `onStateChanged`, `advanceLine`,
///   `selectOption`).
/// - `SPEC/ui/game-start-intro-overlay.md` (modal blocking overlay that runs
///   the `game_start_intro` Yarn node and notifies the host via
///   `onDismissed`).
/// - `SPEC/ui/overture-dialogue-overlay.md` (modal blocking overlay that lets
///   the human-controlled faction Accept / Reject each pending
///   `OvertureOffer` and Submit `OvertureDecision`s via `onDecisions`).
/// - `SPEC/ui/call-to-arms-dialogue-overlay.md` (modal blocking overlay that
///   lets the human-controlled faction Join / Refuse each pending
///   `CallToArmsPending` and Submit `CallToArmsDecision`s via `onDecisions`).
///
/// Refs GitHub #2753.
library;

// Concern split under repo.app_test_file_size (Refs #4013, #4352):
// CtDialogueView + GameStartIntroOverlay.

import 'dart:io' show File;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/ct_dialogue_view.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jenny/jenny.dart';

import 'dialogue_overlays_specs_test_support.dart';
import 'yarn_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('CtDialogueView (SPEC/ui/ct-dialogue-view.md)', () {
    test(
      'freshly constructed view exposes null line and choice, no completers',
      () {
        final view = CtDialogueView();
        expect(view.currentLine, isNull);
        expect(view.currentChoice, isNull);
        view.advanceLine();
        view.selectOption(0);
      },
    );

    test(
      'driving a Yarn project end-to-end transitions line -> choice -> finish '
      'and notifies onStateChanged at each boundary',
      () async {
        final project = YarnProject();
        project.parse(kYarnTraceStory);
        final view = CtDialogueView();
        final transitions = <(String, String)>[];
        view.onStateChanged = (line, choice) {
          transitions.add((
            line == null ? 'null' : 'line',
            choice == null ? 'null' : 'choice',
          ));
        };

        final runner = DialogueRunner(
          yarnProject: project,
          dialogueViews: [view],
        );
        final fut = runner.startDialogue('trace_story');

        await Future<void>.delayed(const Duration(milliseconds: 1));
        expect(view.currentLine, isNotNull);
        expect(view.currentChoice, isNull);
        view.advanceLine();

        await Future<void>.delayed(const Duration(milliseconds: 1));
        expect(view.currentChoice, isNotNull);
        expect(view.currentLine, isNull);
        view.selectOption(0);

        await fut;

        expect(view.currentLine, isNull);
        expect(view.currentChoice, isNull);
        expect(
          transitions,
          containsAllInOrder(<(String, String)>[
            ('line', 'null'),
            ('null', 'null'),
            ('null', 'choice'),
            ('null', 'null'),
          ]),
        );
      },
    );

    test(
      'advanceLine and selectOption are idempotent (second call is a no-op)',
      () async {
        final project = YarnProject();
        project.parse(kYarnTraceStory);
        final view = CtDialogueView();
        final runner = DialogueRunner(
          yarnProject: project,
          dialogueViews: [view],
        );
        final fut = runner.startDialogue('trace_story');

        await Future<void>.delayed(const Duration(milliseconds: 1));
        view.advanceLine();
        view.advanceLine();

        await Future<void>.delayed(const Duration(milliseconds: 1));
        view.selectOption(1);
        view.selectOption(0);

        await fut;
      },
    );
  });

  group('GameStartIntroOverlay (SPEC/ui/game-start-intro-overlay.md)', () {
    testWidgets(
      'with a valid Yarn intro: renders shell over child then dismisses '
      'after the dialogue finishes',
      (WidgetTester tester) async {
        var dismissedCount = 0;
        const childKey = Key('intro_child');

        await tester.pumpWidget(
          wrapGameStartIntroOverlay(
            bundle: YarnInlineAssetBundle(kYarnGameStartIntroShort),
            onDismissed: () => dismissedCount++,
            childKey: childKey,
          ),
        );

        await pumpDialogueOverlaysUntilSettled(tester);

        expect(find.byKey(childKey), findsOneWidget);
        expect(find.byType(CtDialogShell), findsOneWidget);
        // Collapsed single step (Refs #3628): the narrative renders once above
        // a single button labelled with the Yarn option text "I shall." — no
        // separate Continue line step.
        expect(
          find.text('The age of imperialism draweth nigh.'),
          findsOneWidget,
        );
        expect(find.text('I shall.'), findsOneWidget);
        expect(find.byType(CtNinePatchButton), findsOneWidget);

        // One tap advances the line and selects the sole option, finishing the
        // dialogue and dismissing the overlay.
        await tester.tap(find.text('I shall.'));
        await pumpDialogueOverlaysUntilSettled(tester);

        expect(dismissedCount, 1);
        expect(find.byType(CtDialogShell), findsNothing);
        expect(find.byKey(childKey), findsOneWidget);
      },
    );

    testWidgets('with a Yarn asset missing the intro node: surfaces the error '
        'affordance and Continue still dismisses', (WidgetTester tester) async {
      var dismissedCount = 0;

      await tester.pumpWidget(
        wrapGameStartIntroOverlay(
          bundle: YarnMissingNodeAssetBundle(),
          onDismissed: () => dismissedCount++,
        ),
      );

      await pumpDialogueOverlaysUntilSettled(tester);

      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);

      await tester.tap(find.byType(CtNinePatchButton));
      await pumpDialogueOverlaysUntilSettled(tester);

      expect(dismissedCount, 1);
    });

    // AC: title region + CtBrassDivider precede the dialogue body in every
    // non-dismissed state. Pins SPEC/ui/game-start-intro-overlay.md
    // § Components and § Acceptance Criteria for the dark editorial-monocle
    // restyle (Refs #2867 S10).
    testWidgets(
      'every non-dismissed state renders the title + CtBrassDivider chrome '
      'in declared order',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapGameStartIntroOverlay(
            bundle: YarnInlineAssetBundle(kYarnGameStartIntroShort),
            onDismissed: () {},
          ),
        );
        await pumpDialogueOverlaysUntilSettled(tester);

        // The collapsed line+option step (Refs #3628) is the single
        // interactive non-dismissed Yarn state: the title + CtBrassDivider
        // chrome renders above the narrative and the single "I shall." option
        // button together (no separate line step / choice step).
        expect(find.text('A New World Awaits'), findsOneWidget);
        expect(find.byType(CtBrassDivider), findsOneWidget);
        expect(find.text('I shall.'), findsOneWidget);
      },
    );

    testWidgets(
      'error state also renders the title + CtBrassDivider chrome above '
      'the localized error message',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapGameStartIntroOverlay(
            bundle: YarnMissingNodeAssetBundle(),
            onDismissed: () {},
          ),
        );
        await pumpDialogueOverlaysUntilSettled(tester);

        expect(find.text('A New World Awaits'), findsOneWidget);
        expect(find.byType(CtBrassDivider), findsOneWidget);
        expect(
          find.textContaining('Could not load intro dialogue'),
          findsOneWidget,
        );
      },
    );

    // AC: scrim color resolves from EditorialMonoclePalette.dialogScrim
    // (no hex literal). Pins the "no Colors.black54" contract from
    // SPEC/ui/game-start-intro-overlay.md § Acceptance Criteria
    // (Refs #2867 S10).
    testWidgets(
      'scrim layer paints EditorialMonoclePalette.dialogScrim in both the '
      'presenting-line and error states',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapGameStartIntroOverlay(
            bundle: YarnInlineAssetBundle(kYarnGameStartIntroShort),
            onDismissed: () {},
          ),
        );
        await pumpDialogueOverlaysUntilSettled(tester);

        final lineMaterials = tester
            .widgetList<Material>(
              find.descendant(
                of: find.byType(GameStartIntroOverlay),
                matching: find.byType(Material),
              ),
            )
            .where((m) => m.color == EditorialMonoclePalette.dialogScrim);
        expect(
          lineMaterials,
          isNotEmpty,
          reason:
              'presenting-line scrim must paint '
              'EditorialMonoclePalette.dialogScrim, not a hex literal.',
        );
        expect(
          tester
              .widgetList<Material>(find.byType(Material))
              .any((m) => m.color == Colors.black54),
          isFalse,
          reason: 'No Material may paint the legacy Colors.black54 scrim.',
        );

        await tester.pumpWidget(
          wrapGameStartIntroOverlay(
            bundle: YarnMissingNodeAssetBundle(),
            onDismissed: () {},
          ),
        );
        await pumpDialogueOverlaysUntilSettled(tester);

        final errorMaterials = tester
            .widgetList<Material>(
              find.descendant(
                of: find.byType(GameStartIntroOverlay),
                matching: find.byType(Material),
              ),
            )
            .where((m) => m.color == EditorialMonoclePalette.dialogScrim);
        expect(
          errorMaterials,
          isNotEmpty,
          reason:
              'error scrim must also paint '
              'EditorialMonoclePalette.dialogScrim, not a hex literal.',
        );
      },
    );

    // Static check: the widget source must not paint a hex-literal scrim
    // (e.g. Colors.black54). This pins the SPEC ban so future regressions
    // are caught even when the runtime widget tree is shallowly inspected.
    test('widget source does not reference Colors.black54 as the scrim '
        '(SPEC/ui/game-start-intro-overlay.md § Components)', () {
      final source = dialogueOverlaysLibraryUnitSource(
        'lib/features/game/widgets/dialogue/game_start_intro_overlay.dart',
      );
      expect(
        source.contains('Colors.black54'),
        isFalse,
        reason:
            'Refs #2867 S10: intro overlay scrim must resolve from the '
            'EditorialMonoclePalette.dialogScrim token; Colors.black54 was '
            'the legacy hex-literal scrim and must not return.',
      );
      expect(
        source.contains('EditorialMonoclePalette.dialogScrim') ||
            source.contains('CtFullScreenDialogueShell') ||
            source.contains('buildTitledDialogueChrome'),
        isTrue,
        reason:
            'Refs #2867 S10 / #2914 S2 / #4018: intro overlay scrim must resolve '
            'to the canonical EditorialMonoclePalette.dialogScrim token, either '
            'directly, via CtFullScreenDialogueShell, or via '
            'buildTitledDialogueChrome (which wraps that shell).',
      );
      final shellSource = File(
        'lib/widgets/ct_full_screen_dialogue_shell.dart',
      ).readAsStringSync();
      expect(
        shellSource.contains('EditorialMonoclePalette.dialogScrim'),
        isTrue,
        reason:
            'Refs #2914 S2: CtFullScreenDialogueShell is the canonical scrim '
            'host for dialogue overlays and must paint '
            'EditorialMonoclePalette.dialogScrim.',
      );
    });
  });
}
