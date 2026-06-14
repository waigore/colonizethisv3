import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';

/// Resolves capital province ids for a fully-AI observer setup + seed.
///
/// Verifies the GA full-assignment invariant (every topology province owned by a
/// non-empty faction) before returning, so a malformed world fails loudly with
/// [SetupTopologyDataException] code `unassigned_provinces` instead of being
/// scored. SPEC/program/ga-setup-profile.md § Full-assignment verification.
Map<String, String> resolveCapitalProvinces(GameSetupConfig config) {
  final init = runInitGame(
    config: config,
    options: const InitGameOptions(
      cellSize: 24,
      renderPng: false,
      skipFillLakes: false,
    ),
  );
  verifyFullProvinceAssignment(
    worldState: init.game.worldState,
    topologyByRegion: init.topologyByRegion,
  );
  final capitals = <String, String>{};
  for (final player in init.game.players) {
    final cap = player.capitalProvinceId;
    if (cap != null && cap.isNotEmpty) {
      capitals[player.id] = cap;
    }
  }
  return capitals;
}
