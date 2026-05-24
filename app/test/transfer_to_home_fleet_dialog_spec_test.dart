// Pins SPEC/ui/transfer-to-home-fleet-dialog.md contract for the
// regular-fleet → Home Fleet ship merge modal opened from NavalUnitsPanel.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/transfer_to_home_fleet_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

void main() {
  suppressLogsForTests();

  group(
    'TransferToHomeFleetDialog (SPEC/ui/transfer-to-home-fleet-dialog.md)',
    () {
      const playerId = 'gp_transfer_specs';
      const capitalProvince = 'oldWorld|p_transfer_capital';
      const sourceFleetId = 'f_transfer_source';
      const homeFleetId = 'f_transfer_home';

      ({Game game, Fleet source, Fleet home}) buildFixture() {
        final game = Game(
          id: 'g_transfer_specs',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: capitalProvince,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  displayName: 'Capital Port',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(
              id: playerId,
              displayName: 'Specs Admiral',
              isHuman: true,
              capitalProvinceId: capitalProvince,
            ),
          ],
        );
        final source = Fleet(
          id: sourceFleetId,
          ownerId: playerId,
          regionId: 'oldWorld',
          inPortAtProvinceId: capitalProvince,
          ships: const [
            ShipInstance(id: 'ship_carrack_a', typeId: 'carrack'),
            ShipInstance(id: 'ship_carrack_b', typeId: 'carrack'),
            ShipInstance(id: 'ship_fluyte_a', typeId: 'fluyte'),
          ],
        );
        final home = Fleet(
          id: homeFleetId,
          ownerId: playerId,
          regionId: 'oldWorld',
          inPortAtProvinceId: capitalProvince,
          ships: const [
            ShipInstance(id: 'ship_carrack_c', typeId: 'carrack'),
          ],
        );
        return (game: game, source: source, home: home);
      }

      Future<void> pumpDialog(
        WidgetTester tester, {
        required AppEventBus bus,
        Size surfaceSize = const Size(800, 900),
      }) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = surfaceSize;
        tester.view.devicePixelRatio = 1.0;
        final fixture = buildFixture();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => TransferToHomeFleetDialog(
                        sourceFleet: fixture.source,
                        homeFleet: fixture.home,
                        game: fixture.game,
                        humanPlayerId: playerId,
                        bus: bus,
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
      }

      testWidgets(
        'renders single CtTransferList with source 3 ships and target 1 ship totals',
        (WidgetTester tester) async {
          await pumpDialog(tester, bus: AppEventBus.create());
          expect(find.byType(TransferToHomeFleetDialog), findsOneWidget);
          expect(find.byType(CtTransferList), findsOneWidget);
          expect(find.textContaining('Total: 3'), findsWidgets);
          expect(find.textContaining('Total: 1'), findsWidgets);
        },
      );

      testWidgets(
        'initial open: no ship movement, no NavalTransferShipsRequestedEvent on Confirm tap',
        (WidgetTester tester) async {
          NavalTransferShipsRequestedEvent? captured;
          final bus = AppEventBus.create();
          final sub = bus.on<NavalTransferShipsRequestedEvent>().listen((e) {
            captured = e;
          });
          addTearDown(sub.cancel);

          await pumpDialog(tester, bus: bus);
          final confirm = find.widgetWithText(
            CtNinePatchButton,
            'Confirm Transfer',
          );
          expect(confirm, findsOneWidget);
          await tester.ensureVisible(confirm);
          await tester.pumpAndSettle();
          await tester.tap(confirm);
          await tester.pumpAndSettle();

          expect(captured, isNull);
          expect(find.byType(TransferToHomeFleetDialog), findsOneWidget);
        },
      );

      testWidgets(
        'Cancel emits no event and dismisses dialog',
        (WidgetTester tester) async {
          NavalTransferShipsRequestedEvent? captured;
          final bus = AppEventBus.create();
          final sub = bus.on<NavalTransferShipsRequestedEvent>().listen((e) {
            captured = e;
          });
          addTearDown(sub.cancel);

          await pumpDialog(tester, bus: bus);
          final cancel = find.widgetWithText(CtNinePatchButton, 'Cancel');
          await tester.ensureVisible(cancel);
          await tester.pumpAndSettle();
          await tester.tap(cancel);
          await tester.pumpAndSettle();

          expect(captured, isNull);
          expect(find.byType(TransferToHomeFleetDialog), findsNothing);
        },
      );
    },
  );
}
