// Shared fixtures for own-province prospect budget priority scenarios (Refs #3971).
//
// Refs #2847 § Old World mineral feedstock prospect localization (gp1 residual).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const orderSuggestionProspectOwnProvinceBudgetPriorityPlayerId = 'gp1';
const orderSuggestionProspectOwnProvinceBudgetPriorityRegionId =
    kRegionOldWorld;

const orderSuggestionProspectOwnProvinceBudgetPriorityDrainProvinceId =
    'oldWorld|aaa_drain';
const orderSuggestionProspectOwnProvinceBudgetPriorityDrainTiles = <String>[
  'oldWorld|aaa_drain|0|0',
  'oldWorld|aaa_drain|1|0',
  'oldWorld|aaa_drain|2|0',
  'oldWorld|aaa_drain|3|0',
];

const orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockProvinceId =
    'oldWorld|zzz_feedstock';
const orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockTileKey =
    'oldWorld|zzz_feedstock|0|0';
const orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockUnitId =
    'e_feedstock';

const orderSuggestionProspectOwnProvinceBudgetPriorityDrainerCount = 30;

Game orderSuggestionProspectOwnProvinceBudgetPriorityGame({
  bool feedstockAlreadyProspected = false,
}) {
  const playerId = orderSuggestionProspectOwnProvinceBudgetPriorityPlayerId;
  const ow = orderSuggestionProspectOwnProvinceBudgetPriorityRegionId;
  const drainProvinceId =
      orderSuggestionProspectOwnProvinceBudgetPriorityDrainProvinceId;
  const drainTiles = orderSuggestionProspectOwnProvinceBudgetPriorityDrainTiles;
  const feedstockProvinceId =
      orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockProvinceId;
  const feedstockTileKey =
      orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockTileKey;
  const feedstockUnitId =
      orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockUnitId;
  const drainerCount =
      orderSuggestionProspectOwnProvinceBudgetPriorityDrainerCount;

  final drainProvince = Province(
    id: drainProvinceId,
    regionId: ow,
    ownerId: playerId,
  );
  final feedstockProvince = Province(
    id: feedstockProvinceId,
    regionId: ow,
    ownerId: playerId,
  );

  final drainerProvinces = <Province>[];
  final units = <Unit>[];
  final tileKeysByRegion = <String, List<String>>{};
  final visibility = <String, String>{
    for (final tk in drainTiles) tk: 'fogged',
    feedstockTileKey: 'fogged',
  };
  final resourceByTile = <String, String>{
    for (final tk in drainTiles) tk: 'iron',
    feedstockTileKey: 'iron',
  };

  for (var i = 0; i < drainerCount; i++) {
    final provId = 'oldWorld|d${i.toString().padLeft(2, '0')}';
    drainerProvinces.add(Province(id: provId, regionId: ow, ownerId: playerId));
    units.add(
      Unit(
        id: 'drain_${i.toString().padLeft(2, '0')}',
        type: kUnitTypeExplorer,
        ownerId: playerId,
        locationProvinceId: provId,
      ),
    );
    tileKeysByRegion[provId] = const <String>[];
  }

  units.add(
    Unit(
      id: feedstockUnitId,
      type: kUnitTypeExplorer,
      ownerId: playerId,
      locationProvinceId: feedstockProvinceId,
    ),
  );
  tileKeysByRegion[drainProvinceId] = List<String>.from(drainTiles);
  tileKeysByRegion[feedstockProvinceId] = const [feedstockTileKey];

  return ordersOwRegionGame(
    id: 'g',
    turnNumber: 1,
    players: const [Player(id: playerId, displayName: 'GP', isHuman: false)],
    oldWorld: RegionData(
      provinces: [...drainerProvinces, drainProvince, feedstockProvince],
      units: units,
    ),
    playerVisibilityByTile: {playerId: visibility},
    playerProspectedTiles: {
      playerId: {if (feedstockAlreadyProspected) feedstockTileKey},
    },
    resourceByTileKey: resourceByTile,
    tileKeysByRegionAndProvince: {ow: tileKeysByRegion},
  );
}

MapTopology orderSuggestionProspectOwnProvinceBudgetPriorityTopology(
  Game game,
) => ordersProvinceTopology(
  game.worldState.oldWorld.provinces,
  regionId: orderSuggestionProspectOwnProvinceBudgetPriorityRegionId,
);

List<WorkOrder>
orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockProspects(
  List<WorkOrder> suggestions,
) => suggestions
    .where(
      (o) =>
          o.unitId ==
              orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockUnitId &&
          o.target == kWorkTargetProspect,
    )
    .toList();
