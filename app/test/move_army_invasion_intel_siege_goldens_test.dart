// Widget goldens for selected-row fort siege gist on DLG20001 (Refs #4764).
// Concern split under repo.app_test_file_size.
// SPEC: SPEC/ui/move-army-dialog.md § Invasion intel.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'move_army_invasion_intel_goldens_test_support.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets('golden: selected wood siege gist on invasion row (Refs #4764)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'moveArmyInvasionIntelSelectedSiegeGolden',
    );
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
    await tester.tap(find.text('Invade Dest'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Wood fort siege'), findsOneWidget);
    expect(
      find.text(
        'Light walls soak some of the attack; the defender has 1 extra gun.',
      ),
      findsOneWidget,
    );

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/move_army_invasion_intel_selected_siege.png'),
    );
  });

  testWidgets('golden: selected wood siege gist wraps at 320 dp (Refs #4764)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'moveArmyInvasionIntelSelectedSiege320Golden',
    );
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
      physicalSize: const Size(kMinViewportWidth, 640),
    );
    await tester.tap(find.text('Invade Dest'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.text(
        'Light walls soak some of the attack; the defender has 1 extra gun.',
      ),
      findsOneWidget,
    );

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile(
        'goldens/move_army_invasion_intel_selected_siege_320.png',
      ),
    );
  });
}
