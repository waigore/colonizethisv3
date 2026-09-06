// Pure-function tests for DiplomacyPanel row building (Refs #4021 / #4305).
// Rich-panel pins: diplomacy_panel_rows_discovered_test.dart.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';

import 'diplomacy_panel_rows_test_fixtures.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game gameWithNoDiscovered;

  setUpAll(() async {
    gameWithNoDiscovered = buildDiplomacyPanelGameWithNoDiscoveredFactions();
  });

  group('buildDiplomacyRows', () {
    test(
      'display mapping aligned with SPEC (10-step ladder bands, Refs #3753)',
      () {
        for (final c in <(int, String)>[
          (0, 'Hostile'),
          (10, 'Antagonistic'),
          (20, 'Distrustful'),
          (30, 'Unfriendly'),
          (40, 'Wary'),
          (50, 'Neutral'),
          (60, 'Cordial'),
          (70, 'Amicable'),
          (80, 'Friendly'),
          (90, 'Devoted'),
          (100, 'Devoted'),
        ]) {
          expect(relationScoreToDisplayLabel(c.$1), c.$2);
        }
      },
    );

    test('returns empty list when player has no relations', () {
      final rows = buildDiplomacyRows(
        gameWithNoDiscovered,
        const MapTopology(nodes: [], edges: []),
        'gp1',
        const Orders(),
      );
      expect(rows, isEmpty);
    });

    test(
      'AC (Refs #3341): discovers a tribe via tile visibility with no prior '
      'relation, surfacing AT_PEACE / 50 / neutral first-contact standing',
      () {
        final rows = buildDiplomacyRows(
          buildDiplomacyPanelGameWithTribeDiscoveredByVisibility(),
          const MapTopology(nodes: [], edges: []),
          'gp1',
          const Orders(),
        );
        final tribeRows = rows
            .where((r) => r.kind == FactionKind.tribe)
            .toList();
        expect(tribeRows, hasLength(1));
        final tribe = tribeRows.single;
        expect(tribe.factionId, 't1');
        expect(tribe.relation, isNotNull);
        expect(tribe.relation!.state, RelationState.atPeace);
        expect(tribe.relation!.score, 50);
        expect(tribe.relation!.level, RelationLevel.neutral);
      },
    );

    test('AC-1 (#3620): turn-0 sea-reachable tribe with no contact yields no '
        'tribe rows and is absent from knownDiplomaticTargetFactionIds', () {
      final game = diplomacyPanelRowsSeaReachableTribeNoContact();
      final view = buildPlayerView(
        game,
        diplomacyPanelRowsSeaReachableTopology,
        'gp1',
      );
      expect(
        knownDiplomaticTargetFactionIds(
          view: view,
          game: game,
          topology: diplomacyPanelRowsSeaReachableTopology,
        ),
        isNot(contains('t1')),
      );

      final rows = buildDiplomacyRows(
        game,
        diplomacyPanelRowsSeaReachableTopology,
        'gp1',
        const Orders(),
      );
      expect(
        rows.where((r) => r.kind == FactionKind.tribe),
        isEmpty,
      );
    });

    test(
      'AC-7 (#3620): tribe with persisted relation but no current visibility '
      'still surfaces a tribe row (contact survives fog decay)',
      () {
        final rows = buildDiplomacyRows(
          diplomacyPanelRowsTribeRelationButNoVisibility(),
          const MapTopology(nodes: [], edges: []),
          'gp1',
          const Orders(),
        );
        final tribeRows = rows
            .where((r) => r.kind == FactionKind.tribe)
            .toList();
        expect(tribeRows, hasLength(1));
        expect(tribeRows.single.factionId, 't1');
        expect(tribeRows.single.relation, isNotNull);
        expect(tribeRows.single.relation!.state, RelationState.atPeace);
      },
    );
  });
}
