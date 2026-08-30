import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Barrel / concern-split smoke for Refs #4136 Slice B.
void main() {
  group('session command event concern split barrel', () {
    test('positive: domain events construct via barrel as SessionCommandEvent', () {
      final civilian = RemovePendingWorkOrderRequestedEvent(
        playerId: 'gp1',
        index: 0,
      );
      final naval = NavalMoveFleetRequestedEvent(
        humanPlayerId: 'gp1',
        moveOrder: NavalMoveOrder(
          fleetId: 'f1',
          destinationSeaZoneId: 'sz1',
        ),
      );
      final army = ArmyCombineRequestedEvent(
        humanPlayerId: 'gp1',
        armyIds: const ['a1', 'a2'],
      );
      final train = TrainCivilianBuildOrdersCommittedEvent(orders: const []);
      const debug = SpawnDebugCivilianAtCapitalEvent(
        humanPlayerId: 'gp1',
        unitType: 'explorer',
      );
      const observe = SetObserveModeGlobalEvent();
      final diplomacy = AppendDiplomaticOrderRequestedEvent(
        playerId: 'gp1',
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'gp2',
        ),
      );

      expect(civilian, isA<SessionCommandEvent>());
      expect(naval, isA<SessionCommandEvent>());
      expect(army, isA<SessionCommandEvent>());
      expect(train, isA<SessionCommandEvent>());
      expect(debug, isA<SessionCommandEvent>());
      expect(observe, isA<SessionCommandEvent>());
      expect(diplomacy, isA<SessionCommandEvent>());
    });

    test('negative: FlipDebugProvinceOwnershipEvent rejects invalid ctor args', () {
      expect(
        () => FlipDebugProvinceOwnershipEvent(
          humanPlayerId: 'gp1',
          fullProvinceId: 'ow|p1',
          regionId: 'ow',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
