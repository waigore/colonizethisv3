/// Equivalence tests for [ArmyMoveValidator] with optional `armiesById`.
///
/// Verifies that the O(1) `Map<String, Army>` lookup path introduced for
/// Refs #2394 (SPEC/program/order-suggestions.md — incremental validation)
/// produces the same `OrderValidationResult` as the legacy single-pass scan.
library;

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'move_validator_test_support.dart';

void main() {
  const ow = 'oldWorld';
  final topology = moveValidatorTestTwoProvinceTopology(ow);
  const validator = ArmyMoveValidator();

  Game buildSampleGame() {
    return Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(
          provinces: [
            Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'pikemen',
              ownerId: 'p1',
              locationProvinceId: '$ow|P1',
            ),
          ],
        ),
        newWorld: const RegionData(),
        armies: [
          moveValidatorTestFieldArmy(ow, 'p1', 'P1', 'u1'),
        ],
        playerVisibilityByTile: const {
          'p1': {
            'oldWorld|P1|0|0': 'fullyVisible',
            'oldWorld|P2|0|0': 'fullyVisible',
          },
        },
      ),
      players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
    );
  }

  group('ArmyMoveValidator armiesById equivalence', () {
    test(
      'accepted result is identical with and without supplied armiesById',
      () {
        final game = buildSampleGame();
        final view = buildPlayerView(game, topology, 'p1');
        final armiesById = {
          for (final a in game.worldState.armies) a.id: a,
        };
        final order = ArmyMoveOrder(
          armyId: fieldArmyIdFor('p1', '$ow|P1'),
          destinationProvinceId: '$ow|P2',
        );

        final without = validator.validate(
          order,
          game,
          'p1',
          const [],
          view,
          topology,
        );
        final with_ = validator.validate(
          order,
          game,
          'p1',
          const [],
          view,
          topology,
          armiesById: armiesById,
        );

        expect(with_.status, without.status);
        expect(with_.status, OrderValidationStatus.accepted);
      },
    );

    test(
      'rejected result is identical with and without supplied armiesById',
      () {
        // Unknown army id should be rejected on both paths.
        final game = buildSampleGame();
        final view = buildPlayerView(game, topology, 'p1');
        final armiesById = {
          for (final a in game.worldState.armies) a.id: a,
        };
        const order = ArmyMoveOrder(
          armyId: 'army_does_not_exist',
          destinationProvinceId: '$ow|P2',
        );

        final without = validator.validate(
          order,
          game,
          'p1',
          const [],
          view,
          topology,
        );
        final with_ = validator.validate(
          order,
          game,
          'p1',
          const [],
          view,
          topology,
          armiesById: armiesById,
        );

        expect(with_.status, without.status);
        expect(with_.status, OrderValidationStatus.rejected);
        expect(with_.reason, without.reason);
      },
    );

    test(
      'armiesById missing the target army id is rejected as Invalid army move',
      () {
        // Caller-supplied map omitting the targeted army id: validator
        // must treat it as not found (no silent fallback to the world list).
        final game = buildSampleGame();
        final view = buildPlayerView(game, topology, 'p1');
        final partialMap = <String, Army>{
          // Intentionally empty: simulates caller map missing the entry.
        };
        final order = ArmyMoveOrder(
          armyId: fieldArmyIdFor('p1', '$ow|P1'),
          destinationProvinceId: '$ow|P2',
        );

        final result = validator.validate(
          order,
          game,
          'p1',
          const [],
          view,
          topology,
          armiesById: partialMap,
        );

        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Invalid army move');
      },
    );

    test(
      'IncrementalCandidateValidator.isArmyMoveAccepted matches '
      'ArmyMoveValidator.validate (Refs #2394 incremental hot path)',
      () {
        final game = buildSampleGame();
        final view = buildPlayerView(game, topology, 'p1');
        final armiesById = {
          for (final a in game.worldState.armies) a.id: a,
        };
        final order = ArmyMoveOrder(
          armyId: fieldArmyIdFor('p1', '$ow|P1'),
          destinationProvinceId: '$ow|P2',
        );

        final incremental = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: 'p1',
          basePrefix: const Orders(),
        );

        final directResult = validator.validate(
          order,
          game,
          'p1',
          const [],
          view,
          topology,
          armiesById: armiesById,
        );

        expect(incremental.isArmyMoveAccepted(order), directResult.isAccepted);
        expect(directResult.status, OrderValidationStatus.accepted);
      },
    );

    test(
      'factionMembership path matches legacy GP declare-war guard (Refs #2394)',
      () {
        final game = Game(
          id: 'g2',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'pikemen',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: [
              moveValidatorTestFieldArmy(ow, 'p1', 'P1', 'u1'),
            ],
            playerVisibilityByTile: const {
              'p1': {
                'oldWorld|P1|0|0': 'fullyVisible',
                'oldWorld|P2|0|0': 'fullyVisible',
              },
            },
          ),
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: false),
          ],
        );
        final view = buildPlayerView(game, topology, 'p1');
        final membership = DiplomacyFactionMembership.from(game);
        final order = ArmyMoveOrder(
          armyId: fieldArmyIdFor('p1', '$ow|P1'),
          destinationProvinceId: '$ow|P2',
        );

        final without = validator.validate(
          order,
          game,
          'p1',
          const [],
          view,
          topology,
        );
        final withMembership = validator.validate(
          order,
          game,
          'p1',
          const [],
          view,
          topology,
          factionMembership: membership,
        );

        expect(withMembership.status, without.status);
        expect(without.status, OrderValidationStatus.rejected);
        expect(without.reason, contains('declare war'));
        expect(withMembership.reason, without.reason);
      },
    );
  });
}
