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
  Game nextTurn(Game current) {
    final newWorldState = resolveTurn(current.worldState);
    final newGame = current.copyWith(worldState: newWorldState);
    saveGame(newGame);
    return newGame;
  }

  /// Creates a minimal new game, saves it, and returns it. Used to wire "new game" in shell.
  Game createNewGame({String? id}) {
    final gameId = id ?? 'game_${DateTime.now().millisecondsSinceEpoch}';
    final game = Game(
      id: gameId,
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: const [Player(id: 'human', displayName: 'Player', isHuman: true)],
    );
    saveGame(game);
    return game;
  }
}
