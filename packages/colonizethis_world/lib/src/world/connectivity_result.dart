/// Result of connectivity resolution: connected tile set and per-tile path transport cap.
/// SPEC/game/capital-and-connectivity, extraction-and-improvements: effective yield is
/// capped by min transport level along path to town then to capital; [pathTransportCap]
/// is that cap (max over paths of min road level on path).
///
/// [connectedByRoadRule] is the tile set before § Town rule expansion (Road rule + sea
/// port wiring per resolver). Used for extraction town-development caps.
///
/// Declared in its own library (extracted from `connectivity_resolver.dart`,
/// Refs #3544 Step 3) so the standalone `connectivity_propagation.dart` core can
/// construct results without importing the resolver, keeping the world `lib/`
/// import graph acyclic.
class ConnectivityResult {
  const ConnectivityResult({
    required this.connected,
    this.pathTransportCap = const {},
    this.connectedByRoadRule = const {},
  });

  final Set<String> connected;
  final Map<String, int> pathTransportCap;

  /// Tiles reachable under Road rule + overseas/port phases **before** 4-adjacent town closure.
  final Set<String> connectedByRoadRule;
}
