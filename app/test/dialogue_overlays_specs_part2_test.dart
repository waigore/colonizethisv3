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
/// Refs GitHub #2753. In-file pump/decision helpers densify mid-size fixtures
/// (Refs #4021).
library;

// Split under repo.app_test_file_size (Refs #4013) — part 2:
// OvertureDialogueOverlay + CallToArmsDialogueOverlay.

import 'package:colonizethis_app/features/game/widgets/dialogue/call_to_arms_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';
import 'support/dialogue_overlays_specs_test_support.dart';

const Game _gpTrioGame = Game(
  id: 'test_gp_trio',
  worldState: WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: 4),
    oldWorld: RegionData(),
    newWorld: RegionData(),
  ),
  players: [
    Player(id: 'gp_spain', displayName: 'Spain', isHuman: false, treasury: 0),
    Player(
      id: 'gp_portugal',
      displayName: 'Portugal',
      isHuman: false,
      treasury: 0,
    ),
    Player(id: 'gp_player', displayName: 'Player', isHuman: true, treasury: 0),
  ],
);

const List<OvertureOffer> _twoOvertureOffers = [
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
];

const List<CallToArmsPending> _twoCtaPending = [
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
];

Widget _shell(Widget body) {
  // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
  return buildAppShell(
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    child: Scaffold(body: body),
  );
}

Future<void> _tapSettle(
  WidgetTester tester,
  Finder finder, {
  bool warnIfMissed = true,
}) async {
  await tester.tap(finder, warnIfMissed: warnIfMissed);
  await pumpDialogueOverlaysUntilSettled(tester);
}

void main() {
  suppressLogsForTests();

  group('OvertureDialogueOverlay (SPEC/ui/overture-dialogue-overlay.md)', () {
    Widget wrap({
      required List<OvertureOffer> offers,
      required void Function(List<OvertureDecision>) onDecisions,
    }) {
      return _shell(
        OvertureDialogueOverlay(
          game: _gpTrioGame,
          pendingOvertures: offers,
          skipIntroForTest: true,
          onDecisions: onDecisions,
          child: const SizedBox.expand(
            child: Center(child: Text('child-content')),
          ),
        ),
      );
    }

    Future<void> pumpOverture(
      WidgetTester tester, {
      List<OvertureOffer> offers = _twoOvertureOffers,
      void Function(List<OvertureDecision>)? onDecisions,
    }) async {
      await tester.pumpWidget(
        wrap(offers: offers, onDecisions: onDecisions ?? (_) {}),
      );
      await pumpDialogueOverlaysUntilSettled(tester);
    }

    testWidgets(
      'phase 2 renders one Accept/Reject row per pending overture and Submit',
      (WidgetTester tester) async {
        await pumpOverture(tester);
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
        await pumpOverture(tester, onDecisions: (d) => captured = d);

        await _tapSettle(tester, find.text('Accept').at(0));
        await _tapSettle(tester, find.text('Accept').at(1));
        await _tapSettle(tester, find.text('Submit'));

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
        await pumpOverture(tester, onDecisions: (d) => captured = d);

        await _tapSettle(tester, find.text('Accept').at(0));
        await _tapSettle(tester, find.text('Reject').at(1));
        await _tapSettle(tester, find.text('Submit'));

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
        await pumpOverture(tester, onDecisions: (d) => captured = d);

        // `warnIfMissed: false` because the disabled button intentionally
        // ignores hit-tests (per CtNinePatchButton § Disabled).
        await _tapSettle(tester, find.text('Submit'), warnIfMissed: false);
        expect(captured, isNull);

        await _tapSettle(tester, find.text('Accept').at(0));
        await _tapSettle(tester, find.text('Submit'), warnIfMissed: false);
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
      await pumpOverture(
        tester,
        offers: const [],
        onDecisions: (d) => captured = d,
      );

      expect(find.text('Accept'), findsNothing);
      expect(find.text('Submit'), findsOneWidget);

      await _tapSettle(tester, find.text('Submit'));
      expect(captured, isNotNull);
      expect(captured, isEmpty);
    });
  });

  group('CallToArmsDialogueOverlay (SPEC/ui/call-to-arms-dialogue-overlay.md)', () {
    Widget wrap({
      required List<CallToArmsPending> pending,
      required void Function(List<CallToArmsDecision>) onDecisions,
    }) {
      return _shell(
        CallToArmsDialogueOverlay(
          game: _gpTrioGame,
          pending: pending,
          onDecisions: onDecisions,
          child: const SizedBox.expand(
            child: Center(child: Text('child-content')),
          ),
        ),
      );
    }

    Future<void> pumpCta(
      WidgetTester tester, {
      List<CallToArmsPending> pending = _twoCtaPending,
      void Function(List<CallToArmsDecision>)? onDecisions,
    }) async {
      await tester.pumpWidget(
        wrap(pending: pending, onDecisions: onDecisions ?? (_) {}),
      );
      await pumpDialogueOverlaysUntilSettled(tester);
    }

    testWidgets(
      'renders one Join/Refuse row per pending call and resolves names',
      (WidgetTester tester) async {
        await pumpCta(
          tester,
          pending: const [
            CallToArmsPending(
              allyGpId: 'gp_player',
              defenderGpId: 'gp_portugal',
              aggressorGpId: 'gp_spain',
            ),
          ],
        );

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
        await pumpCta(tester, onDecisions: (d) => captured = d);

        await _tapSettle(tester, find.text('Join').at(0));
        await _tapSettle(tester, find.text('Join').at(1));
        await _tapSettle(tester, find.text('Submit'));

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
        await pumpCta(tester, onDecisions: (d) => captured = d);

        await _tapSettle(tester, find.text('Refuse').at(0));
        await _tapSettle(tester, find.text('Join').at(1));
        await _tapSettle(tester, find.text('Submit'));

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
        await pumpCta(tester, onDecisions: (d) => captured = d);

        // `warnIfMissed: false` because the disabled button intentionally
        // ignores hit-tests (per CtNinePatchButton § Disabled).
        await _tapSettle(tester, find.text('Submit'), warnIfMissed: false);
        expect(captured, isNull);

        await _tapSettle(tester, find.text('Refuse').at(0));
        await _tapSettle(tester, find.text('Submit'), warnIfMissed: false);
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
        await pumpCta(
          tester,
          pending: const [],
          onDecisions: (d) => captured = d,
        );

        expect(find.text('Join'), findsNothing);
        expect(find.text('Submit'), findsOneWidget);

        await _tapSettle(tester, find.text('Submit'));
        expect(captured, isNotNull);
        expect(captured, isEmpty);
      },
    );

    testWidgets('unknown gp ids fall back to the raw id in prompt text', (
      WidgetTester tester,
    ) async {
      await pumpCta(
        tester,
        pending: const [
          CallToArmsPending(
            allyGpId: 'gp_player',
            defenderGpId: 'gp_unknown_defender',
            aggressorGpId: 'gp_unknown_aggressor',
          ),
        ],
      );

      expect(find.textContaining('gp_unknown_defender'), findsOneWidget);
      expect(find.textContaining('gp_unknown_aggressor'), findsOneWidget);
    });
  });
}
