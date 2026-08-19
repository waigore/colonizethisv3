import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

/// Diagnostic: default observer seed 42 must give every GP adjacent minor targets.
void main() {
  test('seed 42 init: each GP has invadable Old World provinces at turn 1', () {
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
    var gpsWithMinorTarget = 0;
    for (var i = 1; i <= 6; i++) {
      final gpId = 'gp$i';
      final view = buildPlayerView(game, topology, gpId);
      final snap = AIWorldSnapshot.fromPlayerView(view, topology: topology);
      final invadableOwners = <String>{
        for (final provinceId in snap.conquest.invadableProvinceIdsSorted)
          game.worldState.oldWorld.provinces
              .firstWhere((p) => p.id == provinceId)
              .ownerId ??
              '',
      }..remove('');
      // Anti-degenerate start: every GP must have at least one invadable Old
      // World province at turn 1 (no GP boxed in with zero conquest targets).
      expect(
        snap.conquest.invadableProvinceIdsSorted,
        isNotEmpty,
        reason: '$gpId invadable=${snap.conquest.invadableProvinceIdsSorted} '
            'adjacentOwners=${snap.conquest.adjacentOwnerFactionIdsSorted}',
      );
      if (invadableOwners.any((o) => o.startsWith('minor'))) {
        gpsWithMinorTarget++;
      }
    }
    // After the #3573 forest terrain redistribution (R6: plains up, forest
    // halved/split), the seed-42 world places gp6 adjacent only to gp5
    // (another great power) rather than a minor; the other five GPs still
    // border an invadable minor at turn 1. Re-baseline this floor whenever
    // terrain distribution weights or province placement change intentionally.
    expect(
      gpsWithMinorTarget,
      greaterThanOrEqualTo(5),
      reason: 'gpsWithMinorTarget=$gpsWithMinorTarget (expected >= 5 of 6 GPs '
          'to border an invadable minor on seed 42)',
    );
  });
}
