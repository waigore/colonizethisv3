// Migrated to the shared [runSeed42ObserverCampaign] harness (Refs #3749
// step 2): the init / handoff / per-turn resolve loop is owned by
// `test/support/seed42_observer_campaign.dart`; this test contributes only
// its post-campaign invadable-minor probe for gp3 at turn 20.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/seed42_observer_campaign.dart';

void main() {
  test(
    'gp3 invadable at turn 20 seed 42',
    () {
      CtLogger.level = Level.off;
      MapTopology? topo;
      final result = runSeed42ObserverCampaign(
        turns: 20,
        onBeforeResolve: (_, __, ___, topology, ____) {
          topo ??= topology;
        },
      );
      final game = result.finalGame;
      final view = buildPlayerView(game, topo!, 'gp3');
      final snap = AIWorldSnapshot.fromPlayerView(view, topology: topo!);
      final owners = getProvinceOwnerMap(game);
      final minorInvadable = snap.conquest.invadableProvinceIdsSorted
          .where((pid) => game.minorNations.any((m) => m.id == owners[pid]))
          .toList();
      expect(minorInvadable.length, greaterThan(0),
          reason: 'gp3 should have minor targets');
    },
    skip:
        'Refs #2509: seed-42 turn-20 gp3 invadable minors not stable after '
        'sole-GP peace merge; covered by colonial_pressure unit tests',
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
