import 'package:colonizethis_app/features/game/widgets/unit_orders/army_stack_marker_action.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('resolveArmyStackMarkerAction (Refs #4384, #4407)', () {
    test('observe mode blocks Move and roster regardless of field armies', () {
      final action = resolveArmyStackMarkerAction(
        canMutateViaUi: false,
        fieldArmyIds: const ['army_field'],
        stackHasNonEmptyHomeArmy: true,
      );
      expect(action.kind, ArmyStackMarkerKind.observeBlocked);
      expect(action.moveArmyIds, isEmpty);
    });

    test('empty Home-only stack opens the military roster', () {
      final action = resolveArmyStackMarkerAction(
        canMutateViaUi: true,
        fieldArmyIds: const [],
      );
      expect(action.kind, ArmyStackMarkerKind.openMilitaryRoster);
      expect(action.moveArmyIds, isEmpty);
    });

    test('non-empty Home-only stack starts detach-then-move', () {
      final action = resolveArmyStackMarkerAction(
        canMutateViaUi: true,
        fieldArmyIds: const [],
        stackHasNonEmptyHomeArmy: true,
      );
      expect(action.kind, ArmyStackMarkerKind.detachThenMove);
      expect(action.moveArmyIds, isEmpty);
    });

    test('mixed capital with destinations uses field ids only', () {
      final action = resolveArmyStackMarkerAction(
        canMutateViaUi: true,
        fieldArmyIds: const ['army_field_a', 'army_field_b'],
        stackHasNonEmptyHomeArmy: true,
        fieldArmyIdsWithDestinations: const ['army_field_a'],
      );
      expect(action.kind, ArmyStackMarkerKind.overlayMove);
      expect(action.moveArmyIds, ['army_field_a']);
      expect(action.moveArmyIds, isNot(contains('army_home')));
    });

    test('mixed destination-less field armies start detach-then-move', () {
      final action = resolveArmyStackMarkerAction(
        canMutateViaUi: true,
        fieldArmyIds: const ['army_field'],
        stackHasNonEmptyHomeArmy: true,
      );
      expect(action.kind, ArmyStackMarkerKind.detachThenMove);
      expect(action.moveArmyIds, isEmpty);
    });

    test('dest-less field army away from Home Army uses overlay Move', () {
      final action = resolveArmyStackMarkerAction(
        canMutateViaUi: true,
        fieldArmyIds: const ['army_field'],
      );
      expect(action.kind, ArmyStackMarkerKind.overlayMove);
      expect(action.moveArmyIds, ['army_field']);
    });
  });
}
