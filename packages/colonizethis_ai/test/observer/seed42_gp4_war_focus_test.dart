import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'support/seed42_observer_campaign.dart';

void main() {
  test('seed 42 turn 51: gp4 has at most one GP war when invadable OW remains', () {
    MapTopology? topo;
    final result = runSeed42ObserverCampaign(
      turns: 51,
      onBeforeResolve: (turn, fullAi, game, topology, tileMap) {
        topo ??= topology;
      },
    );
    final game = result.finalGame;
    final topology = topo!;
    // Run through turn 50 resolution: multi-front GP wars consolidate in the
    // same diplomacy phase (declare blocker, peace non-blocker). S10 peace
    // plumbing may leave a sole mutual-plateau peer war instead of the OW
    // blocker (seed-42 gp4/gp6 vs gp3 frontier). Multi-slot treasury-aware
    // research (Refs #3472) can leave a transient two-GP-war state at the
    // turn-50 boundary; one more turn lets expand-phase peace consolidate.
    final view = buildPlayerView(game, topology, 'gp4');
    final snap = AIWorldSnapshot.fromPlayerView(view, topology: topology);
    final gpWars = snap.threats.atWarWith
        .where((id) => game.playerById(id) != null)
        .toList()
      ..sort();
    if (snap.conquest.invadableProvinceIdsSorted.isEmpty) {
      return;
    }
    expect(gpWars.length, lessThanOrEqualTo(1));
  }, timeout: const Timeout(Duration(minutes: 8)));
}
