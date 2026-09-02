// Session cache + compact expand path for DLG60001 staged review (Refs #4715).

import 'package:colonizethis_app/features/game/flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review_builder.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review_session_cache.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

const _human = kPanelTestHumanPlayerId;
final _l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  suppressLogsForTests();

  tearDown(StagedDecreeReviewSessionCache.clear);

  testWidgets(
    'Given compact staged review When Review decrees expands Then rows render',
    (WidgetTester tester) async {
      final game = buildPanelTestGame(
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: kOldWorldRegionId,
            displayName: 'Alpha',
          ),
        ],
        oldWorldUnits: [
          Unit(
            id: 'e1',
            type: kUnitTypeExplorer,
            ownerId: _human,
            locationProvinceId: 'oldWorld|p1',
            tileKey: 'oldWorld|p1|0|0',
          ),
        ],
      );
      const orders = Orders(
        workOrdersByPlayerId: {
          _human: [
            WorkOrder(
              unitId: 'e1',
              target: kWorkTargetExplore,
              targetTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );
      final compact = buildStagedDecreeReview(
        orders: orders,
        humanPlayerId: _human,
        l10n: _l10n,
        game: game,
      );
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: Scaffold(
            body: Center(
              child: NextTurnConfirmationDialog(
                currentTurn: 3,
                stagedReview: compact,
                expandStagedReview: () => expandStagedDecreeReview(
                  compact: compact,
                  orders: orders,
                  humanPlayerId: _human,
                  l10n: _l10n,
                  game: game,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Civilian work (1)'), findsOneWidget);
      expect(find.textContaining(kUnitTypeExplorer), findsNothing);

      await tester.tap(find.text('Review decrees'));
      await tester.pumpAndSettle();

      expect(find.textContaining(kUnitTypeExplorer), findsOneWidget);
    },
  );

  test('session cache reuses expanded review for same Orders identity', () {
    const orders = Orders(
      armyMoveOrdersByPlayerId: {
        _human: [
          ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'oldWorld|p1'),
        ],
      },
    );
    final compact = buildStagedDecreeReview(
      orders: orders,
      humanPlayerId: _human,
      l10n: _l10n,
    );
    expect(StagedDecreeReviewSessionCache.readExpandedFor(orders), isNull);
    final expanded = expandStagedDecreeReview(
      compact: compact,
      orders: orders,
      humanPlayerId: _human,
      l10n: _l10n,
    );
    StagedDecreeReviewSessionCache.storeExpanded(
      orders: orders,
      expanded: expanded,
    );
    expect(
      identical(
        StagedDecreeReviewSessionCache.readExpandedFor(orders),
        expanded,
      ),
      isTrue,
    );
  });
}
