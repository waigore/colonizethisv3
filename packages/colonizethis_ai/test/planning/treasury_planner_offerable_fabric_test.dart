/// Offer-side market-fabric localization predicates
/// (Refs #2847 § S7-D market-fabric offer/acquisition).
///
/// `otherGreatPowerFabricHeld` (cast_iron_labour_gate.dart) is a gross-holdings
/// proxy: it counts `fabric` even when every holder withholds it via the
/// regiment-rebuild offer-retention carve-out, so a positive holdings total does
/// not prove any counterparty actually offers `fabric`. These tests pin the
/// offer-side refinement — `otherGreatPowerOfferableFabricHeld` excludes holders
/// that are themselves below-quota zero-NW zero-regiment lock-recovery sellers
/// (their `fabric` is staged toward the regiment build cost, not offered), and
/// `isFabricOfferRetainingLockRecoverySeller` mirrors that carve-out scope.
library;

import 'package:colonizethis_ai/src/planning/treasury_planner.dart'
    show
        isFabricOfferRetainingLockRecoverySeller,
        otherGreatPowerOfferableFabricHeld;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _ow = 'oldWorld';

/// One great power for the fixture: [ow] owned Old World provinces, [fabric]
/// units held, and whether it fields a [regiment] (lifts it out of the
/// zero-regiment retention carve-out).
typedef _Gp = ({String id, int ow, int fabric, bool regiment});

Game _game(List<_Gp> gps) {
  final provinces = <Province>[];
  final armies = <Army>[];
  for (final gp in gps) {
    for (var i = 0; i < gp.ow; i++) {
      provinces.add(
        Province(id: '$_ow|${gp.id}_$i', regionId: _ow, ownerId: gp.id),
      );
    }
    if (gp.regiment) {
      armies.add(
        Army(
          id: 'army-${gp.id}',
          ownerId: gp.id,
          regionId: _ow,
          stationedProvinceId: '$_ow|${gp.id}_0',
          regimentUnitIds: ['reg-${gp.id}'],
        ),
      );
    }
  }
  return Game(
    id: 'g-offerable-fabric',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(provinces: []),
      armies: armies,
    ),
    players: [
      for (final gp in gps)
        Player(
          id: gp.id,
          displayName: gp.id,
          isHuman: false,
          stockpile: gp.fabric > 0
              ? Stockpile.empty.applyDelta(
                  CommodityCatalog.fabric.id,
                  gp.fabric,
                )
              : Stockpile.empty,
        ),
    ],
  );
}

void main() {
  group('isFabricOfferRetainingLockRecoverySeller (Refs #2847)', () {
    test('positive: below-quota zero-NW seller holding zero regiments', () {
      final game = _game([(id: 'gp5', ow: 3, fabric: 5, regiment: false)]);
      expect(isFabricOfferRetainingLockRecoverySeller(game, 'gp5'), isTrue);
    });

    test('negative: a held regiment lifts the carve-out (seller offers)', () {
      final game = _game([(id: 'gp5', ow: 3, fabric: 5, regiment: true)]);
      expect(
        isFabricOfferRetainingLockRecoverySeller(game, 'gp5'),
        isFalse,
        reason: 'The retention targets the zero-regiment rebuild gap only.',
      );
    });

    test('negative: quota-met GP is not a lock-recovery seller', () {
      final game = _game([(id: 'gp5', ow: 12, fabric: 5, regiment: false)]);
      expect(
        isFabricOfferRetainingLockRecoverySeller(game, 'gp5'),
        isFalse,
        reason: 'The retention is scoped to below-quota zero-NW sellers.',
      );
    });

    test('negative: a GP owning no Old World province is not a seller', () {
      final game = _game([(id: 'gp5', ow: 0, fabric: 5, regiment: false)]);
      expect(isFabricOfferRetainingLockRecoverySeller(game, 'gp5'), isFalse);
    });
  });

  group('otherGreatPowerOfferableFabricHeld (Refs #2847)', () {
    test('positive: sums fabric across non-retaining offerable holders', () {
      // gp2 holds a regiment, gp3 is quota-met — both offer their fabric.
      final game = _game([
        (id: 'gp5', ow: 3, fabric: 0, regiment: false),
        (id: 'gp2', ow: 3, fabric: 4, regiment: true),
        (id: 'gp3', ow: 12, fabric: 6, regiment: false),
      ]);
      expect(otherGreatPowerOfferableFabricHeld(game, 'gp5'), 10);
    });

    test(
      'excludes retaining lock-recovery sellers (door closed at offer layer)',
      () {
        // gp1 holds fabric but is a below-quota zero-NW zero-regiment seller, so
        // it withholds every unit — gross holdings are positive yet none is
        // offerable.
        final game = _game([
          (id: 'gp5', ow: 3, fabric: 0, regiment: false),
          (id: 'gp1', ow: 3, fabric: 5, regiment: false),
        ]);
        expect(otherGreatPowerOfferableFabricHeld(game, 'gp5'), 0);
      },
    );

    test('mixed holders: only the offerable share is counted', () {
      final game = _game([
        (id: 'gp5', ow: 3, fabric: 0, regiment: false),
        (id: 'gp1', ow: 3, fabric: 5, regiment: false), // retained
        (id: 'gp2', ow: 3, fabric: 4, regiment: true), // offerable
      ]);
      expect(otherGreatPowerOfferableFabricHeld(game, 'gp5'), 4);
    });

    test('excludes the queried seller\'s own fabric holdings', () {
      final game = _game([
        (id: 'gp5', ow: 3, fabric: 9, regiment: true),
        (id: 'gp1', ow: 3, fabric: 5, regiment: false), // retained
      ]);
      expect(otherGreatPowerOfferableFabricHeld(game, 'gp5'), 0);
    });
  });
}
