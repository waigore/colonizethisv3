// Fixtures for appendMilitaryRegimentToArmy armiesById scenarios
// (Refs #3949 wave 3, #3971 wave 4).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const amrPlayerId = 'p1';
const amrCapProvinceId = 'oldWorld|P1';

Player amrBuildPlayer() => Player(
  id: amrPlayerId,
  displayName: 'P1',
  isHuman: true,
  capitalProvinceId: amrCapProvinceId,
  stockpile: const Stockpile(),
  workerPool: const WorkerPool(peasants: 10),
  treasury: 10000,
);

const _amrOwnedProvince = RegionData(
  provinces: [
    Province(id: amrCapProvinceId, regionId: 'oldWorld', ownerId: amrPlayerId),
  ],
  units: [],
);

Game amrEmptyArmyGame() => ordersOwRegionGame(
  id: 'g',
  players: [amrBuildPlayer()],
  oldWorld: _amrOwnedProvince,
);

Game amrGameWithExistingHomeArmy() => ordersOwRegionGame(
  id: 'g',
  players: [amrBuildPlayer()],
  oldWorld: _amrOwnedProvince,
  armies: [
    Army(
      id: homeArmyIdFor(amrPlayerId),
      ownerId: amrPlayerId,
      regionId: 'oldWorld',
      stationedProvinceId: amrCapProvinceId,
      regimentUnitIds: const ['u_existing'],
      isHomeArmy: true,
    ),
  ],
);
