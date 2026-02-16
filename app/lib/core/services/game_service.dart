import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

/// Loads/saves games and advances turn. SPEC/project/phase-1: app invokes TurnResolver and persists via colonizethis_save.
class GameService {
  GameService(this._box, this._adapter);

  final Box<dynamic> _box;
  final GameSaveAdapter _adapter;

  /// Loads game by id. Returns null if not found.
  Game? loadGame(String gameId) => _adapter.load(_box, gameId);

  /// Saves game to storage.
  void saveGame(Game game) => _adapter.save(_box, game);

  /// Lists all saved game ids.
  List<String> listGameIds() => _adapter.listGameIds(_box);

  /// Resolves one turn, persists the new state, and returns the updated game.
  ///
  /// Phase 2: this uses the Game-level resolver so that economy and movement
  /// phases can operate on players, stockpiles, workers, and units.
  ///
  /// Currently, topology is loaded once per call via colonizethis_data and
  /// orders are passed in by the caller (UI or AI).
  Game nextTurn(Game current, {Orders? orders, MapTopology? topology}) {
    final resolvedOrders = orders ?? const Orders();
    final topo = topology ?? const MapTopology();
    final newGame = resolveTurnForGame(
      game: current,
      topology: topo,
      orders: resolvedOrders,
    );
    saveGame(newGame);
    return newGame;
  }

  /// Creates a minimal new game, saves it, and returns it. Used to wire "new game" in shell.
  Game createNewGame({String? id}) {
    final gameId = id ?? 'game_${DateTime.now().millisecondsSinceEpoch}';
    final game = Game(
      id: gameId,
      worldState: const WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(
          id: 'human',
          displayName: 'Player',
          isHuman: true,
        ),
      ],
    );
    saveGame(game);
    return game;
  }
}
