// Shared Game fixtures for faction_query util pins (Refs #4310 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

const String kFactionQueryGp1 = 'gp1';
const String kFactionQueryMinorA = 'minorA';
const String kFactionQueryMinorB = 'minorB';
const String kFactionQueryTribeA = 'tribeA';
const String kFactionQueryTribeB = 'tribeB';

/// Minimal `Game` scaffold with deterministic minor-nation and tribe
/// rosters; province / world state details are irrelevant for these
/// predicates.
Game factionQueryGame({
  List<MinorNation> minorNations = const [
    MinorNation(id: kFactionQueryMinorA, displayName: 'Minor A'),
    MinorNation(id: kFactionQueryMinorB, displayName: 'Minor B'),
  ],
  List<Tribe> tribes = const [
    Tribe(id: kFactionQueryTribeA, displayName: 'Tribe A'),
    Tribe(id: kFactionQueryTribeB, displayName: 'Tribe B'),
  ],
}) {
  return Game(
    id: 'g-faction-query',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: kFactionQueryGp1, displayName: 'GP1', isHuman: false),
    ],
    minorNations: minorNations,
    tribes: tribes,
  );
}
