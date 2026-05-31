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

import 'dart:io' show File;

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/dialogue/call_to_arms_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/dialogue/ct_dialogue_view.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jenny/jenny.dart';

class _InlineYarnAssetBundle extends Fake implements AssetBundle {
  _InlineYarnAssetBundle(this._text);

  final String _text;

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future.value(_text);
  }
}

class _MissingNodeAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future.value('title: not_the_intro\n---\nIrrelevant.\n===\n');
  }
}

const String _kIntroYarn = '''
title: game_start_intro
---
The age of imperialism draweth nigh.
-> I shall.
===
''';

const String _kTraceYarn = '''
title: trace_story
---
First line.
-> Continue
-> Stop
===
''';

Future<void> _pumpUntilSettled(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Widget _wrapIntroOverlay({
  required AssetBundle bundle,
  required VoidCallback onDismissed,
  Key? childKey,
}) {
  return MaterialApp(
    theme: AppThemes.colonial,
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    localizationsDelegates: const [
      // Reuse Material delegates so appL10n resolves english strings.
    ],
    home: Scaffold(
      body: GameStartIntroOverlay(
        onDismissed: onDismissed,
        assetBundle: bundle,
        child: SizedBox.expand(
          key: childKey,
          child: const Center(child: Text('child-content')),
        ),
      ),
    ),
  );
}

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
        project.parse(_kTraceYarn);
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
        project.parse(_kTraceYarn);
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
          _wrapIntroOverlay(
            bundle: _InlineYarnAssetBundle(_kIntroYarn),
            onDismissed: () => dismissedCount++,
            childKey: childKey,
          ),
        );

        await _pumpUntilSettled(tester);

        expect(find.byKey(childKey), findsOneWidget);
        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.text('The age of imperialism draweth nigh.'), findsOneWidget);
        expect(find.byType(CtNinePatchButton), findsOneWidget);

        await tester.tap(find.byType(CtNinePatchButton));
        await _pumpUntilSettled(tester);
        expect(find.text('I shall.'), findsOneWidget);

        await tester.tap(find.text('I shall.'));
        await _pumpUntilSettled(tester);

        expect(dismissedCount, 1);
        expect(find.byType(CtDialogShell), findsNothing);
        expect(find.byKey(childKey), findsOneWidget);
      },
    );

    testWidgets(
      'with a Yarn asset missing the intro node: surfaces the error '
      'affordance and Continue still dismisses',
      (WidgetTester tester) async {
        var dismissedCount = 0;

        await tester.pumpWidget(
          _wrapIntroOverlay(
            bundle: _MissingNodeAssetBundle(),
            onDismissed: () => dismissedCount++,
          ),
        );

        await _pumpUntilSettled(tester);

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.byType(CtNinePatchButton), findsOneWidget);

        await tester.tap(find.byType(CtNinePatchButton));
        await _pumpUntilSettled(tester);

        expect(dismissedCount, 1);
      },
    );

    // AC: title region + CtBrassDivider precede the dialogue body in every
    // non-dismissed state. Pins SPEC/ui/game-start-intro-overlay.md
    // § Components and § Acceptance Criteria for the dark editorial-monocle
    // restyle (Refs #2867 S10).
    testWidgets(
      'every non-dismissed state renders the title + CtBrassDivider chrome '
      'in declared order',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrapIntroOverlay(
            bundle: _InlineYarnAssetBundle(_kIntroYarn),
            onDismissed: () {},
          ),
        );
        await _pumpUntilSettled(tester);

        expect(find.text('A New World Awaits'), findsOneWidget);
        expect(find.byType(CtBrassDivider), findsOneWidget);

        await tester.tap(find.byType(CtNinePatchButton));
        await _pumpUntilSettled(tester);

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
          _wrapIntroOverlay(
            bundle: _MissingNodeAssetBundle(),
            onDismissed: () {},
          ),
        );
        await _pumpUntilSettled(tester);

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
          _wrapIntroOverlay(
            bundle: _InlineYarnAssetBundle(_kIntroYarn),
            onDismissed: () {},
          ),
        );
        await _pumpUntilSettled(tester);

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
          tester.widgetList<Material>(find.byType(Material)).any(
            (m) => m.color == Colors.black54,
          ),
          isFalse,
          reason: 'No Material may paint the legacy Colors.black54 scrim.',
        );

        await tester.pumpWidget(
          _wrapIntroOverlay(
            bundle: _MissingNodeAssetBundle(),
            onDismissed: () {},
          ),
        );
        await _pumpUntilSettled(tester);

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
      final source = File(
        'lib/features/game/dialogue/game_start_intro_overlay.dart',
      ).readAsStringSync();
      expect(
        source.contains('Colors.black54'),
        isFalse,
        reason:
            'Refs #2867 S10: intro overlay scrim must resolve from the '
            'EditorialMonoclePalette.dialogScrim token; Colors.black54 was '
            'the legacy hex-literal scrim and must not return.',
      );
      expect(
        source.contains('EditorialMonoclePalette.dialogScrim'),
        isTrue,
        reason:
            'Refs #2867 S10: intro overlay scrim must reference the '
            'canonical EditorialMonoclePalette.dialogScrim token.',
      );
    });
  });

  group('OvertureDialogueOverlay (SPEC/ui/overture-dialogue-overlay.md)', () {
    const Game game = Game(
      id: 'test_overture',
      worldState: WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 4),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: [
        Player(
          id: 'gp_spain',
          displayName: 'Spain',
          isHuman: false,
          treasury: 0,
        ),
        Player(
          id: 'gp_portugal',
          displayName: 'Portugal',
          isHuman: false,
          treasury: 0,
        ),
        Player(
          id: 'gp_player',
          displayName: 'Player',
          isHuman: true,
          treasury: 0,
        ),
      ],
    );

    Widget wrap({
      required List<OvertureOffer> offers,
      required void Function(List<OvertureDecision>) onDecisions,
    }) {
      return MaterialApp(
        theme: AppThemes.colonial,
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: OvertureDialogueOverlay(
            game: game,
            pendingOvertures: offers,
            skipIntroForTest: true,
            onDecisions: onDecisions,
            child: const SizedBox.expand(
              child: Center(child: Text('child-content')),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'phase 2 renders one Accept/Reject row per pending overture and Submit',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrap(
            offers: const [
              OvertureOffer(
                offererGpId: 'gp_spain',
                targetFactionId: 'gp_player',
                stage: OvertureStage.tradeConsulate,
              ),
              OvertureOffer(
                offererGpId: 'gp_portugal',
                targetFactionId: 'gp_player',
                stage: OvertureStage.embassy,
              ),
            ],
            onDecisions: (_) {},
          ),
        );
        await _pumpUntilSettled(tester);

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.text('Accept'), findsNWidgets(2));
        expect(find.text('Reject'), findsNWidgets(2));
        expect(find.text('Submit'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Accept on every row emits one OvertureDecision per offer with accepted=true '
      '(#2867 R23 / AC4 — Submit enables after all decided)',
      (WidgetTester tester) async {
        List<OvertureDecision>? captured;
        await tester.pumpWidget(
          wrap(
            offers: const [
              OvertureOffer(
                offererGpId: 'gp_spain',
                targetFactionId: 'gp_player',
                stage: OvertureStage.tradeConsulate,
              ),
              OvertureOffer(
                offererGpId: 'gp_portugal',
                targetFactionId: 'gp_player',
                stage: OvertureStage.embassy,
              ),
            ],
            onDecisions: (d) => captured = d,
          ),
        );
        await _pumpUntilSettled(tester);

        await tester.tap(find.text('Accept').at(0));
        await _pumpUntilSettled(tester);
        await tester.tap(find.text('Accept').at(1));
        await _pumpUntilSettled(tester);

        await tester.tap(find.text('Submit'));
        await _pumpUntilSettled(tester);

        expect(captured, isNotNull);
        expect(captured!.length, 2);
        expect(captured![0].offererGpId, 'gp_spain');
        expect(captured![0].stage, OvertureStage.tradeConsulate);
        expect(captured![0].accepted, isTrue);
        expect(captured![1].offererGpId, 'gp_portugal');
        expect(captured![1].stage, OvertureStage.embassy);
        expect(captured![1].accepted, isTrue);
      },
    );

    testWidgets(
      'tapping Accept on the first row and Reject on the second row before Submit '
      '(#2867 R23 / AC4 — mixed decision)',
      (WidgetTester tester) async {
        List<OvertureDecision>? captured;
        await tester.pumpWidget(
          wrap(
            offers: const [
              OvertureOffer(
                offererGpId: 'gp_spain',
                targetFactionId: 'gp_player',
                stage: OvertureStage.tradeConsulate,
              ),
              OvertureOffer(
                offererGpId: 'gp_portugal',
                targetFactionId: 'gp_player',
                stage: OvertureStage.embassy,
              ),
            ],
            onDecisions: (d) => captured = d,
          ),
        );
        await _pumpUntilSettled(tester);

        await tester.tap(find.text('Accept').at(0));
        await _pumpUntilSettled(tester);
        await tester.tap(find.text('Reject').at(1));
        await _pumpUntilSettled(tester);

        await tester.tap(find.text('Submit'));
        await _pumpUntilSettled(tester);

        expect(captured, isNotNull);
        expect(captured!.length, 2);
        expect(captured![0].accepted, isTrue);
        expect(captured![1].accepted, isFalse);
        expect(captured![1].offererGpId, 'gp_portugal');
      },
    );

    testWidgets(
      'Submit stays disabled and does not invoke onDecisions while any '
      'overture row is still undecided (#2867 R23 / AC4 negative case)',
      (WidgetTester tester) async {
        List<OvertureDecision>? captured;
        await tester.pumpWidget(
          wrap(
            offers: const [
              OvertureOffer(
                offererGpId: 'gp_spain',
                targetFactionId: 'gp_player',
                stage: OvertureStage.tradeConsulate,
              ),
              OvertureOffer(
                offererGpId: 'gp_portugal',
                targetFactionId: 'gp_player',
                stage: OvertureStage.embassy,
              ),
            ],
            onDecisions: (d) => captured = d,
          ),
        );
        await _pumpUntilSettled(tester);

        // `warnIfMissed: false` because the disabled button intentionally
        // ignores hit-tests (per CtNinePatchButton § Disabled).
        await tester.tap(find.text('Submit'), warnIfMissed: false);
        await _pumpUntilSettled(tester);
        expect(captured, isNull);

        await tester.tap(find.text('Accept').at(0));
        await _pumpUntilSettled(tester);
        await tester.tap(find.text('Submit'), warnIfMissed: false);
        await _pumpUntilSettled(tester);
        expect(
          captured,
          isNull,
          reason:
              'Submit must remain disabled while the second row is still '
              'undecided (#2867 R23).',
        );
      },
    );

    testWidgets('empty offer list still renders Submit and emits empty list', (
      WidgetTester tester,
    ) async {
      List<OvertureDecision>? captured;
      await tester.pumpWidget(
        wrap(offers: const [], onDecisions: (d) => captured = d),
      );
      await _pumpUntilSettled(tester);

      expect(find.text('Accept'), findsNothing);
      expect(find.text('Submit'), findsOneWidget);

      await tester.tap(find.text('Submit'));
      await _pumpUntilSettled(tester);

      expect(captured, isNotNull);
      expect(captured, isEmpty);
    });
  });

  group(
    'CallToArmsDialogueOverlay (SPEC/ui/call-to-arms-dialogue-overlay.md)',
    () {
      const Game game = Game(
        id: 'test_cta',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: [
          Player(
            id: 'gp_spain',
            displayName: 'Spain',
            isHuman: false,
            treasury: 0,
          ),
          Player(
            id: 'gp_portugal',
            displayName: 'Portugal',
            isHuman: false,
            treasury: 0,
          ),
          Player(
            id: 'gp_player',
            displayName: 'Player',
            isHuman: true,
            treasury: 0,
          ),
        ],
      );

      Widget wrap({
        required List<CallToArmsPending> pending,
        required void Function(List<CallToArmsDecision>) onDecisions,
      }) {
        return MaterialApp(
          theme: AppThemes.colonial,
          locale: const Locale('en'),
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: CallToArmsDialogueOverlay(
              game: game,
              pending: pending,
              onDecisions: onDecisions,
              child: const SizedBox.expand(
                child: Center(child: Text('child-content')),
              ),
            ),
          ),
        );
      }

      testWidgets(
        'renders one Join/Refuse row per pending call and resolves names',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            wrap(
              pending: const [
                CallToArmsPending(
                  allyGpId: 'gp_player',
                  defenderGpId: 'gp_portugal',
                  aggressorGpId: 'gp_spain',
                ),
              ],
              onDecisions: (_) {},
            ),
          );
          await _pumpUntilSettled(tester);

          expect(find.byType(CtDialogShell), findsOneWidget);
          expect(find.text('Join'), findsOneWidget);
          expect(find.text('Refuse'), findsOneWidget);
          expect(find.text('Submit'), findsOneWidget);
          expect(find.textContaining('Portugal'), findsOneWidget);
          expect(find.textContaining('Spain'), findsOneWidget);
        },
      );

      testWidgets(
        'tapping Join on every row emits one CallToArmsDecision per pending '
        'with accepted=true (#2867 R25 / AC5 — Submit enables after all decided)',
        (WidgetTester tester) async {
          List<CallToArmsDecision>? captured;
          await tester.pumpWidget(
            wrap(
              pending: const [
                CallToArmsPending(
                  allyGpId: 'gp_player',
                  defenderGpId: 'gp_portugal',
                  aggressorGpId: 'gp_spain',
                ),
                CallToArmsPending(
                  allyGpId: 'gp_player',
                  defenderGpId: 'gp_spain',
                  aggressorGpId: 'gp_portugal',
                ),
              ],
              onDecisions: (d) => captured = d,
            ),
          );
          await _pumpUntilSettled(tester);

          await tester.tap(find.text('Join').at(0));
          await _pumpUntilSettled(tester);
          await tester.tap(find.text('Join').at(1));
          await _pumpUntilSettled(tester);

          await tester.tap(find.text('Submit'));
          await _pumpUntilSettled(tester);

          expect(captured, isNotNull);
          expect(captured!.length, 2);
          expect(captured![0].defenderGpId, 'gp_portugal');
          expect(captured![0].accepted, isTrue);
          expect(captured![1].defenderGpId, 'gp_spain');
          expect(captured![1].accepted, isTrue);
        },
      );

      testWidgets(
        'tapping Refuse on the first row and Join on the second row before Submit '
        '(#2867 R25 / AC5 — mixed decision)',
        (WidgetTester tester) async {
          List<CallToArmsDecision>? captured;
          await tester.pumpWidget(
            wrap(
              pending: const [
                CallToArmsPending(
                  allyGpId: 'gp_player',
                  defenderGpId: 'gp_portugal',
                  aggressorGpId: 'gp_spain',
                ),
                CallToArmsPending(
                  allyGpId: 'gp_player',
                  defenderGpId: 'gp_spain',
                  aggressorGpId: 'gp_portugal',
                ),
              ],
              onDecisions: (d) => captured = d,
            ),
          );
          await _pumpUntilSettled(tester);

          await tester.tap(find.text('Refuse').at(0));
          await _pumpUntilSettled(tester);
          await tester.tap(find.text('Join').at(1));
          await _pumpUntilSettled(tester);

          await tester.tap(find.text('Submit'));
          await _pumpUntilSettled(tester);

          expect(captured, isNotNull);
          expect(captured![0].accepted, isFalse);
          expect(captured![1].accepted, isTrue);
        },
      );

      testWidgets(
        'Submit stays disabled and does not invoke onDecisions while any '
        'call-to-arms row is still undecided (#2867 R25 / AC5 negative case)',
        (WidgetTester tester) async {
          List<CallToArmsDecision>? captured;
          await tester.pumpWidget(
            wrap(
              pending: const [
                CallToArmsPending(
                  allyGpId: 'gp_player',
                  defenderGpId: 'gp_portugal',
                  aggressorGpId: 'gp_spain',
                ),
                CallToArmsPending(
                  allyGpId: 'gp_player',
                  defenderGpId: 'gp_spain',
                  aggressorGpId: 'gp_portugal',
                ),
              ],
              onDecisions: (d) => captured = d,
            ),
          );
          await _pumpUntilSettled(tester);

          // `warnIfMissed: false` because the disabled button intentionally
          // ignores hit-tests (per CtNinePatchButton § Disabled).
          await tester.tap(find.text('Submit'), warnIfMissed: false);
          await _pumpUntilSettled(tester);
          expect(captured, isNull);

          await tester.tap(find.text('Refuse').at(0));
          await _pumpUntilSettled(tester);
          await tester.tap(find.text('Submit'), warnIfMissed: false);
          await _pumpUntilSettled(tester);
          expect(
            captured,
            isNull,
            reason:
                'Submit must remain disabled while the second row is still '
                'undecided (#2867 R25).',
          );
        },
      );

      testWidgets(
        'empty pending list still renders Submit and emits empty list',
        (WidgetTester tester) async {
          List<CallToArmsDecision>? captured;
          await tester.pumpWidget(
            wrap(pending: const [], onDecisions: (d) => captured = d),
          );
          await _pumpUntilSettled(tester);

          expect(find.text('Join'), findsNothing);
          expect(find.text('Submit'), findsOneWidget);

          await tester.tap(find.text('Submit'));
          await _pumpUntilSettled(tester);

          expect(captured, isNotNull);
          expect(captured, isEmpty);
        },
      );

      testWidgets('unknown gp ids fall back to the raw id in prompt text', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          wrap(
            pending: const [
              CallToArmsPending(
                allyGpId: 'gp_player',
                defenderGpId: 'gp_unknown_defender',
                aggressorGpId: 'gp_unknown_aggressor',
              ),
            ],
            onDecisions: (_) {},
          ),
        );
        await _pumpUntilSettled(tester);

        expect(find.textContaining('gp_unknown_defender'), findsOneWidget);
        expect(find.textContaining('gp_unknown_aggressor'), findsOneWidget);
      });
    },
  );
}
