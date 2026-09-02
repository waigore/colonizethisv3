// SPEC/ui/next-turn-confirmation.md + staged-decree-review.md — DLG60001 staged section.

import 'package:colonizethis_app/features/game/flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_go_to.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

const _oneFamily = StagedDecreeReview(
  families: [
    StagedDecreeFamilyGroup(
      family: StagedDecreeFamily.armyMoves,
      familyLabel: 'Army moves',
      count: 1,
      rows: [StagedDecreeRow(id: 'a1', label: 'Army a1 → Alpha')],
    ),
  ],
);

const _multiFamily = StagedDecreeReview(
  families: [
    StagedDecreeFamilyGroup(
      family: StagedDecreeFamily.civilianWork,
      familyLabel: 'Civilian work',
      count: 1,
      rows: [StagedDecreeRow(id: 'w1', label: 'Explorer: Explore')],
    ),
    StagedDecreeFamilyGroup(
      family: StagedDecreeFamily.trade,
      familyLabel: 'Trade',
      count: 1,
      rows: [StagedDecreeRow(id: 't1', label: 'Bid Grain × 10')],
    ),
  ],
);

void main() {
  suppressLogsForTests();

  testWidgets(
    'Given a staged draft When DLG60001 opens Then compact summary lists families',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: const Scaffold(
            body: Center(
              child: NextTurnConfirmationDialog(
                currentTurn: 7,
                stagedReview: _oneFamily,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STAGED THIS TURN'), findsOneWidget);
      expect(find.text('Army moves (1)'), findsOneWidget);
      expect(find.text('Review decrees'), findsOneWidget);
      expect(find.text('Army a1 → Alpha'), findsNothing);
      expect(find.textContaining('no decrees'), findsNothing);
      expect(find.text('Yes'), findsOneWidget);
    },
  );

  testWidgets(
    'Given an empty draft When DLG60001 opens Then no staged nag is shown',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: const Scaffold(
            body: Center(child: NextTurnConfirmationDialog(currentTurn: 7)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STAGED THIS TURN'), findsNothing);
      expect(find.text('Review decrees'), findsNothing);
      expect(find.textContaining('no decrees'), findsNothing);
    },
  );

  testWidgets(
    'Given a multi-family draft When Review decrees is tapped Then rows and go-to render',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: const Scaffold(
            body: Center(
              child: NextTurnConfirmationDialog(
                currentTurn: 12,
                stagedReview: _multiFamily,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review decrees'));
      await tester.pumpAndSettle();

      expect(find.text('Explorer: Explore'), findsOneWidget);
      expect(find.text('Bid Grain × 10'), findsOneWidget);
      expect(find.text('ArmyMoveOrder'), findsNothing);
      expect(
        find.byKey(const ValueKey('staged-decree-locate-civilianWork')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('staged-decree-locate-trade')),
        findsOneWidget,
      );
    },
  );

  testWidgets('Given staged rows When go-to is tapped Then confirm aborts', (
    WidgetTester tester,
  ) async {
    StagedDecreeFamily? goneTo;
    NextTurnConfirmationResult? result;
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await showNextTurnConfirmationDialog(
                    context,
                    currentTurn: 4,
                    stagedReview: _oneFamily,
                    onGoToStagedFamily: (family) => goneTo = family,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review decrees'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('staged-decree-locate-armyMoves')),
    );
    await tester.pumpAndSettle();

    expect(goneTo, StagedDecreeFamily.armyMoves);
    expect(result?.confirmed, isFalse);
  });

  testWidgets('Given staged decrees When Yes is shown Then Yes stays enabled', (
    WidgetTester tester,
  ) async {
    NextTurnConfirmationResult? result;
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await showNextTurnConfirmationDialog(
                    context,
                    currentTurn: 4,
                    stagedReview: _multiFamily,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(CtNinePatchButton), findsNWidgets(2));
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(result?.confirmed, isTrue);
  });

  test('army-move go-to emits OpenMilitaryUnitsPanelEvent', () async {
    final bus = AppEventBus();
    final received = <OpenMilitaryUnitsPanelEvent>[];
    final sub = bus.on<OpenMilitaryUnitsPanelEvent>().listen(received.add);
    emitStagedDecreeGoTo(
      bus: bus,
      game: buildPanelTestGame(),
      humanPlayerId: kPanelTestHumanPlayerId,
      orders: const Orders(),
      family: StagedDecreeFamily.armyMoves,
    );
    await Future<void>.value();
    expect(received, hasLength(1));
    await sub.cancel();
  });

  testWidgets('staged section uses CtDialogShell chrome', (tester) async {
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: const Scaffold(
          body: Center(
            child: NextTurnConfirmationDialog(
              currentTurn: 1,
              stagedReview: _oneFamily,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(CtDialogShell), findsOneWidget);
    expect(find.byType(CtIconAction), findsNothing);
  });
}
