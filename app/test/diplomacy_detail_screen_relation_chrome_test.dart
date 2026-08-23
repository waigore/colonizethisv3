// GAME30002 current-relation chrome pins (Refs #4606 Slice D).
// SPEC: SPEC/ui/diplomacy-detail-screen.md.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_detail_screen_test_support.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await preloadNinePatchImage();
  });

  group('current relation card chrome', () {
    for (final c
        in <
          ({
            String name,
            Game Function() game,
            void Function(WidgetTester tester) assertUi,
          })
        >[
          (
            name: 'War label in --danger colour',
            game: () => diplomacyDetailMinimalGame(
              eventType: DiplomaticEventType.declareWar,
              atWar: true,
            ),
            assertUi: (tester) {
              expect(find.text('CURRENT RELATION'), findsOneWidget);
              final Text war = tester.widget(find.text('War'));
              expect(war.style?.color, EditorialMonoclePalette.danger);
            },
          ),
          (
            name: 'Peace label in --success colour',
            game: diplomacyDetailMinimalGame,
            assertUi: (tester) {
              expect(find.text('CURRENT RELATION'), findsOneWidget);
              final Text peace = tester.widget(find.text('Peace'));
              expect(peace.style?.color, EditorialMonoclePalette.success);
            },
          ),
          (
            name:
                'ALLIANCE badge in --accent for formal alliance (Refs #3625 AC4)',
            game: () => diplomacyDetailMinimalGame(
              eventType: DiplomaticEventType.allianceFormed,
              score: 90,
              formalAlliance: true,
            ),
            assertUi: (tester) {
              expect(find.text('CURRENT RELATION'), findsOneWidget);
              final Finder badge = find.text(kDiplomacyAllianceBadgeLabel);
              expect(badge, findsOneWidget);
              final Text badgeText = tester.widget<Text>(badge);
              expect(badgeText.style?.color, EditorialMonoclePalette.accent);
              expect(kDiplomacyAllianceBadgeLabel, isNot('Friendly'));
            },
          ),
          (
            name:
                'omits ALLIANCE badge for informal Allied band (Refs #3625 AC4 negative)',
            game: () => diplomacyDetailMinimalGame(score: 90),
            assertUi: (tester) {
              expect(find.text('CURRENT RELATION'), findsOneWidget);
              expect(find.text(kDiplomacyAllianceBadgeLabel), findsNothing);
              expect(find.textContaining('Devoted'), findsOneWidget);
            },
          ),
        ]) {
      testWidgets(c.name, (WidgetTester tester) async {
        final game = c.game();
        final relation = getRelation(
          game,
          diplomacyDetailHumanId,
          diplomacyDetailOtherId,
        );
        expect(relation, isNotNull);
        await pumpDiplomacyDetailOtherGp(
          tester,
          game: game,
          relation: relation,
        );
        c.assertUi(tester);
      });
    }
  });
}
