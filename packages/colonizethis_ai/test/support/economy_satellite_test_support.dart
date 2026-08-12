// Shared Game fixtures for economy / orchestrator satellite pins (Refs #4310).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String economyCastIronSellerNationId = 'gp_seller';

/// Seller GP with fabric stockpile for cast-iron labour peasant-recruit pins.
Game economyCastIronSellerGame({int fabricHeld = 2}) {
  return Game(
    id: 'g-peasant-recruit',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < 5; i++)
            Province(
              id: 'oldWorld|p$i',
              regionId: 'oldWorld',
              ownerId: economyCastIronSellerNationId,
            ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: economyCastIronSellerNationId,
        displayName: 'Seller',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: Stockpile(quantities: {'fabric': fabricHeld}),
      ),
    ],
  );
}

/// Single-GP cotton-only fabric feedstock for cotton-weaving gate pins.
Game economyCottonOnlyGame({
  required int cotton,
  Map<String, bool>? techUnlocked,
}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g-cotton-gate',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: const RegionData(
        provinces: [
          Province(id: '$ow|p0', regionId: ow, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: '$ow|p0',
        treasury: 100,
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 30)
            .applyDelta(CommodityCatalog.cotton.id, cotton),
        workerPool: const WorkerPool(peasants: 12),
        techUnlocked: techUnlocked,
      ),
    ],
  );
}

const String economyBrokeAtPeaceNationId = 'gp1';
const String economyBrokeAtPeaceHomeProvince = 'oldWorld|p1';

/// Below-quota peace + insufficient regiments trap for phase-plan injection pins.
Game economyBrokeAtPeaceGame() {
  return const Game(
    id: 'g-2509-economy-phase-plan-injection',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: economyBrokeAtPeaceHomeProvince,
            regionId: 'oldWorld',
            ownerId: economyBrokeAtPeaceNationId,
          ),
        ],
      ),
      newWorld: RegionData(),
      armies: [
        Army(
          id: 'army_gp1',
          ownerId: economyBrokeAtPeaceNationId,
          regionId: 'oldWorld',
          stationedProvinceId: economyBrokeAtPeaceHomeProvince,
          regimentUnitIds: ['u1', 'u2', 'u3'],
          isHomeArmy: true,
        ),
      ],
    ),
    players: [
      Player(
        id: economyBrokeAtPeaceNationId,
        displayName: 'France',
        isHuman: false,
        treasury: 0,
        stockpile: Stockpile(),
        workerPool: WorkerPool(peasants: 0),
      ),
    ],
  );
}

const String economyNavalBootstrapNationId = 'gp3';
const String economyNavalBootstrapHome = 'oldWorld|gp3_0';
const String economyNavalBootstrapMinor = 'oldWorld|minor1';

/// First-naval-transport bootstrap scenario with optional treasury and fleets.
Game economyNavalBootstrapGame({
  int treasury = 0,
  List<Fleet> fleets = const [],
}) {
  return Game(
    id: 'g-2847-first-naval-bootstrap',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 20),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|gp3_$i',
              regionId: 'oldWorld',
              ownerId: economyNavalBootstrapNationId,
            ),
          const Province(
            id: economyNavalBootstrapMinor,
            regionId: 'oldWorld',
            ownerId: 'minor1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      fleets: fleets,
      armies: const [
        Army(
          id: 'home_gp3',
          ownerId: economyNavalBootstrapNationId,
          regionId: 'oldWorld',
          stationedProvinceId: economyNavalBootstrapHome,
          regimentUnitIds: [],
          isHomeArmy: true,
        ),
      ],
    ),
    players: [
      Player(
        id: economyNavalBootstrapNationId,
        displayName: 'GP3',
        isHuman: false,
        treasury: treasury,
        capitalProvinceId: economyNavalBootstrapHome,
      ),
    ],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Minor'),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: economyNavalBootstrapNationId,
        factionId2: 'minor1',
        state: RelationState.atWar,
        score: -100,
      ),
    ],
  );
}
