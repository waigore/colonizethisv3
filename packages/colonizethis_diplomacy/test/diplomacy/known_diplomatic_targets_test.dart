import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

/// Coverage for `knownDiplomaticTargetFactionIds` in `known_diplomatic_targets.dart`
/// (Refs #3290 test migration — per-package coverage gate for
/// `colonizethis_diplomacy`).
const _topology = MapTopology(nodes: [], edges: []);

void main() {
  suppressLogsForTests();

  group('knownDiplomaticTargetFactionIds', () {
    test('positive: relations (player as factionId2), visibility, and own '
        'units anchor surface known targets', () {
      final game = knownDiplomaticTargetsAnchoredGame();

      final view = buildPlayerView(game, _topology, 'gp1');
      final targets = knownDiplomaticTargetFactionIds(
        view: view,
        game: game,
        topology: _topology,
      );

      expect(targets, contains('minor1'));
      expect(targets, isNot(contains('gp1')));
    });

    test('negative: no relations and no visibility yields no targets', () {
      final game = knownDiplomaticTargetsIsolatedGame();

      final view = buildPlayerView(game, _topology, 'gp1');
      final targets = knownDiplomaticTargetFactionIds(
        view: view,
        game: game,
        topology: _topology,
      );

      expect(targets, isEmpty);
    });

    test(
      'negative (#3620): sea-reachable tribe with zero NW tile visibility is '
      'not a diplomatic target',
      () {
        final game = gpTribeSeaReachableNoNwVisibilityGame();
        final view = buildPlayerView(game, gpTribeSeaReachableTopology, 'gp1');
        final targets = knownDiplomaticTargetFactionIds(
          view: view,
          game: game,
          topology: gpTribeSeaReachableTopology,
        );

        expect(targets, isNot(contains('tribe1')));
      },
    );
  });
}
