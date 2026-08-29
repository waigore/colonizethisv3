// Offerable-fabric Game factory for treasury satellite pins (Refs #4669 Slice D).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

typedef TreasuryOfferableFabricGp = ({String id, int ow, int fabric, bool regiment});

Game treasuryPlannerOfferableFabricGame(List<TreasuryOfferableFabricGp> gps) {
  final provinces = <Province>[];
  final armies = <Army>[];
  for (final gp in gps) {
    for (var i = 0; i < gp.ow; i++) {
      provinces.add(
        Province(id: 'oldWorld|${gp.id}_$i', regionId: 'oldWorld', ownerId: gp.id),
      );
    }
    if (gp.regiment) {
      armies.add(
        Army(
          id: 'army-${gp.id}',
          ownerId: gp.id,
          regionId: 'oldWorld',
          stationedProvinceId: 'oldWorld|${gp.id}_0',
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
