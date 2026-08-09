// Widget goldens for move army invasion intel on DLG20001 (Refs #4216).
// Pins own-army line, defender totals, fort labels, unopposed capture,
// defenders unknown, and selected-row type breakdown.
//
// SPEC: SPEC/ui/move-army-dialog.md § Invasion intel.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'move_army_invasion_intel_goldens_test_support.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  Future<void> pumpMoveArmyInvasionIntelGolden(
    WidgetTester tester, {
    required Key boundaryKey,
    required Game game,
    required MapTopology topology,
    PlayerView? playerView,
  }) async {
    final army = game.worldState.armies.first;
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: kMoveArmyInvasionIntelGoldenViewport,
      settle: false,
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      child: MoveArmyDialog(
        army: army,
        game: game,
        humanPlayerId: moveArmyInvasionIntelGoldenPlayerId,
        bus: AppEventBus.create(),
        topology: topology,
        draftOrders: const Orders(),
        playerView: playerView,
      ),
    );
  }

  testWidgets(
    'golden: full intel invasion row shows defenders and wood fort siege (Refs #4216)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('moveArmyInvasionIntelFullGolden');
      final topology = buildMoveArmyInvasionIntelGoldenTopology();
      final game = buildMoveArmyInvasionIntelGoldenGame(
        visibilityByTile: moveArmyInvasionIntelFullVisibilityTiles(),
        fortLevel: 1,
        invasionUnits: [
          Unit(
            id: 'd1',
            type: 'pikemen',
            ownerId: moveArmyInvasionIntelGoldenRivalId,
            locationProvinceId: moveArmyInvasionIntelGoldenInvasionDest,
          ),
        ],
      );
      final view = buildPlayerView(
        game,
        topology,
        moveArmyInvasionIntelGoldenPlayerId,
      );

      await pumpMoveArmyInvasionIntelGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        topology: topology,
        playerView: view,
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text('Your army: 1 regiments'), findsOneWidget);
      expect(find.text('Defenders: 1 regiments'), findsOneWidget);
      expect(find.text('Wood fort siege'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/move_army_invasion_intel_full.png'),
      );
    },
  );

  testWidgets(
    'golden: full intel with zero defenders shows unopposed capture (Refs #4216)',
    (WidgetTester tester) async {
      const boundaryKey =
          ValueKey<String>('moveArmyInvasionIntelUnopposedGolden');
      final topology = buildMoveArmyInvasionIntelGoldenTopology();
      final game = buildMoveArmyInvasionIntelGoldenGame(
        visibilityByTile: moveArmyInvasionIntelFullVisibilityTiles(),
        includeOwnedDestination: false,
      );
      final view = buildPlayerView(
        game,
        topology,
        moveArmyInvasionIntelGoldenPlayerId,
      );

      await pumpMoveArmyInvasionIntelGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        topology: topology,
        playerView: view,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Your army: 1 regiments'), findsOneWidget);
      expect(find.text('Unopposed capture'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/move_army_invasion_intel_unopposed.png'),
      );
    },
  );

  testWidgets(
    'golden: fogged invasion row shows defenders unknown (Refs #4216)',
    (WidgetTester tester) async {
      const boundaryKey =
          ValueKey<String>('moveArmyInvasionIntelUnknownGolden');
      final topology = buildMoveArmyInvasionIntelGoldenTopology();
      final game = buildMoveArmyInvasionIntelGoldenGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fogged',
        },
        invasionUnits: [
          Unit(
            id: 'd1',
            type: 'pikemen',
            ownerId: moveArmyInvasionIntelGoldenRivalId,
            locationProvinceId: moveArmyInvasionIntelGoldenInvasionDest,
          ),
        ],
      );
      final view = buildPlayerView(
        game,
        topology,
        moveArmyInvasionIntelGoldenPlayerId,
      );

      await pumpMoveArmyInvasionIntelGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        topology: topology,
        playerView: view,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Defenders unknown'), findsOneWidget);
      expect(find.textContaining('Defenders:'), findsNothing);
      expect(find.text('Unopposed capture'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/move_army_invasion_intel_unknown.png'),
      );
    },
  );

  testWidgets(
    'golden: selected invasion row shows regiment type breakdown (Refs #4216)',
    (WidgetTester tester) async {
      const boundaryKey =
          ValueKey<String>('moveArmyInvasionIntelSelectedGolden');
      final topology = buildMoveArmyInvasionIntelGoldenTopology();
      final game = buildMoveArmyInvasionIntelGoldenGame(
        visibilityByTile: moveArmyInvasionIntelFullVisibilityTiles(),
        invasionUnits: [
          Unit(
            id: 'd1',
            type: 'pikemen',
            ownerId: moveArmyInvasionIntelGoldenRivalId,
            locationProvinceId: moveArmyInvasionIntelGoldenInvasionDest,
          ),
        ],
      );
      final view = buildPlayerView(
        game,
        topology,
        moveArmyInvasionIntelGoldenPlayerId,
      );

      await pumpMoveArmyInvasionIntelGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        topology: topology,
        playerView: view,
      );
      await tester.tap(find.text('Invade Dest'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Musketeers'), findsWidgets);
      expect(find.textContaining('Pikemen'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/move_army_invasion_intel_selected.png'),
      );
    },
  );
}
