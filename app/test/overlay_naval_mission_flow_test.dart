// Pins overlay Blockade/Beachhead flow skip-menu + preselect (Refs #4413).

import 'dart:async';

import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_flow.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_menu_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_target_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'move_dialogs_specs_test_support.dart';
import 'naval_mission_goldens_test_support.dart';
import 'naval_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();
  const target = 'oldWorld|enemy1';

  Game twoFleetWarGame() {
    final base = buildNavalMissionWarTargetsGame();
    return base.copyWith(
      worldState: base.worldState.copyWith(
        fleets: [
          ...base.worldState.fleets,
          Fleet(
            id: 'fleet_second',
            ownerId: navalMissionGoldenHumanId,
            regionId: 'oldWorld',
            seaZoneId: navalMissionGoldenSeaZone,
            ships: const [ShipInstance(id: 's2', typeId: 'galleon')],
          ),
        ],
      ),
    );
  }

  Future<void> openFlow(
    WidgetTester tester, {
    required Game game,
    required MapTopology topology,
    required List<String> fleetIds,
    required AppEventBus bus,
    FleetMission? initialMission,
    String? initialTargetProvinceId,
  }) async {
    await tester.pumpWidget(
      moveDialogsSpecsFrameWithOpener((context) {
        return () {
          unawaited(
            showNavalMissionFlow(
              context: context,
              game: game,
              topology: topology,
              humanPlayerId: navalMissionGoldenHumanId,
              draftOrders: const Orders(),
              bus: bus,
              fleetIds: fleetIds,
              initialMission: initialMission,
              initialTargetProvinceId: initialTargetProvinceId,
            ),
          );
        };
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('single fleet overlay Blockade skips menu and preselects P', (
    tester,
  ) async {
    final game = buildNavalMissionWarTargetsGame();
    final bus = AppEventBus();
    NavalMissionRequestedEvent? emitted;
    bus.on<NavalMissionRequestedEvent>().listen((e) => emitted = e);

    await openFlow(
      tester,
      game: game,
      topology: navalMissionWarTopology(),
      fleetIds: const ['fleet_at_sea'],
      bus: bus,
      initialMission: FleetMission.blockade,
      initialTargetProvinceId: target,
    );

    expect(find.byType(NavalMissionMenuDialog), findsNothing);
    expect(find.byType(NavalMissionTargetDialog), findsOneWidget);
    expect(find.text('Enemy Port'), findsOneWidget);

    final confirm = tester.widget<CtNinePatchButton>(
      find.widgetWithText(CtNinePatchButton, l10n.common_confirm),
    );
    expect(confirm.enabled, isTrue);
    expect(confirm.onPressed, isNotNull);

    await tester.tap(
      find.widgetWithText(CtNinePatchButton, l10n.common_confirm),
    );
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    expect(emitted!.missionOrder.fleetId, 'fleet_at_sea');
    expect(emitted!.missionOrder.mission, FleetMission.blockade.name);
    expect(emitted!.missionOrder.targetProvinceId, target);
  });

  testWidgets('several eligible fleets open picker then preselected target', (
    tester,
  ) async {
    final game = twoFleetWarGame();
    final bus = AppEventBus();

    await openFlow(
      tester,
      game: game,
      topology: navalMissionWarTopology(),
      fleetIds: const ['fleet_at_sea', 'fleet_second'],
      bus: bus,
      initialMission: FleetMission.blockade,
      initialTargetProvinceId: target,
    );

    expect(find.byType(NavalMissionFleetPickerDialog), findsOneWidget);
    expect(find.text(l10n.naval_mission_selectFleetTitle), findsOneWidget);
    expect(find.byType(NavalMissionMenuDialog), findsNothing);

    await tester.tap(
      find.widgetWithText(CtNinePatchButton, l10n.common_confirm),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavalMissionTargetDialog), findsOneWidget);
    final confirm = tester.widget<CtNinePatchButton>(
      find.widgetWithText(CtNinePatchButton, l10n.common_confirm),
    );
    expect(confirm.enabled, isTrue);
  });

  testWidgets('omitting initialMission still opens DLG31001 menu', (
    tester,
  ) async {
    final game = buildNavalPanelNamedSeaZoneGame(
      humanId: navalMissionGoldenHumanId,
    );
    final bus = AppEventBus();

    await openFlow(
      tester,
      game: game,
      topology: const MapTopology(),
      fleetIds: const ['sea_named'],
      bus: bus,
    );

    expect(find.byType(NavalMissionMenuDialog), findsOneWidget);
    expect(find.byType(NavalMissionTargetDialog), findsNothing);
  });
}
