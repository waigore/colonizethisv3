import 'game_service.dart' show GameMapData;

/// Best-effort [GameService.getMapData] for Flutter hosts that may mount
/// without Hive-backed persistence (widget / golden tests).
///
/// Shared by province-detail overlay hosts and feature screens (diplomacy,
/// production) that previously each swallowed the same load throw.
/// Refs #4035 AC3.
GameMapData? tryGetGameMapData(GameMapData? Function() load) {
  try {
    return load();
  } catch (_) {
    return null;
  }
}
