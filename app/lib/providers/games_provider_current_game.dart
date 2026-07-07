part of 'games_provider.dart';

/// List of saved game ids. Refreshed by reading from GameService.
final gameListIdsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(gameServiceProvider);
  return service.listGameIds();
});

/// Currently loaded game, if any. Updated on load and after next turn.
class CurrentGameNotifier extends Notifier<Game?> {
  CurrentGameNotifier([this._initial]);

  final Game? _initial;

  @override
  Game? build() => _initial;

  void setGame(Game? game) {
    state = game;
  }

  void clear() {
    state = null;
  }
}

final currentGameProvider = NotifierProvider<CurrentGameNotifier, Game?>(
  CurrentGameNotifier.new,
);

/// True when the auto-save slot is valid. Rebuilds when [currentGameProvider] changes
/// so the main menu updates immediately after exiting to menu. SPEC/ui/main-menu.md.
final mainMenuAutoSaveAvailableProvider = Provider<bool>((ref) {
  ref.watch(currentGameProvider);
  if (!Hive.isBoxOpen(HiveBoxNames.games)) {
    return false;
  }
  final service = ref.watch(gameServiceProvider);
  return service.hasValidAutoSave();
});

/// Current-turn orders for the human player (work orders, move orders, etc.).
/// Updated when the player assigns/cancels work in the civilian panel; passed to nextTurn and reset after resolution.
class CurrentOrdersNotifier extends Notifier<Orders> {
  CurrentOrdersNotifier([this._initial = const Orders()]);

  final Orders _initial;

  @override
  Orders build() => _initial;

  void replaceAll(Orders next) {
    state = next;
  }

  void clear() {
    state = const Orders();
  }
}

final currentOrdersProvider = NotifierProvider<CurrentOrdersNotifier, Orders>(
  CurrentOrdersNotifier.new,
);

/// Set of game ids for which the game-start intro dialogue has been shown.
/// SPEC/ai/dialogue-management.md § First dialogue emission point.
class GameIdsWithIntroShownNotifier extends Notifier<Set<String>> {
  GameIdsWithIntroShownNotifier([this._initial = const <String>{}]);

  final Set<String> _initial;

  @override
  Set<String> build() => _initial;

  void markShown(String gameId) {
    state = {...state, gameId};
  }
}

final gameIdsWithIntroShownProvider =
    NotifierProvider<GameIdsWithIntroShownNotifier, Set<String>>(
      GameIdsWithIntroShownNotifier.new,
    );
