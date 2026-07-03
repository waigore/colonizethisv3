import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'init_game_orchestrator_test_support.dart';

/// S4b (Refs #3753 R4a): under the locked full-init profile every Tribe must own
/// at least one sea-bound (P–S) New World province so every Tribe is discoverable
/// by fleet entry. Seeds 257, 2003, and 15013 previously produced a Tribe with no
/// sea-bound province; with the sea-bound ownership gate + regen-until-pass they
/// now resolve to a layout where every Tribe owns a sea-bound province.
void main() {
  group('locked full-init tribe sea-bound ownership (#3753 S4b)', () {
    // Includes the three seeds that violated the property before the gate, plus
    // the fixture seed (42) and the AC-12 determinism seed (17011) which already
    // satisfied it (so the gate must not perturb their output).
    const seeds = <int>[257, 2003, 15013, 42, 17011];

    for (final s in seeds) {
      test('seed=$s: every tribe owns at least one sea-bound NW province', () {
        final config = lockedFullInitConfig(seed: s);
        final result = runInitGame(config: config, options: defaultInitOptions);
        final topoNw = result.topologyByRegion[kRegionNewWorld]!;
        final game = result.game;

        final seaBoundByLocalId = <String, bool>{
          for (final p in game.worldState.newWorld.provinces)
            ProvinceId.localIdFrom(p.id): isProvinceSeaBound(
              topoNw,
              ProvinceId.localIdFrom(p.id),
            ),
        };

        final tribeOwnsSeaBound = <String, bool>{};
        for (final p in game.worldState.newWorld.provinces) {
          final ownerId = p.ownerId;
          if (ownerId == null || !ownerId.startsWith('tribe')) continue;
          final localId = ProvinceId.localIdFrom(p.id);
          tribeOwnsSeaBound[ownerId] =
              (tribeOwnsSeaBound[ownerId] ?? false) ||
              (seaBoundByLocalId[localId] ?? false);
        }

        expect(tribeOwnsSeaBound, isNotEmpty, reason: 'seed=$s has tribes');
        for (final entry in tribeOwnsSeaBound.entries) {
          expect(
            entry.value,
            isTrue,
            reason: 'seed=$s tribe ${entry.key} owns no sea-bound province',
          );
        }
      });
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
