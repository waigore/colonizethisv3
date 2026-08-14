import 'package:colonizethis_app/features/game/widgets/unit_orders/army_stack_marker_action.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('resolveArmyStackMarkerAction (Refs #4384)', () {
    test('observe mode blocks Move and roster regardless of field armies', () {
      final action = resolveArmyStackMarkerAction(
        canMutateViaUi: false,
        fieldArmyIds: const ['army_field'],
      );
      expect(action.kind, ArmyStackMarkerKind.observeBlocked);
      expect(action.moveArmyIds, isEmpty);
    });

    test('Home-only stack opens the military roster', () {
      final action = resolveArmyStackMarkerAction(
        canMutateViaUi: true,
        fieldArmyIds: const [],
      );
      expect(action.kind, ArmyStackMarkerKind.openMilitaryRoster);
      expect(action.moveArmyIds, isEmpty);
    });

    test('mixed capital passes field ids only into overlay Move', () {
      final action = resolveArmyStackMarkerAction(
        canMutateViaUi: true,
        fieldArmyIds: const ['army_field_a', 'army_field_b'],
      );
      expect(action.kind, ArmyStackMarkerKind.overlayMove);
      expect(action.moveArmyIds, ['army_field_a', 'army_field_b']);
      expect(action.moveArmyIds, isNot(contains('army_home')));
    });
  });
}
