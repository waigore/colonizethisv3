import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('seed 42 init: each GP has sea-reachable NW invadable provinces', () {
    final base = GameSetupConfig.defaultConfig;
    final init = runInitGame(
      config: GameSetupConfig(
        selectedGreatPowerIds: base.selectedGreatPowerIds,
        leaderVariantByGpId: base.leaderVariantByGpId,
        continentCount: base.continentCount,
        minorNationCount: base.minorNationCount,
        tribeCount: base.tribeCount,
        numProvincesOldWorld: base.numProvincesOldWorld,
        numProvincesNewWorld: base.numProvincesNewWorld,
        minProvincesPerMinor: base.minProvincesPerMinor,
        seed: 42,
      ),
      options: const InitGameOptions(
        cellSize: 24,
        renderPng: false,
        skipFillLakes: false,
      ),
    );
    final topology = init.combinedTopology;
    final game = init.game;
    for (var i = 1; i <= 6; i++) {
      final gpId = 'gp$i';
      final view = buildPlayerView(game, topology, gpId);
      final snap = AIWorldSnapshot.fromPlayerView(view, topology: topology);
      expect(
        snap.colonial.invadableNewWorldProvinceIdsSorted,
        isNotEmpty,
        reason: '$gpId nwInvadable=${snap.colonial.invadableNewWorldProvinceIdsSorted}',
      );
    }
  });
}
