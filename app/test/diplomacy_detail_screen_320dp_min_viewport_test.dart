// Pin the 320 dp minimum-viewport contract for the `DiplomacyDetailScreen`
// (GAME30002) full-screen feature route (Refs #2870 S10).
//
// SPEC: SPEC/ui/mobile-adaptation.md § 7; SPEC/ui/diplomacy-detail-screen.md.
// Wide regression sentinel: diplomacy_detail_screen_320dp_min_viewport_observe_test.dart.

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
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

  group('SPEC/ui/mobile-adaptation.md § 7 — DiplomacyDetailScreen (great '
      'power, history + dossier) @ 320 dp (Refs #2870 S10)', () {
    testWidgets('AC (positive) DiplomacyDetailScreen greatPower @ 320×640: no '
        'RenderFlex overflow exception, dark CtTopBar (title = faction '
        'displayName) + CtBackButton + all three card titles render', (
      WidgetTester tester,
    ) async {
      final game = diplomacyDetailMinimalGame(
        includeHistory: true,
        includeDossier: true,
        atWar: true,
        eventType: DiplomaticEventType.declareWar,
      );
      final relation = getRelation(
        game,
        diplomacyDetailHumanId,
        diplomacyDetailOtherId,
      );

      await pumpDiplomacyDetailScreen320(
        tester,
        size: kDiplomacyDetailScreen320MinViewport,
        game: game,
        kind: FactionKind.greatPower,
        relation: relation,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: DiplomacyDetailScreen '
            'must not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp).',
      );

      final topBarFinder = find.byType(CtTopBar);
      expect(topBarFinder, findsOneWidget);
      final CtTopBar topBar = tester.widget<CtTopBar>(topBarFinder);
      expect(topBar.title, 'Other GP');

      expect(
        find.descendant(of: topBarFinder, matching: find.byType(CtBackButton)),
        findsOneWidget,
      );

      expect(find.text('CURRENT RELATION'), findsOneWidget);
      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      expect(find.text('DOSSIER'), findsOneWidget);
    });

    testWidgets('AC (positive) DiplomacyDetailScreen greatPower @ 320×640: '
        'populated history event sentence + dossier evidence row both '
        'render inside the ~288 dp content column', (
      WidgetTester tester,
    ) async {
      final game = diplomacyDetailMinimalGame(
        includeHistory: true,
        includeDossier: true,
        atWar: true,
        eventType: DiplomaticEventType.declareWar,
      );
      final relation = getRelation(
        game,
        diplomacyDetailHumanId,
        diplomacyDetailOtherId,
      );

      await pumpDiplomacyDetailScreen320(
        tester,
        size: kDiplomacyDetailScreen320MinViewport,
        game: game,
        kind: FactionKind.greatPower,
        relation: relation,
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('declared war'), findsOneWidget);
      expect(find.textContaining('evidence-1'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — DiplomacyDetailScreen (minor '
      'nation, no dossier) @ 320 dp (Refs #2870 S10)', () {
    testWidgets('AC (positive) DiplomacyDetailScreen minor @ 320×640: no '
        'RenderFlex overflow exception, CtTopBar + CURRENT RELATION + '
        'DIPLOMATIC HISTORY render, DOSSIER section is absent', (
      WidgetTester tester,
    ) async {
      final game = diplomacyDetailMinimalGame(
        includeHistory: false,
        includeDossier: false,
        atWar: false,
      );
      final relation = getRelation(
        game,
        diplomacyDetailHumanId,
        diplomacyDetailOtherId,
      );

      await pumpDiplomacyDetailScreen320(
        tester,
        size: kDiplomacyDetailScreen320MinViewport,
        game: game,
        kind: FactionKind.minor,
        relation: relation,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CtTopBar), findsOneWidget);
      expect(find.text('CURRENT RELATION'), findsOneWidget);
      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      expect(find.text('DOSSIER'), findsNothing);
    });
  });
}
