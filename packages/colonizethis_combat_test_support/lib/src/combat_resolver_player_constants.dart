// Standard player fixtures for land resolver integration tests (Refs #4196 slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

/// Standard att/def player pair for land resolver integration tests.
const landResolverAttDefPlayers = [
  Player(id: 'att', displayName: 'Att', isHuman: true),
  Player(id: 'def', displayName: 'Def', isHuman: false),
];

/// Both-human att/def pair.
const landResolverHumanPlayers = [
  Player(id: 'att', displayName: 'Att', isHuman: true),
  Player(id: 'def', displayName: 'Def', isHuman: true),
];

/// Napoleon/Frederick leader keys for multiplier path tests.
const landResolverNapoleonFrederickPlayers = [
  Player(
    id: 'att',
    displayName: 'France',
    isHuman: true,
    leaderKey: 'napoleon',
  ),
  Player(
    id: 'def',
    displayName: 'Prussia',
    isHuman: false,
    leaderKey: 'frederick',
  ),
];
