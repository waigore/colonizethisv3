// Case bodies for `colonial_phase_planner_civilian_test.dart` (Refs #4291 Slice D).
// Structural exclusion pins (tests 1–5).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';
import 'colonial_phase_planner_civilian_core_support.dart';

void registerColonialPhasePlannerCivilianCoreCasesPartA() {
  group('planColonialCivilian', () {
    test('no owned NW provinces -> empty', () {
      final game = buildColonialCivilianGame(
        provinces: const [
          Province(
            id: kColonialCivilianOwProv1,
            regionId: kOldWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
        ],
        owUnits: [colonialCivilianIdleBuilder('b1')],
        resourceByTileKey: const {kColonialCivilianOwTileA: 'grain'},
      );
      expect(
        planColonialCivilian(
          game: game,
          snapshot: buildColonialCivilianSnapshot(),
        ),
        isEmpty,
        reason:
            'Active player owns zero NW provinces -> no eligible tiles. '
            'The COLONIAL civilian planner must short-circuit before '
            'scanning resource tiles when the owned-NW set is empty.',
      );
    });

    test('no idle builders -> empty', () {
      final game = buildColonialCivilianGame(
        provinces: const [
          Province(
            id: kColonialCivilianNwProv1,
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
        ],
        owUnits: const [],
        resourceByTileKey: const {kColonialCivilianNwTileA: 'tobacco'},
      );
      expect(
        planColonialCivilian(
          game: game,
          snapshot: buildColonialCivilianSnapshot(),
        ),
        isEmpty,
        reason:
            'No idle Builders -> no orders. The function must skip its '
            'tile scan when builders are empty (early-exit contract).',
      );
    });

    test('OW resource tile excluded even when owned (NW-only restriction)', () {
      final game = buildColonialCivilianGame(
        provinces: const [
          Province(
            id: kColonialCivilianOwProv1,
            regionId: kOldWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
          Province(
            id: kColonialCivilianNwProv1,
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
        ],
        owUnits: [colonialCivilianIdleBuilder('b1')],
        resourceByTileKey: const {kColonialCivilianOwTileA: 'grain'},
      );
      expect(
        planColonialCivilian(
          game: game,
          snapshot: buildColonialCivilianSnapshot(),
        ),
        isEmpty,
        reason:
            'OW resource tile is structurally suppressed in COLONIAL. '
            'A regression that emitted an OW order here would break '
            'the COLONIAL Suppressions rule and overlap with '
            '`planExpandEconomy` / `planDevelopCivilian` responsibilities.',
      );
    });

    test('foreign-owned NW tile excluded from output', () {
      final game = buildColonialCivilianGame(
        provinces: const [
          Province(
            id: kColonialCivilianNwProv1,
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
          Province(
            id: kColonialCivilianNwForeignProv,
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp2,
          ),
        ],
        owUnits: [colonialCivilianIdleBuilder('b1')],
        resourceByTileKey: const {
          kColonialCivilianNwForeignTile: 'gold',
          kColonialCivilianNwTileA: 'tobacco',
        },
      );
      final orders = planColonialCivilian(
        game: game,
        snapshot: buildColonialCivilianSnapshot(),
      );
      expect(orders.map((o) => o.targetTileKey), const [kColonialCivilianNwTileA]);
    });

    test('town tile is excluded even with resource entry', () {
      final game = buildColonialCivilianGame(
        provinces: const [
          Province(
            id: kColonialCivilianNwProv1,
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp1,
            townTileKey: kColonialCivilianNwTileTown,
          ),
        ],
        owUnits: [colonialCivilianIdleBuilder('b1')],
        resourceByTileKey: const {
          kColonialCivilianNwTileTown: 'tobacco',
          kColonialCivilianNwTileA: 'tobacco',
        },
      );
      final orders = planColonialCivilian(
        game: game,
        snapshot: buildColonialCivilianSnapshot(),
      );
      expect(orders.map((o) => o.targetTileKey), const [kColonialCivilianNwTileA]);
    });
  });
}
