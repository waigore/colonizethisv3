/// Validates that the per-target classification step of the diplomatic
/// sub-validators consults the optional `DiplomacyFactionMembership` snapshot
/// instead of falling back to linear `game.players` / `game.minorNations` /
/// `game.tribes` scans when the snapshot is supplied (Refs #2394 — O(1)
/// classification on per-candidate probe paths).
///
/// Coverage strategy:
///
/// 1. Positive equivalence — when the snapshot reflects the same membership
///    as `Game`, the validator's accept/reject decision is identical to the
///    no-snapshot path (membership must not change established behavior).
/// 2. Negative override — when the snapshot intentionally disagrees with
///    `Game`, the validator's classification follows the snapshot, proving
///    the fast path is on the active branch (snapshot is consulted, not the
///    `Game` collections).
library;

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/alliance_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/establish_overture_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomatic_sub_validators_test_support.dart';

void main() {
  group('allianceSubValidator factionMembership', () {
    test('accepts known GP target identically with and without snapshot', () {
      final game = twoGpGame();
      final membership = DiplomacyFactionMembership.from(game);
      const order = DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: 'gp2',
      );

      final withoutSnapshot = allianceSubValidator(
        diplomaticSubValidatorContext(game, 'gp1'),
      ).validate(order: order, treasury: 0);
      final withSnapshot = allianceSubValidator(
        diplomaticSubValidatorContext(
          game,
          'gp1',
          factionMembership: membership,
        ),
      ).validate(order: order, treasury: 0);

      expect(withoutSnapshot.result.status, OrderValidationStatus.accepted);
      expect(withSnapshot.result.status, OrderValidationStatus.accepted);
      expect(withSnapshot.treasury, withoutSnapshot.treasury);
    });

    test(
      'rejects non-GP target identically when snapshot has no GP membership',
      () {
        final game = gpMinorGame();
        final membership = DiplomacyFactionMembership.from(game);
        const order = DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'minor1',
        );

        final withoutSnapshot = allianceSubValidator(
          diplomaticSubValidatorContext(game, 'gp1'),
        ).validate(order: order, treasury: 0);
        final withSnapshot = allianceSubValidator(
          diplomaticSubValidatorContext(
            game,
            'gp1',
            factionMembership: membership,
          ),
        ).validate(order: order, treasury: 0);

        expect(withoutSnapshot.result.status, OrderValidationStatus.rejected);
        expect(withSnapshot.result.status, OrderValidationStatus.rejected);
        expect(withSnapshot.result.reason, withoutSnapshot.result.reason);
      },
    );

    test(
      'snapshot is consulted on active path: rejects target listed only in Game.players',
      () {
        final game = twoGpGame();
        final emptyMembership = DiplomacyFactionMembership.from(
          Game(
            id: 'empty',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 0,
              ),
              oldWorld: const RegionData(),
              newWorld: const RegionData(),
            ),
            players: const [],
          ),
        );

        final r =
            allianceSubValidator(
              diplomaticSubValidatorContext(
                game,
                'gp1',
                factionMembership: emptyMembership,
              ),
            ).validate(
              order: const DiplomaticOrder(
                type: DiplomaticOrderType.alliance,
                targetFactionId: 'gp2',
              ),
              treasury: 0,
            );

        expect(r.result.status, OrderValidationStatus.rejected);
        expect(r.result.reason, contains('Great Power'));
      },
    );
  });

  group('establishOvertureSubValidator factionMembership', () {
    test('accepts Trade Consulate toward Minor identically with snapshot', () {
      final game = gpMinorGame(overtureStage: OvertureStage.none);
      final membership = DiplomacyFactionMembership.from(game);
      const order = DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: 'minor1',
        overtureStage: OvertureStage.tradeConsulate,
      );
      final initialTreasury = overtureConsulateCost + 5;

      final withoutSnapshot = establishOvertureSubValidator(
        diplomaticSubValidatorContext(game, 'gp1'),
      ).validate(order: order, treasury: initialTreasury);
      final withSnapshot = establishOvertureSubValidator(
        diplomaticSubValidatorContext(
          game,
          'gp1',
          factionMembership: membership,
        ),
      ).validate(order: order, treasury: initialTreasury);

      expect(withoutSnapshot.result.status, OrderValidationStatus.accepted);
      expect(withSnapshot.result.status, OrderValidationStatus.accepted);
      expect(withSnapshot.treasury, withoutSnapshot.treasury);
    });

    test(
      'snapshot is consulted: rejects overture toward target absent from snapshot',
      () {
        final game = gpMinorGame(overtureStage: OvertureStage.none);
        final emptyMembership = DiplomacyFactionMembership.from(
          Game(
            id: 'empty',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 0,
              ),
              oldWorld: const RegionData(),
              newWorld: const RegionData(),
            ),
            players: const [],
          ),
        );

        final r =
            establishOvertureSubValidator(
              diplomaticSubValidatorContext(
                game,
                'gp1',
                factionMembership: emptyMembership,
              ),
            ).validate(
              order: const DiplomaticOrder(
                type: DiplomaticOrderType.establishOverture,
                targetFactionId: 'minor1',
                overtureStage: OvertureStage.tradeConsulate,
              ),
              treasury: overtureConsulateCost + 5,
            );

        expect(r.result.status, OrderValidationStatus.rejected);
        expect(
          r.result.reason,
          contains('Minor Nations, Tribes, or Great Powers'),
        );
        expect(r.treasury, overtureConsulateCost + 5);
      },
    );
  });

  group('DiplomaticOrderValidator factionMembership', () {
    test(
      'accepts equivalent classification with snapshot snapshot present',
      () {
        final game = gpMinorGame();
        final membership = DiplomacyFactionMembership.from(game);
        final withoutSnapshot = DiplomaticOrderValidator(
          game: game,
          playerId: 'gp1',
          initialTreasury: overtureConsulateCost + 1000,
        );
        final withSnapshot = DiplomaticOrderValidator(
          game: game,
          playerId: 'gp1',
          initialTreasury: overtureConsulateCost + 1000,
          factionMembership: membership,
        );

        final order = DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'minor1',
          overtureStage: OvertureStage.tradeConsulate,
        );

        final a = withoutSnapshot.validate(order, previousRejected: false);
        final b = withSnapshot.validate(order, previousRejected: false);
        expect(b.result.status, a.result.status);
        expect(b.treasury, a.treasury);
      },
    );

    test('snapshot is consulted on active path: rejects unknown target id', () {
      final game = gpMinorGame();
      final emptyMembership = DiplomacyFactionMembership.from(
        Game(
          id: 'empty',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [],
        ),
      );
      final validator = DiplomaticOrderValidator(
        game: game,
        playerId: 'gp1',
        initialTreasury: overtureConsulateCost + 1000,
        factionMembership: emptyMembership,
      );

      final r = validator.validate(
        const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'minor1',
          overtureStage: OvertureStage.tradeConsulate,
        ),
        previousRejected: false,
      );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('Target faction not found'));
    });
  });
}
