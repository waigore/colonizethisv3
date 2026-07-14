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

// Split under repo.app_test_file_size (Refs #4013) — part 2:
// OvertureDialogueOverlay + CallToArmsDialogueOverlay.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/call_to_arms_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dialogue_overlays_specs_test_support.dart';

void main() {
  suppressLogsForTests();

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
        await pumpDialogueOverlaysUntilSettled(tester);

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
        await pumpDialogueOverlaysUntilSettled(tester);

        await tester.tap(find.text('Accept').at(0));
        await pumpDialogueOverlaysUntilSettled(tester);
        await tester.tap(find.text('Accept').at(1));
        await pumpDialogueOverlaysUntilSettled(tester);

        await tester.tap(find.text('Submit'));
        await pumpDialogueOverlaysUntilSettled(tester);

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
        await pumpDialogueOverlaysUntilSettled(tester);

        await tester.tap(find.text('Accept').at(0));
        await pumpDialogueOverlaysUntilSettled(tester);
        await tester.tap(find.text('Reject').at(1));
        await pumpDialogueOverlaysUntilSettled(tester);

        await tester.tap(find.text('Submit'));
        await pumpDialogueOverlaysUntilSettled(tester);

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
        await pumpDialogueOverlaysUntilSettled(tester);

        // `warnIfMissed: false` because the disabled button intentionally
        // ignores hit-tests (per CtNinePatchButton § Disabled).
        await tester.tap(find.text('Submit'), warnIfMissed: false);
        await pumpDialogueOverlaysUntilSettled(tester);
        expect(captured, isNull);

        await tester.tap(find.text('Accept').at(0));
        await pumpDialogueOverlaysUntilSettled(tester);
        await tester.tap(find.text('Submit'), warnIfMissed: false);
        await pumpDialogueOverlaysUntilSettled(tester);
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
      await pumpDialogueOverlaysUntilSettled(tester);

      expect(find.text('Accept'), findsNothing);
      expect(find.text('Submit'), findsOneWidget);

      await tester.tap(find.text('Submit'));
      await pumpDialogueOverlaysUntilSettled(tester);

      expect(captured, isNotNull);
      expect(captured, isEmpty);
    });
  });

  group('CallToArmsDialogueOverlay (SPEC/ui/call-to-arms-dialogue-overlay.md)', () {
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
        await pumpDialogueOverlaysUntilSettled(tester);

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
        await pumpDialogueOverlaysUntilSettled(tester);

        await tester.tap(find.text('Join').at(0));
        await pumpDialogueOverlaysUntilSettled(tester);
        await tester.tap(find.text('Join').at(1));
        await pumpDialogueOverlaysUntilSettled(tester);

        await tester.tap(find.text('Submit'));
        await pumpDialogueOverlaysUntilSettled(tester);

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
        await pumpDialogueOverlaysUntilSettled(tester);

        await tester.tap(find.text('Refuse').at(0));
        await pumpDialogueOverlaysUntilSettled(tester);
        await tester.tap(find.text('Join').at(1));
        await pumpDialogueOverlaysUntilSettled(tester);

        await tester.tap(find.text('Submit'));
        await pumpDialogueOverlaysUntilSettled(tester);

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
        await pumpDialogueOverlaysUntilSettled(tester);

        // `warnIfMissed: false` because the disabled button intentionally
        // ignores hit-tests (per CtNinePatchButton § Disabled).
        await tester.tap(find.text('Submit'), warnIfMissed: false);
        await pumpDialogueOverlaysUntilSettled(tester);
        expect(captured, isNull);

        await tester.tap(find.text('Refuse').at(0));
        await pumpDialogueOverlaysUntilSettled(tester);
        await tester.tap(find.text('Submit'), warnIfMissed: false);
        await pumpDialogueOverlaysUntilSettled(tester);
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
        await pumpDialogueOverlaysUntilSettled(tester);

        expect(find.text('Join'), findsNothing);
        expect(find.text('Submit'), findsOneWidget);

        await tester.tap(find.text('Submit'));
        await pumpDialogueOverlaysUntilSettled(tester);

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
      await pumpDialogueOverlaysUntilSettled(tester);

      expect(find.textContaining('gp_unknown_defender'), findsOneWidget);
      expect(find.textContaining('gp_unknown_aggressor'), findsOneWidget);
    });
  });
}
