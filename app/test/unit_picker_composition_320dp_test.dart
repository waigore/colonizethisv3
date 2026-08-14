// 320 dp pins for DLG20002 / DLG31003 composition lines (Refs #4385).

import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_menu_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/overlay_army_move_picker_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';

void main() {
  suppressLogsForTests();

  const playerId = 'gp_picker_320';
  const province = 'oldWorld|p1';
  final l10n = AppLocalizationsEn();

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — unit pickers @ 320 dp (Refs #4385)',
    () {
      testWidgets(
        'AC (positive) OverlayArmyMovePickerDialog @ 320×640: no overflow, '
        'composition + Confirm reachable',
        (tester) async {
          final game = Game(
            id: 'g_picker_320_army',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: RegionData(
                provinces: const [
                  Province(
                    id: province,
                    regionId: 'oldWorld',
                    ownerId: playerId,
                    displayName: 'P1',
                  ),
                ],
                units: [
                  Unit(
                    id: 'u1',
                    type: 'pikemen',
                    ownerId: playerId,
                    locationProvinceId: province,
                  ),
                  Unit(
                    id: 'u2',
                    type: 'peasant_levies',
                    ownerId: playerId,
                    locationProvinceId: province,
                  ),
                ],
              ),
              newWorld: const RegionData(),
              armies: const [
                Army(
                  id: 'a1',
                  ownerId: playerId,
                  regionId: 'oldWorld',
                  stationedProvinceId: province,
                  regimentUnitIds: ['u1'],
                ),
                Army(
                  id: 'a2',
                  ownerId: playerId,
                  regionId: 'oldWorld',
                  stationedProvinceId: province,
                  regimentUnitIds: ['u2'],
                ),
              ],
            ),
            players: const [
              Player(id: playerId, displayName: 'Human', isHuman: true),
            ],
          );
          await pinDialogs320At(
            tester,
            OverlayArmyMovePickerDialog(
              game: game,
              humanPlayerId: playerId,
              armyIds: const ['a1', 'a2'],
            ),
            size: kDialogs320MinViewport,
            overflowReason:
                'DLG20002 composition lines must wrap/ellipsis at 320 dp.',
            expectFinders: [
              find.text(l10n.provinceOverlay_selectArmyTitle),
              find.text(l10n.military_units_typeCount('Pikemen', 1)),
              find.text(l10n.common_confirm),
            ],
          );
        },
      );

      testWidgets(
        'AC (positive) NavalMissionFleetPickerDialog @ 320×640: no overflow, '
        'composition + Confirm reachable',
        (tester) async {
          final game = Game(
            id: 'g_picker_320_fleet',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: const RegionData(),
              newWorld: const RegionData(),
              fleets: [
                Fleet(
                  id: 'alpha',
                  ownerId: playerId,
                  regionId: 'oldWorld',
                  seaZoneId: 'oldWorld|sea1',
                  ships: const [ShipInstance(id: 's1', typeId: 'sloop')],
                  mission: FleetMission.patrol,
                ),
                Fleet(
                  id: 'beta',
                  ownerId: playerId,
                  regionId: 'oldWorld',
                  seaZoneId: 'oldWorld|sea1',
                  ships: const [ShipInstance(id: 's2', typeId: 'carrack')],
                ),
              ],
            ),
            players: const [
              Player(id: playerId, displayName: 'Human', isHuman: true),
            ],
          );
          await pinDialogs320At(
            tester,
            NavalMissionFleetPickerDialog(
              game: game,
              humanPlayerId: playerId,
              fleetIds: const ['alpha', 'beta'],
            ),
            size: kDialogs320MinViewport,
            overflowReason:
                'DLG31003 composition lines must wrap/ellipsis at 320 dp.',
            expectFinders: [
              find.text(l10n.naval_mission_selectFleetTitle),
              find.text(l10n.naval_units_compositionSummary(1, 1, 0)),
              find.text(l10n.common_confirm),
            ],
          );
        },
      );
    },
  );
}
