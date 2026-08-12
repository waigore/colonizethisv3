// Shared Game / snapshot fixtures for sole-GP-war helper pins (Refs #4310).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String soleGpWarHelpersGp1 = 'gp1';
const String soleGpWarHelpersGp2 = 'gp2';
const String soleGpWarHelpersGp3 = 'gp3';
const String soleGpWarHelpersMinor1 = 'minor1';
const String soleGpWarHelpersTribe1 = 'tribe1';

Game soleGpWarHelpersGameWithGpsAndMinors({
  List<String> playerIds = const [
    soleGpWarHelpersGp1,
    soleGpWarHelpersGp2,
    soleGpWarHelpersGp3,
  ],
  List<String> minorIds = const [soleGpWarHelpersMinor1],
}) {
  return Game(
    id: 'g-2509-sole-gp-war-helpers-canonical',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 60, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      for (final id in playerIds)
        Player(id: id, displayName: id.toUpperCase(), isHuman: false),
    ],
    minorNations: [
      for (final id in minorIds) MinorNation(id: id, displayName: id),
    ],
  );
}

AIWorldSnapshot soleGpWarHelpersSnapshotAtWarWith(List<String> atWarWith) {
  return AIWorldSnapshot(
    playerId: soleGpWarHelpersGp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

Game soleGpWarHelpersGameWithProvinces({
  required List<Province> owProvinces,
  List<Province> nwProvinces = const [],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-can-pivot-from-sole-gp-war-canonical',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 80, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: owProvinces),
      newWorld: RegionData(provinces: nwProvinces),
    ),
    players: const [
      Player(id: soleGpWarHelpersGp1, displayName: 'GP1', isHuman: false),
      Player(id: soleGpWarHelpersGp2, displayName: 'GP2', isHuman: false),
    ],
    minorNations: minorNations,
  );
}

AIWorldSnapshot soleGpWarHelpersPivotSnapshotFor({
  required int oldWorldProvincesOwned,
  List<String> invadableProvinceIdsSorted = const [],
  List<String> atWarWith = const [soleGpWarHelpersGp2],
}) {
  return AIWorldSnapshot(
    playerId: soleGpWarHelpersGp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

List<Province> soleGpWarHelpersGp1OwProvinces(int count) {
  return [
    for (var i = 1; i <= count; i++)
      Province(
        id: 'oldWorld|gp1_$i',
        regionId: 'oldWorld',
        ownerId: soleGpWarHelpersGp1,
      ),
  ];
}
