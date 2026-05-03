import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared [Game] / [WorldState] factories for logic package tests.
///
/// Refactor slice for waigore/colonizethis#2071 (centralize repeated setup).
abstract final class TestFixtures {
  TestFixtures._();

  /// Both regions empty; tunable turn.
  static WorldState emptyWorldState({
    TurnPhase phase = TurnPhase.orders,
    int turnNumber = 1,
  }) =>
      WorldState(
        turnState: TurnState(phase: phase, turnNumber: turnNumber),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );

  /// Minimal [Game] with default empty regions and a single human player.
  static Game minimalGame({
    String id = 'g',
    List<Player> players = const [
      Player(id: 'h1', displayName: 'Human', isHuman: true),
    ],
    TurnPhase phase = TurnPhase.orders,
    int turnNumber = 1,
    RegionData? oldWorld,
    RegionData? newWorld,
    Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
        const {},
    TileMapState? tileState,
    double richesCashMultiplier = 1.0,
  }) =>
      Game(
        id: id,
        worldState: WorldState(
          turnState: TurnState(phase: phase, turnNumber: turnNumber),
          oldWorld: oldWorld ?? const RegionData(),
          newWorld: newWorld ?? const RegionData(),
          tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
          tileState: tileState ?? const TileMapState(),
        ),
        players: players,
        richesCashMultiplier: richesCashMultiplier,
      );

  /// Old World land with [unit]; New World empty. Default provinces match
  /// common work-order tests (`oldWorld|p1`, `oldWorld|p2`).
  static Game oldWorldGameWithUnit({
    required Unit unit,
    List<Province> provinces = const [
      Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
      Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
    ],
    List<Player> players = const [
      Player(id: 'h1', displayName: 'Human', isHuman: true),
    ],
    int turnNumber = 1,
    Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
        const {},
    TileMapState? tileState,
  }) =>
      minimalGame(
        players: players,
        turnNumber: turnNumber,
        oldWorld: RegionData(provinces: provinces, units: [unit]),
        tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
        tileState: tileState,
      );

  /// One old-world province owned by the sole player (validator / spawn tests).
  static Game gameWithSingleOwnedProvince({
    String id = 'g',
    String ownerPlayerId = 'gp1',
    String provinceId = 'oldWorld|p1',
    int treasury = 0,
    String displayName = 'P',
    bool isHuman = true,
  }) =>
      minimalGame(
        id: id,
        players: [
          Player(
            id: ownerPlayerId,
            displayName: displayName,
            isHuman: isHuman,
            capitalProvinceId: provinceId,
            treasury: treasury,
          ),
        ],
        oldWorld: RegionData(
          provinces: [
            Province(
              id: provinceId,
              regionId: 'oldWorld',
              ownerId: ownerPlayerId,
            ),
          ],
        ),
      );
}
