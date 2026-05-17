import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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
      expect(
        snap.conquest.invadableProvinceIdsSorted,
        isNotEmpty,
        reason: '$gpId invadable=${snap.conquest.invadableProvinceIdsSorted} '
            'adjacentOwners=${snap.conquest.adjacentOwnerFactionIdsSorted}',
      );
      expect(
        invadableOwners.any((o) => o.startsWith('minor')),
        isTrue,
        reason: '$gpId invadable owners=$invadableOwners',
      );
    }
  });
}
