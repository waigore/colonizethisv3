// Fixtures for civilian_units_sort helper tests (Refs #2575 / #4642 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

const civilianSortHumanId = 'gp1';
const civilianSortOtherId = 'gp2';

Game civilianSortTestGameWith({
  List<Unit> oldUnits = const [],
  List<Unit> newUnits = const [],
  List<Province> oldProvinces = const [],
  List<Province> newProvinces = const [],
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: oldProvinces, units: oldUnits),
      newWorld: RegionData(provinces: newProvinces, units: newUnits),
    ),
    players: const [
      Player(id: civilianSortHumanId, displayName: 'Human', isHuman: true),
      Player(id: civilianSortOtherId, displayName: 'Other', isHuman: false),
    ],
    minorNations: const [],
    tribes: const [],
  );
}
