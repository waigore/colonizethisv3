// Builder-cap pins for `colonial_phase_planner_civilian_test.dart` (Refs #4669).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';
import 'colonial_phase_planner_civilian_core_support.dart';

void registerColonialPhasePlannerCivilianCoreCasesPartB() {
  group('planColonialCivilian', () {
    test('already-improved NW tile excluded', () {
      final game = buildColonialCivilianGame(
        provinces: const [
          Province(
            id: kColonialCivilianNwProv2,
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
        ],
        owUnits: [colonialCivilianIdleBuilder('b1')],
        resourceByTileKey: const {kColonialCivilianNwTileImproved: 'cotton'},
        tileState: const TileMapState(
          improvementByTile: {kColonialCivilianNwTileImproved: 1},
        ),
      );
      expect(
        planColonialCivilian(
          game: game,
          snapshot: buildColonialCivilianSnapshot(),
        ),
        isEmpty,
        reason:
            'All eligible NW tiles already at improvementLevel >= 1; '
            'the planner must emit no orders.',
      );
    });

    test('builder count caps emitted orders below tile count', () {
      final game = buildColonialCivilianGame(
        provinces: const [
          Province(
            id: kColonialCivilianNwProv1,
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
        ],
        owUnits: [colonialCivilianIdleBuilder('b1')],
        resourceByTileKey: const {
          kColonialCivilianNwTileA: 'tobacco',
          kColonialCivilianNwTileB: 'sugar',
        },
      );
      final orders = planColonialCivilian(
        game: game,
        snapshot: buildColonialCivilianSnapshot(),
      );
      expect(orders.length, 1);
      expect(orders.single.unitId, 'b1');
      expect(orders.single.targetTileKey, kColonialCivilianNwTileA);
      expect(orders.single.target, kWorkTargetBuildImprovement);
    });

    test('tile count caps emitted orders below builder count', () {
      final game = buildColonialCivilianGame(
        provinces: const [
          Province(
            id: kColonialCivilianNwProv1,
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
        ],
        owUnits: [
          colonialCivilianIdleBuilder('b1'),
          colonialCivilianIdleBuilder('b2'),
        ],
        resourceByTileKey: const {kColonialCivilianNwTileA: 'tobacco'},
      );
      final orders = planColonialCivilian(
        game: game,
        snapshot: buildColonialCivilianSnapshot(),
      );
      expect(orders.length, 1);
      expect(orders.single.unitId, 'b1');
      expect(orders.single.targetTileKey, kColonialCivilianNwTileA);
    });
  });
}
