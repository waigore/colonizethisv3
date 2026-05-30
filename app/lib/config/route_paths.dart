/// Route path strings only (no screen/widget imports).
/// Keeps lightweight tests from importing [Routes], which pulls the full app graph.
abstract final class RoutePaths {
  RoutePaths._();

  static const String shell = '/';
  static const String game = '/game';
  static const String debugLog = '/debug-log';
  static const String production = '/game/production';
  static const String diplomacy = '/game/diplomacy';
  static const String diplomacyDetail = '/game/diplomacy/detail';
  static const String technology = '/game/technology';
  static const String trade = '/game/trade';
}
