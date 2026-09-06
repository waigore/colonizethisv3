// Pins overlay Sail / Move flow: DLG31003? → DLG30001, never DLG31001 (Refs #4735).

import 'dart:async';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_fleet_picker_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_menu_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/overlay_sail_move_flow.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'move_dialogs_specs_test_support.dart';
import 'province_naval_mission_action_state_fixtures.dart';

void main() {
  suppressLogsForTests();

  MapTopology topology() => coastalTopology();

  testWidgets('single fleet opens MoveFleetDialog without mission menu', (
    tester,
  ) async {
    final game = gameWith(fleets: [atSeaFleet()]);
    final bus = AppEventBus();
    final l10n = AppLocalizationsEn();

    await tester.pumpWidget(
      moveDialogsSpecsFrameWithOpener((context) {
        return () {
          unawaited(
            showOverlaySailMoveFlow(
              context: context,
              game: game,
              topology: topology(),
              humanPlayerId: human,
              bus: bus,
              fleetIds: const ['f_sea'],
            ),
          );
        };
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(NavalMissionMenuDialog), findsNothing);
    expect(find.byType(NavalMissionFleetPickerDialog), findsNothing);
    expect(find.byType(MoveFleetDialog), findsOneWidget);
    expect(find.textContaining(l10n.naval_fleetLabel('f_sea')), findsWidgets);
  });

  testWidgets('multi fleet shows picker then MoveFleetDialog', (tester) async {
    final game = gameWith(
      fleets: [
        atSeaFleet(id: 'f_a'),
        atSeaFleet(id: 'f_b'),
      ],
    );
    final bus = AppEventBus();
    final l10n = AppLocalizationsEn();

    await tester.pumpWidget(
      moveDialogsSpecsFrameWithOpener((context) {
        return () {
          unawaited(
            showOverlaySailMoveFlow(
              context: context,
              game: game,
              topology: topology(),
              humanPlayerId: human,
              bus: bus,
              fleetIds: const ['f_a', 'f_b'],
            ),
          );
        };
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(NavalMissionFleetPickerDialog), findsOneWidget);
    expect(find.byType(NavalMissionMenuDialog), findsNothing);

    await tester.tap(
      find.widgetWithText(CtNinePatchButton, l10n.common_confirm),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavalMissionFleetPickerDialog), findsNothing);
    expect(find.byType(MoveFleetDialog), findsOneWidget);
  });
}
