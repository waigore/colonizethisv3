import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';

/// Shared GP ids for EXPAND-phase planner unit tests (Refs #3278 item 9).
const String kExpandTestGp1 = 'gp1';
const String kExpandTestGp2 = 'gp2';
const String kExpandTestGp3 = 'gp3';
const String kExpandTestGp4 = 'gp4';

/// Three-GP roster with affluent treasury (declare-war / military defaults).
const List<Player> kExpandTestPlayers3Affluent = [
  Player(
    id: kExpandTestGp1,
    displayName: 'GP1',
    isHuman: false,
    treasury: 9999,
  ),
  Player(
    id: kExpandTestGp2,
    displayName: 'GP2',
    isHuman: false,
    treasury: 9999,
  ),
  Player(
    id: kExpandTestGp3,
    displayName: 'GP3',
    isHuman: false,
    treasury: 9999,
  ),
];

/// Four-GP roster without explicit treasury (peace planner defaults).
const List<Player> kExpandTestPlayers4Neutral = [
  Player(id: kExpandTestGp1, displayName: 'GP1', isHuman: false),
  Player(id: kExpandTestGp2, displayName: 'GP2', isHuman: false),
  Player(id: kExpandTestGp3, displayName: 'GP3', isHuman: false),
  Player(id: kExpandTestGp4, displayName: 'GP4', isHuman: false),
];

/// Extensible EXPAND-phase [Game] scaffold (Refs #3278 item 9 / issue #2509).
///
/// [gameIdLabel] preserves each test file's prior `g-2509-<label>-t<N>` id
/// pattern. Override only the parameters a test varies.
Game buildExpandGame({
  required String gameIdLabel,
  int turnNumber = 50,
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  List<Player>? players,
  bool defaultFourGpPlayers = false,
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
  List<Army> armies = const [],
  List<Unit> oldWorldUnits = const [],
  List<DiplomaticEvent> diplomaticHistoryEvents = const [],
}) {
  return Game(
    id: 'g-2509-$gameIdLabel-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: oldWorldProvinces, units: oldWorldUnits),
      newWorld: RegionData(provinces: newWorldProvinces),
      armies: armies,
    ),
    players:
        players ??
        (defaultFourGpPlayers
            ? kExpandTestPlayers4Neutral
            : kExpandTestPlayers3Affluent),
    tribes: tribes,
    minorNations: minorNations,
    diplomaticHistoryEvents: diplomaticHistoryEvents,
  );
}

/// Extensible EXPAND-phase [AIWorldSnapshot] scaffold (Refs #3278 item 9).
///
/// Defaults mirror the below-quota EXPAND posture used across peace,
/// declare-war, economy, and military planner pins.
AIWorldSnapshot buildExpandSnapshot({
  String playerId = kExpandTestGp1,
  List<String> atWarWith = const [],
  List<String> invadableOw = const [],
  List<String> adjacentOwners = const [],
  int oldWorldProvincesOwned = 8,
  List<String> invadableNw = const [],
  int newWorldProvincesOwned = 0,
  List<String> adjacentNewWorldOwnerFactionIdsSorted = const [],
  List<String> preferredColonialTargetFactionIdsSorted = const [],
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: invadableOw,
      adjacentOwnerFactionIdsSorted: adjacentOwners,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: invadableNw,
      newWorldProvincesOwned: newWorldProvincesOwned,
      adjacentNewWorldOwnerFactionIdsSorted:
          adjacentNewWorldOwnerFactionIdsSorted,
      preferredColonialTargetFactionIdsSorted:
          preferredColonialTargetFactionIdsSorted,
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}
