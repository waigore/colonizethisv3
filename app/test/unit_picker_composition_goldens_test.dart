// Host widget goldens for DLG20002 / DLG31003 composition lines (Refs #4385).
// Closes the verification PNG gap: army picker rows and fleet pending-mission.
//
// SPEC: SPEC/ui/overlay-army-move-picker-dialog.md,
//       SPEC/ui/naval-mission-fleet-picker-dialog.md.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_menu_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/overlay_army_move_picker_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'unit_picker_composition_test_support.dart';
import 'widget_test_assets.dart';

const Size _kPickerGoldenViewport = Size(360, 360);

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  Future<void> pumpPickerGolden(
    WidgetTester tester, {
    required Key boundaryKey,
    required Widget child,
    Size physicalSize = _kPickerGoldenViewport,
  }) async {
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: physicalSize,
      settle: false,
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      child: child,
    );
  }

  testWidgets(
    'golden: DLG20002 army picker shows distinct per-army composition '
    '(Refs #4385)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('overlayArmyMovePickerGolden');
      final game = _twoArmyPickerGame();

      await pumpPickerGolden(
        tester,
        boundaryKey: boundaryKey,
        child: OverlayArmyMovePickerDialog(
          game: game,
          humanPlayerId: unitPickerTestPlayerId,
          armyIds: const ['a1', 'a2'],
        ),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text(l10n.military_units_army('a1')), findsOneWidget);
      expect(find.text(l10n.military_units_army('a2')), findsOneWidget);
      expect(
        find.text(l10n.military_units_typeCount('Pikemen', 1)),
        findsOneWidget,
      );
      expect(
        find.text(l10n.military_units_typeCount('Peasant Levies', 1)),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/overlay_army_move_picker_composition.png'),
      );
    },
  );

  testWidgets('golden: DLG20002 army picker at 320 dp (Refs #4385)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('overlayArmyMovePicker320Golden');
    final game = _twoArmyPickerGame();

    await pumpPickerGolden(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(kMinViewportWidth, 640),
      child: OverlayArmyMovePickerDialog(
        game: game,
        humanPlayerId: unitPickerTestPlayerId,
        armyIds: const ['a1', 'a2'],
      ),
    );

    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile(
        'goldens/overlay_army_move_picker_composition_320dp.png',
      ),
    );
  });

  testWidgets(
    'golden: DLG31003 fleet picker shows pending-mission line (Refs #4385)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'navalMissionFleetPickerPendingGolden',
      );
      final game = unitPickerFleetGame([
        Fleet(
          id: 'alpha',
          ownerId: unitPickerTestPlayerId,
          regionId: 'oldWorld',
          seaZoneId: 'oldWorld|sea1',
          ships: const [ShipInstance(id: 's1', typeId: 'sloop')],
          mission: FleetMission.patrol,
        ),
        Fleet(
          id: 'beta',
          ownerId: unitPickerTestPlayerId,
          regionId: 'oldWorld',
          seaZoneId: 'oldWorld|sea1',
          ships: const [ShipInstance(id: 's2', typeId: 'carrack')],
        ),
      ]);

      await pumpPickerGolden(
        tester,
        boundaryKey: boundaryKey,
        child: NavalMissionFleetPickerDialog(
          game: game,
          humanPlayerId: unitPickerTestPlayerId,
          fleetIds: const ['alpha', 'beta'],
        ),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text(l10n.naval_fleetLabel('alpha')), findsOneWidget);
      expect(find.text(l10n.naval_fleetLabel('beta')), findsOneWidget);
      expect(
        find.text(l10n.naval_mission_pendingLine('Patrol')),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/naval_mission_fleet_picker_pending_mission.png',
        ),
      );
    },
  );
}

Game _twoArmyPickerGame() {
  return unitPickerArmyGame(
    armies: const [
      Army(
        id: 'a1',
        ownerId: unitPickerTestPlayerId,
        regionId: 'oldWorld',
        stationedProvinceId: unitPickerTestProvince,
        regimentUnitIds: ['u_pike'],
      ),
      Army(
        id: 'a2',
        ownerId: unitPickerTestPlayerId,
        regionId: 'oldWorld',
        stationedProvinceId: unitPickerTestProvince,
        regimentUnitIds: ['u_levy'],
      ),
    ],
    units: [
      Unit(
        id: 'u_pike',
        type: 'pikemen',
        ownerId: unitPickerTestPlayerId,
        locationProvinceId: unitPickerTestProvince,
      ),
      Unit(
        id: 'u_levy',
        type: 'peasant_levies',
        ownerId: unitPickerTestPlayerId,
        locationProvinceId: unitPickerTestProvince,
      ),
    ],
  );
}
