// Shared fixtures for develop-phase civilian Builder pairing pins (Refs #4669).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'develop_phase_planner_support.dart';

const String kDevelopPhaseCivilianPairingOwProv1 = 'oldWorld|p_alpha';
const String kDevelopPhaseCivilianPairingOwProv2 = 'oldWorld|p_beta';
const String kDevelopPhaseCivilianPairingNwProv1 = 'newWorld|p_gamma';

const String kDevelopPhaseCivilianPairingOwTileA = 'oldWorld|p_alpha|1|1';
const String kDevelopPhaseCivilianPairingOwTileB = 'oldWorld|p_alpha|2|2';
const String kDevelopPhaseCivilianPairingOwTileTown = 'oldWorld|p_alpha|0|0';
const String kDevelopPhaseCivilianPairingOwTileImproved = 'oldWorld|p_beta|1|1';
const String kDevelopPhaseCivilianPairingNwTileA = 'newWorld|p_gamma|1|1';

Game developPhaseCivilianPairingGame({
  required List<Province> provinces,
  required List<Unit> owUnits,
  List<Unit> nwUnits = const [],
  Map<String, String> resourceByTileKey = const {},
  TileMapState tileState = const TileMapState(),
}) {
  final byRegion = <String, List<Province>>{};
  for (final province in provinces) {
    byRegion.putIfAbsent(province.regionId, () => <Province>[]).add(province);
  }
  return Game(
    id: 'g-2509-develop-phase-planner-civilian',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 145, phase: TurnPhase.orders),
      oldWorld: RegionData(
        provinces: byRegion[kOldWorldRegionId] ?? const [],
        units: owUnits,
      ),
      newWorld: RegionData(
        provinces: byRegion[kNewWorldRegionId] ?? const [],
        units: nwUnits,
      ),
      resourceByTileKey: resourceByTileKey,
      tileState: tileState,
    ),
    players: const [
      Player(id: kDevelopPhaseGp1, displayName: 'GP1', isHuman: false),
      Player(id: kDevelopPhaseGp2, displayName: 'GP2', isHuman: false),
    ],
  );
}

AIWorldSnapshot developPhaseCivilianPairingSnapshot() {
  return AIWorldSnapshot(
    playerId: kDevelopPhaseGp1,
    threats: const ThreatSummary(atWarWith: []),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

Unit developPhaseIdleBuilder(String id, {String regionId = kOldWorldRegionId}) {
  final provinceId = regionId == kOldWorldRegionId
      ? kDevelopPhaseCivilianPairingOwProv1
      : kDevelopPhaseCivilianPairingNwProv1;
  return Unit(
    id: id,
    type: kUnitTypeBuilder,
    ownerId: kDevelopPhaseGp1,
    locationProvinceId: provinceId,
    tileKey: '$provinceId|9|9',
  );
}
