// Dialogue system tests aligned with SPEC/ai/dialogue-management.md and SPEC/ui/dialogue-presentation.md ACs.
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart'
    show GameStartIntroLoadingIndicator, GameStartIntroOverlay;
import 'package:colonizethis_app/features/game/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

class _ThrowingAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    throw Exception('missing asset');
  }
}

void main() {
  suppressLogsForTests();

  group(
    'GameStartIntroOverlay — SPEC/ai/dialogue-management.md § First dialogue emission point',
    () {
      testWidgets(
        'GameStartIntroLoadingIndicator uses 48 px --accent spinner (Refs #2867 R28)',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(body: GameStartIntroLoadingIndicator()),
            ),
          );
          final indicator = tester.widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          );
          expect(indicator.color, EditorialMonoclePalette.accent);
          expect(indicator.strokeWidth, 2);
          final sizedBox = tester.widget<SizedBox>(
            find.ancestor(
              of: find.byType(CircularProgressIndicator),
              matching: find.byType(SizedBox),
            ),
          );
          expect(sizedBox.width, 48);
          expect(sizedBox.height, 48);
        },
      );

      testWidgets(
        'AC: asset load failure shows error shell; Continue invokes onDismissed',
        (WidgetTester tester) async {
          var dismissed = false;
          await tester.pumpWidget(
            MaterialApp(
              home: GameStartIntroOverlay(
                assetBundle: _ThrowingAssetBundle(),
                onDismissed: () => dismissed = true,
                child: const SizedBox(),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(
            find.textContaining('Could not load intro dialogue'),
            findsOneWidget,
          );
          await tester.tap(find.text('Continue'));
          await tester.pump();
          expect(dismissed, isTrue);
        },
      );

      testWidgets(
        'AC: modal uses CtDialogShell and blocks; intro text and Continue present',
        (WidgetTester tester) async {
          var dismissed = false;
          await tester.pumpWidget(
            MaterialApp(
              home: GameStartIntroOverlay(
                onDismissed: () => dismissed = true,
                child: const SizedBox(),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pumpAndSettle(const Duration(seconds: 5));
          expect(find.byType(CtDialogShell), findsOneWidget);
          expect(dismissed, isFalse);
          expect(find.textContaining('imperialism'), findsOneWidget);
          expect(find.byType(CtNinePatchButton), findsWidgets);
        },
      );
    },
  );

  group('OvertureDialogueOverlay — SPEC/ui/dialogue-presentation.md AC', () {
    Game minimalGame() {
      return Game(
        id: 'test',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: [
          Player(id: 'gp1', displayName: 'France', isHuman: false, treasury: 0),
        ],
      );
    }

    testWidgets(
      'AC: modal with CtDialogShell; Accept/Reject per offer; Submit calls onDecisions with OvertureDecision list',
      (WidgetTester tester) async {
        List<OvertureDecision>? captured;
        final game = minimalGame();
        final offers = [
          const OvertureOffer(
            offererGpId: 'gp1',
            targetFactionId: 'gp2',
            stage: OvertureStage.embassy,
          ),
        ];
        await tester.pumpWidget(
          MaterialApp(
            home: OvertureDialogueOverlay(
              game: game,
              pendingOvertures: offers,
              skipIntroForTest: true,
              onDecisions: (decisions) => captured = decisions,
              child: const SizedBox(),
            ),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.text('Diplomatic overtures'), findsOneWidget);
        expect(find.text('Accept'), findsWidgets);
        expect(find.text('Reject'), findsWidgets);
        expect(find.text('Submit'), findsOneWidget);
        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();
        expect(captured, isNotNull);
        expect(captured!.length, 1);
        expect(captured!.single.offererGpId, 'gp1');
        expect(captured!.single.targetFactionId, 'gp2');
        expect(captured!.single.stage, OvertureStage.embassy);
        expect(captured!.single.accepted, isFalse);
      },
    );

    testWidgets('AC: pixel-art — CtDialogShell and CtNinePatchButton used', (
      WidgetTester tester,
    ) async {
      final game = minimalGame();
      final offers = [
        const OvertureOffer(
          offererGpId: 'gp1',
          targetFactionId: 'gp2',
          stage: OvertureStage.tradeConsulate,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: OvertureDialogueOverlay(
            game: game,
            pendingOvertures: offers,
            skipIntroForTest: true,
            onDecisions: (_) {},
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsWidgets);
    });
  });
}
