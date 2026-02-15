import 'package:flame/game.dart';

/// Empty Flame game. Phase 0: no components or game logic.
/// TDD 15: Flame owns terrain map, battle map, HUD; this is the host.
class ColonizeThisGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // No components in Phase 0.
  }
}
