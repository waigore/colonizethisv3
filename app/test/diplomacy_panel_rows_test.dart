// Pure-function tests for DiplomacyPanel row building and power-comparison
// helpers, split out of diplomacy_panel_test.dart to keep each test file at or
// below the repo dart_file_non_comment_line_size gate. SPEC/ui/diplomacy-panel.md.
// Shared tables densify residual mid-500 cases (Refs #4021 / #4305).

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

  late Game gameWithFactions;
  late Game gameWithNoDiscovered;
  late String humanPlayerId;
  late MapTopology topology;

  setUpAll(() async {
    // Refs #3656: lightweight discovered-faction fixture replaces the ~7-11s
    // getDebugInitGameResult() map generation. It seeds three GPs (sortable by
    // military strength), a Minor Nation with the full overture matrix, and a
    // Tribe — all discovered via persisted DiplomacyRelations — which is the
    // full shape these GP-sort / minor-overture / GP-action assertions read.
    // No generated map/topology data is consumed.
    gameWithFactions = buildDiplomacyRichPanelTestGame();
    topology = const MapTopology();
    humanPlayerId = gameWithFactions.players.isNotEmpty
        ? gameWithFactions.players.first.id
        : 'gp1';
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
        expect(
          tribeRows,
          hasLength(1),
          reason:
              'Tribe owning a visible province must be discovered even '
              'without a game-setup DiplomacyRelation (SPEC § Discovered '
              'factions).',
        );
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
      // The shared first-contact gate now lives in the helper itself, so the
      // sea-reachable tribe is excluded at the source (#3620).
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
        reason:
            'Sea-reachable colonial intel alone must not surface a Tribe row '
            '(SPEC § Tribes require first contact).',
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

    test('returns GP rows sorted by military power then province count', () {
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final gpRows = rows
          .where((r) => r.kind == FactionKind.greatPower)
          .toList();
      if (gpRows.length < 2) return;
      for (var i = 0; i < gpRows.length - 1; i++) {
        final strA = aggregateMilitaryStrengthForPlayer(
          gameWithFactions,
          gpRows[i].factionId,
        );
        final strB = aggregateMilitaryStrengthForPlayer(
          gameWithFactions,
          gpRows[i + 1].factionId,
        );
        expect(strA >= strB, isTrue);
      }
    });

    test('GP rows have power score and player power score set', () {
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final gpRows = rows
          .where((r) => r.kind == FactionKind.greatPower)
          .toList();
      for (final r in gpRows) {
        expect(r.powerScore, isNotNull, reason: 'GP row ${r.displayName}');
        expect(
          r.playerPowerScore,
          isNotNull,
          reason: 'GP row ${r.displayName}',
        );
      }
      final nonGp = rows.where((r) => r.kind != FactionKind.greatPower);
      for (final r in nonGp) {
        expect(r.powerScore, isNull);
        expect(r.playerPowerScore, isNull);
      }
    });

    test(
      'AC-6: minor row enumerates all overture stages with disabled reasons',
      () {
        final minorId = gameWithFactions.minorNations.first.id;
        final rows = buildDiplomacyRows(
          gameWithFactions,
          topology,
          humanPlayerId,
          const Orders(),
        );
        final minorRow = rows.firstWhere((r) => r.factionId == minorId);
        final overtureActions = minorRow.actions
            .where((a) => a.order.type == DiplomaticOrderType.establishOverture)
            .toList();
        expect(overtureActions, hasLength(4));
        final disabled = overtureActions.where((a) => !a.enabled).toList();
        expect(disabled, isNotEmpty);
        for (final action in disabled) {
          expect(action.rejectionReason, isNotNull);
          expect(action.rejectionReason, isNotEmpty);
        }
      },
    );

    test('AC-10: GP row keeps invalid Offer Peace action in matrix', () {
      final otherGp = gameWithFactions.players.firstWhere(
        (p) => p.id != humanPlayerId,
      );
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final gpRow = rows.firstWhere((r) => r.factionId == otherGp.id);
      final offerPeace = gpRow.actions.firstWhere(
        (a) => a.order.type == DiplomaticOrderType.offerPeace,
      );
      expect(offerPeace.enabled, isFalse);
      expect(offerPeace.rejectionReason, isNotEmpty);
      final ftp = gpRow.actions.firstWhere(
        (a) => a.order.type == DiplomaticOrderType.establishFtp,
      );
      expect(ftp.enabled, isFalse);
    });

    test('pendingOrderTypes reflects submitted diplomatic orders', () {
      final otherGp = gameWithFactions.players.firstWhere(
        (p) => p.id != humanPlayerId,
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          humanPlayerId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: otherGp.id,
            ),
          ],
        },
      );
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        orders,
      );
      final targetRow = rows.firstWhere((r) => r.factionId == otherGp.id);
      expect(
        targetRow.pendingOrderTypes,
        contains(DiplomaticOrderType.declareWar),
      );
    });
  });
}
