import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Game generalCapTestGameWith({
  required List<Player> players,
  List<General> generals = const [],
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
    generals: generals,
  );
}

Player generalCapTestGp(String id, {Map<String, bool>? tech, int? cap}) =>
    Player(
      id: id,
      displayName: id,
      isHuman: false,
      techUnlocked: tech,
      generalCap: cap,
    );

List<General> generalCapTestGeneralsFor(Game game, String ownerId) =>
    game.generals.where((g) => g.ownerId == ownerId).toList();
