// Full-widget open-to-interactive profiling anchors for turn-shell surfaces
// DLG60001, DLG50001, OVL70001 (Refs #4715 Slice 1).
//
// CI surrogate for profile/release DevTools sessions on binding hosts: measures
// pump-to-interactive on representative fixtures. Not a debug wall-clock 1s
// assertion — the standing 1 000 ms gate is profile/release on Linux desktop
// and Android emulator (see SPEC/program/ui-surface-budget.md).

import 'package:colonizethis_app/features/game/flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_logic/civilian_intel_api.dart'
    show CivilianMissingWorkOrderEntry;
import 'package:colonizethis_app/features/game/widgets/dialogs/turn_news_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

final Game _turnNewsGame = Game(
  id: 'turn-shell-budget',
  worldState: const WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
    oldWorld: RegionData(),
    newWorld: RegionData(),
  ),
  players: const [
    Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
    Player(id: 'gp2', displayName: 'France', isHuman: false, treasury: 0),
  ],
);

void main() {
  suppressLogsForTests();

  Future<int> pumpToInteractive(WidgetTester tester, Widget child) async {
    final sw = Stopwatch()..start();
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Center(child: child),
      ),
    );
    await tester.pump();
    await tester.pump();
    sw.stop();
    return sw.elapsedMilliseconds;
  }

  testWidgets(
    'DLG60001 next-turn confirm paints title and Yes/No (Refs #4715)',
    (WidgetTester tester) async {
      final elapsedMs = await pumpToInteractive(
        tester,
        const NextTurnConfirmationDialog(currentTurn: 3),
      );
      expect(find.text('End turn?'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(elapsedMs, greaterThan(0));
      expect(ctAppPerfSurfaceOpenElapsedMs('nextTurnConfirm'), isNotNull);
    },
  );

  testWidgets(
    'DLG60001 idle-civilian warning on first open with compact staged summary (Refs #4715 AC3)',
    (WidgetTester tester) async {
      const staged = StagedDecreeReview(
        families: [
          StagedDecreeFamilyGroup(
            family: StagedDecreeFamily.diplomacy,
            familyLabel: 'Diplomacy',
            count: 1,
            rows: [
              StagedDecreeRow(id: 'd1', label: 'Offer peace to France'),
            ],
          ),
        ],
      );
      const idleCivilian = CivilianMissingWorkOrderEntry(
        unitId: 'e1',
        type: 'explorer',
        tileKey: 'oldWorld|p1|0|0',
        regionId: 'oldWorld',
        locationLabel: 'Old World — Alpha',
      );
      final elapsedMs = await pumpToInteractive(
        tester,
        const NextTurnConfirmationDialog(
          currentTurn: 4,
          stagedReview: staged,
          civiliansMissingWork: [idleCivilian],
        ),
      );
      expect(
        find.text('These civilians have no work order for the next turn:'),
        findsOneWidget,
      );
      expect(find.text('explorer'), findsOneWidget);
      expect(find.text('No work order'), findsOneWidget);
      expect(find.text('STAGED THIS TURN'), findsOneWidget);
      expect(find.text('Diplomacy (1)'), findsOneWidget);
      expect(find.text('Offer peace to France'), findsNothing);
      expect(elapsedMs, greaterThan(0));
      expect(ctAppPerfSurfaceOpenElapsedMs('nextTurnConfirm'), isNotNull);
    },
  );

  testWidgets(
    'DLG60001 compact staged summary without expanded rows (Refs #4715)',
    (WidgetTester tester) async {
      const staged = StagedDecreeReview(
        families: [
          StagedDecreeFamilyGroup(
            family: StagedDecreeFamily.civilianWork,
            familyLabel: 'Civilian work',
            count: 1,
            rows: [
              StagedDecreeRow(id: 'w1', label: 'Explorer — explore Bavaria'),
            ],
          ),
        ],
      );
      await pumpToInteractive(
        tester,
        const NextTurnConfirmationDialog(
          currentTurn: 4,
          stagedReview: staged,
        ),
      );
      expect(find.text('STAGED THIS TURN'), findsOneWidget);
      expect(find.text('Civilian work (1)'), findsOneWidget);
      expect(find.text('Explorer — explore Bavaria'), findsNothing);
    },
  );

  testWidgets(
    'DLG50001 turn news paints title and Close (Refs #4715)',
    (WidgetTester tester) async {
      final elapsedMs = await pumpToInteractive(
        tester,
        TurnNewsDialog(
          game: _turnNewsGame,
          digest: const TurnNewsDigest(
            resolvedTurnNumber: 1,
            lines: [
              TurnNewsDiplomacyLine(
                factionIdA: 'gp1',
                factionIdB: 'gp2',
                kind: TurnNewsDiplomacyKind.peace,
              ),
            ],
          ),
          newTurnNumber: 2,
        ),
      );
      expect(find.textContaining('Turn 2'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);
      expect(elapsedMs, greaterThan(0));
      expect(ctAppPerfSurfaceOpenElapsedMs('turnNews'), isNotNull);
    },
  );

  testWidgets(
    'OVL70001 event feed card paints rows or empty copy (Refs #4715)',
    (WidgetTester tester) async {
      final elapsedMs = await pumpToInteractive(
        tester,
        const PlayerTurnEventFeedCard(
          entries: [
            PlayerTurnEventFeedEntry(text: 'Research complete: Printing press.'),
          ],
          emptyLabel: 'No events this turn.',
        ),
      );
      expect(
        find.text('Research complete: Printing press.'),
        findsOneWidget,
      );
      expect(elapsedMs, greaterThan(0));
      expect(ctAppPerfSurfaceOpenElapsedMs('playerTurnEventFeed'), isNotNull);
    },
  );
}
