import 'package:colonizethis_app/features/game/flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/turn_news_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/foundation.dart' show kProfileMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/app_shell_harness.dart';

/// Profile/release open-to-interactive measurement for turn-shell surfaces
/// DLG60001, DLG50001, OVL70001 (Refs #4715).
///
/// From repo root: `tool/run_ui_surface_profile_evidence.sh turn-shell`
void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final game = Game(
    id: 'turn-shell-profile',
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

  Future<void> assertSurfaceOpenBudget(String surfaceId) async {
    final elapsedMs = ctAppPerfSurfaceOpenElapsedMs(surfaceId);
    expect(elapsedMs, isNotNull);
    if (kProfileMode || kReleaseMode) {
      ctAppPerfLogUiSurfaceOpen(surfaceId, elapsedMs!);
      expect(
        elapsedMs,
        lessThanOrEqualTo(kUiSurfaceOpenBudgetMs),
        reason:
            '$surfaceId open-to-interactive exceeded $kUiSurfaceOpenBudgetMs ms',
      );
    }
  }

  testWidgets(
    'DLG60001 interactiveReady within 1s on profile/release binding host',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: const Center(
            child: NextTurnConfirmationDialog(
              currentTurn: 5,
              stagedReview: StagedDecreeReview(
                families: [
                  StagedDecreeFamilyGroup(
                    family: StagedDecreeFamily.diplomacy,
                    familyLabel: 'Diplomacy',
                    rows: [
                      StagedDecreeRow(
                        id: 'd1',
                        label: 'Offer peace to France',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('End turn?'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      await assertSurfaceOpenBudget('nextTurnConfirm');
    },
  );

  testWidgets(
    'DLG50001 interactiveReady within 1s on profile/release binding host',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: Center(
            child: TurnNewsDialog(
              game: game,
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
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(CtNinePatchButton), findsOneWidget);
      await assertSurfaceOpenBudget('turnNews');
    },
  );

  testWidgets(
    'OVL70001 interactiveReady within 1s on profile/release binding host',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: const Center(
            child: PlayerTurnEventFeedCard(
              entries: [
                PlayerTurnEventFeedEntry(
                  text: 'Realm economy: treasury +£120 this turn.',
                ),
              ],
              emptyLabel: 'No events this turn.',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        find.text('Realm economy: treasury +£120 this turn.'),
        findsOneWidget,
      );
      await assertSurfaceOpenBudget('playerTurnEventFeed');
    },
  );
}
