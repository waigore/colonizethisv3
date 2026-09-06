// MoveArmyDialog invasion intel UI widget tests (Refs #4734 Slice E, #4216).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'move_army_invasion_intel_test_support.dart';

void main() {
  suppressLogsForTests();

  group('MoveArmyDialog invasion intel UI', () {
    testWidgets('shows own army count on dialog body', (tester) async {
      final topology = buildMoveArmyInvasionIntelUiTopology();
      final game = buildMoveArmyInvasionIntelUiGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
      );
      await pumpMoveArmyInvasionIntelDialog(
        tester,
        game: game,
        topology: topology,
      );
      expect(find.text('Your army: 1 regiments'), findsOneWidget);
    });

    testWidgets('full intel invasion row shows defender count and fort label', (
      tester,
    ) async {
      final topology = buildMoveArmyInvasionIntelUiTopology();
      final game = buildMoveArmyInvasionIntelUiGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
        fortLevel: 1,
        extraUnits: [
          Unit(
            id: 'd1',
            type: 'pikemen',
            ownerId: kMoveArmyIntelUiRivalId,
            locationProvinceId: kMoveArmyIntelUiInvasionDest,
          ),
        ],
      );
      await pumpMoveArmyInvasionIntelDialog(
        tester,
        game: game,
        topology: topology,
      );
      expect(find.text('Defenders: 1 regiments'), findsOneWidget);
      expect(find.text('Wood fort siege'), findsOneWidget);
      expect(find.text('Defenders unknown'), findsNothing);
    });

    testWidgets('unknown intel invasion row shows defenders unknown', (
      tester,
    ) async {
      final topology = buildMoveArmyInvasionIntelUiTopology();
      final game = buildMoveArmyInvasionIntelUiGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fogged',
        },
      );
      await pumpMoveArmyInvasionIntelDialog(
        tester,
        game: game,
        topology: topology,
      );
      expect(find.text('Defenders unknown'), findsOneWidget);
      expect(find.textContaining('Defenders:'), findsNothing);
      expect(find.text('Unopposed capture'), findsNothing);
    });

    testWidgets('owned destination row has no invasion intel lines', (
      tester,
    ) async {
      final topology = buildMoveArmyInvasionIntelUiTopology();
      final game = buildMoveArmyInvasionIntelUiGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
      );
      await pumpMoveArmyInvasionIntelDialog(
        tester,
        game: game,
        topology: topology,
      );
      final ownedRow = find.ancestor(
        of: find.text('Owned Dest'),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString().contains('MoveDialogDestinationRow'),
        ),
      );
      expect(ownedRow, findsOneWidget);
      expect(
        find.descendant(of: ownedRow, matching: find.text('Defenders unknown')),
        findsNothing,
      );
    });

    testWidgets('selected invasion row shows regiment type breakdown', (
      tester,
    ) async {
      final topology = buildMoveArmyInvasionIntelUiTopology();
      final game = buildMoveArmyInvasionIntelUiGame(
        visibilityByTile: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_owned|0|0': 'fullyVisible',
          'oldWorld|p_invade|0|0': 'fullyVisible',
        },
        extraUnits: [
          Unit(
            id: 'd1',
            type: 'pikemen',
            ownerId: kMoveArmyIntelUiRivalId,
            locationProvinceId: kMoveArmyIntelUiInvasionDest,
          ),
        ],
      );
      await pumpMoveArmyInvasionIntelDialog(
        tester,
        game: game,
        topology: topology,
      );
      await tester.tap(find.text('Invade Dest'));
      await tester.pump();
      expect(find.textContaining('Musketeers'), findsWidgets);
      expect(find.textContaining('Pikemen'), findsOneWidget);
    });
  });
}
