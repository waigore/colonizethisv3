// Wide regression sentinel for DiplomacyDetailScreen @ 320 dp (Refs #4734 Slice F).
// Default pins: diplomacy_detail_screen_320dp_min_viewport_test.dart.
//
// SPEC: SPEC/ui/mobile-adaptation.md § 7; SPEC/ui/diplomacy-detail-screen.md.

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_detail_screen_320dp_min_viewport_support.dart';
import 'diplomacy_detail_screen_test_support.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await preloadNinePatchImage();
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — DiplomacyDetailScreen wide '
      'regression sentinel (Refs #2870 S10)', () {
    testWidgets('Negative control: DiplomacyDetailScreen greatPower @ '
        '1024×768 also pumps without exception (regression sentinel '
        'for the overflow contract — keeps the 320 dp positive pins '
        'meaningful)', (WidgetTester tester) async {
      final game = diplomacyDetailMinimalGame(
        includeHistory: true,
        includeDossier: true,
        atWar: false,
        eventType: DiplomaticEventType.declareWar,
      );
      final relation = getRelation(
        game,
        diplomacyDetailHumanId,
        diplomacyDetailOtherId,
      );

      await pumpDiplomacyDetailScreen320(
        tester,
        size: kDiplomacyDetailScreen320WideViewport,
        game: game,
        kind: FactionKind.greatPower,
        relation: relation,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CtTopBar), findsOneWidget);
      expect(find.text('CURRENT RELATION'), findsOneWidget);
      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      expect(find.text('DOSSIER'), findsOneWidget);
    });
  });
}
