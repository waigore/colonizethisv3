import 'src/test_fixtures_combat_game.dart';
import 'src/test_fixtures_domain_games.dart';
import 'src/test_fixtures_game_core.dart';
import 'src/test_fixtures_units.dart';
import 'src/test_fixtures_world_state.dart';

/// Shared [Game] / [WorldState] factories for cross-package tests.
///
/// Refs waigore/colonizethis#2071 (centralize repeated setup); #3424 Slice 1.
/// Implementation lives under `lib/src/`; this file is the stable public import.
abstract final class TestFixtures {
  TestFixtures._();

  static final emptyWorldState = TestFixturesWorldState.emptyWorldState;
  static final worldStateAtOrdersPhase =
      TestFixturesWorldState.worldStateAtOrdersPhase;
  static final minimalGame = TestFixturesGameCore.minimalGame;
  static final oldWorldGameWithUnit = TestFixturesDomainGames.oldWorldGameWithUnit;
  static final gameWithSingleOwnedProvince =
      TestFixturesDomainGames.gameWithSingleOwnedProvince;
  static final singlePlayerGame = TestFixturesDomainGames.singlePlayerGame;
  static final singlePlayerWorkPreviewGame =
      TestFixturesDomainGames.singlePlayerWorkPreviewGame;
  static final multiProvinceGame = TestFixturesDomainGames.multiProvinceGame;
  static final navalGame = TestFixturesDomainGames.navalGame;
  static final economyGame = TestFixturesDomainGames.economyGame;
  static final twoPlayerGame = TestFixturesDomainGames.twoPlayerGame;
  static final combatGame = TestFixturesCombatGame.combatGame;
  static final testCivilianUnit = TestFixturesUnits.testCivilianUnit;
  static final testMilitaryUnit = TestFixturesUnits.testMilitaryUnit;
  static final testNavalScenarioUnit = TestFixturesUnits.testNavalScenarioUnit;
}
