import 'package:colonizethis_models/colonizethis_models.dart';

/// Mid-turn draft fields stored beside [Game] in the Hive envelope.
/// SPEC/program/save-load.md § Mid-turn draft envelope.
class GameSaveSession {
  const GameSaveSession({
    required this.game,
    this.draftOrders = const Orders(),
    this.productionDesiredOutputByRecipe = const <String, int>{},
    this.displayName,
  });

  final Game game;
  final Orders draftOrders;
  final Map<String, int> productionDesiredOutputByRecipe;

  /// User-facing save label; null on legacy envelopes (UI falls back to Hive id).
  final String? displayName;
}
