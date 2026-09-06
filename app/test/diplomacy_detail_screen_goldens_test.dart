// Widget goldens for the diplomacy detail screen (GAME30002) (Refs #3753 S17).
// SPEC: SPEC/ui/diplomacy-detail-screen.md; SPEC/ui/diplomacy-panel.md § R12.

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/relation_meter.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_detail_screen_goldens_fixtures.dart';
import 'diplomacy_panel_test_support.dart';
import 'golden_capture_harness.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await preloadNinePatchImage();
  });

  setUp(AppEventBus.reset);

  testWidgets(
    'GAME30002 golden: colony Tribe detail shows standing chips + relation meter',
    (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: const Size(600, 900));
      const boundaryKey = ValueKey<String>(
        'diplomacy_detail_colony_tribe_golden',
      );

      final game = diplomacyDetailGoldenColonyTribeGame();
      await tester.pumpWidget(
        diplomacyDetailGoldenHost(
          game: game,
          humanPlayerId: 'gp1',
          factionId: 't1',
          factionDisplayName: 'Powhatan',
          kind: FactionKind.tribe,
          boundaryKey: boundaryKey,
        ),
      );
      await pumpDiplomacyPanelBuilt(tester);

      expect(find.text('CURRENT RELATION'), findsOneWidget);
      expect(find.text('DIPLOMATIC HISTORY'), findsOneWidget);
      expect(find.text(kDiplomacyChipColony), findsOneWidget);
      expect(find.text(kDiplomacyChipEmbassy), findsWidgets);
      expect(
        find.text('${kDiplomacyChipBoycottVsPrefix}Castile'),
        findsOneWidget,
      );
      expect(find.byType(RelationMeter), findsOneWidget);
      expect(find.text('Outgoing subsidy:'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_detail_colony_tribe.png'),
      );
    },
  );

  testWidgets(
    'GAME30002 golden: subsidized Minor detail shows overseas chip + relation meter',
    (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: const Size(600, 900));
      const boundaryKey = ValueKey<String>(
        'diplomacy_detail_subsidized_minor_golden',
      );

      final game = diplomacyDetailGoldenSubsidizedMinorGame();
      await tester.pumpWidget(
        diplomacyDetailGoldenHost(
          game: game,
          humanPlayerId: 'gp1',
          factionId: 'm1',
          factionDisplayName: 'Bavaria',
          kind: FactionKind.minor,
          boundaryKey: boundaryKey,
        ),
      );
      await pumpDiplomacyPanelBuilt(tester);

      expect(find.text('CURRENT RELATION'), findsOneWidget);
      expect(find.text(kDiplomacyChipEmbassy), findsWidgets);
      expect(
        find.text('${kDiplomacyChipOverseasPrefix}2 \u00b7 80%'),
        findsOneWidget,
      );
      expect(find.byType(RelationMeter), findsOneWidget);
      expect(find.text('Outgoing subsidy:'), findsNothing);
      expect(find.text('DOSSIER'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_detail_subsidized_minor.png'),
      );
    },
  );
}
