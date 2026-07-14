// Pure-function tests for DiplomacyPanel row building and power-comparison
// helpers, split out of diplomacy_panel_test.dart to keep each test file at or
// below the repo dart_file_non_comment_line_size gate. SPEC/ui/diplomacy-panel.md.
// Shared tables densify residual mid-500 cases (Refs #4021).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';

import 'support/panel_test_fixtures.dart';

/// Old World coastal province sea-connected to an unrevealed New World tribe
/// colony, with **zero** New World tile visibility (Refs #3620 AC-1). Mirrors
/// the colonial-intel fixture used in the diplomacy package tests.
const _seaReachableTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'oldWorld|home',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|owSea',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|nwSea',
      regionId: 'newWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|colony',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [
    TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
    TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nwSea'),
    TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colony'),
  ],
);

Game _tribeFixture({
  required String id,
  required int turnNumber,
  required Map<String, Map<String, String>> playerVisibilityByTile,
  List<DiplomacyRelation> diplomacyRelations = const [],
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(id: 'newWorld|colony', regionId: 'newWorld', ownerId: 't1'),
        ],
      ),
      playerVisibilityByTile: playerVisibilityByTile,
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          'oldWorld|home': ['oldWorld|home|0|0'],
        },
        'newWorld': {
          'newWorld|colony': ['newWorld|colony|0|0'],
        },
      },
    ),
    players: const [Player(id: 'gp1', displayName: 'Solo', isHuman: true)],
    tribes: const [Tribe(id: 't1', displayName: 'Tribe One')],
    diplomacyRelations: diplomacyRelations,
  );
}

/// Turn-0 fixture where Tribe `t1` owns a New-World province that is
/// sea-reachable from the human GP's Old-World anchor, but the GP has **no**
/// non-`unknown` New-World tile visibility and **no** GP↔Tribe relation
/// (Refs #3620 AC-1). The tribe must not be surfaced in the Tribes section.
Game _gameWithSeaReachableTribeNoContact() => _tribeFixture(
  id: 'sea-reachable-no-contact',
  turnNumber: 0,
  playerVisibilityByTile: const {
    'gp1': {'oldWorld|home|0|0': 'fullyVisible'},
  },
);

/// Fixture for the contact-survives-fog-decay AC (Refs #3620 AC-7): the human
/// GP holds a persisted GP↔Tribe relation with `t1` but currently has **no**
/// non-`unknown` tile visibility into any province `t1` owns.
Game _gameWithTribeRelationButNoVisibility() => _tribeFixture(
  id: 'tribe-relation-fog-decay',
  turnNumber: 7,
  playerVisibilityByTile: const {},
  diplomacyRelations: const [
    DiplomacyRelation(
      factionId1: 'gp1',
      factionId2: 't1',
      state: RelationState.atPeace,
      score: 50,
      sinceTurn: 4,
      lastInteractionTurn: 4,
    ),
  ],
);

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
      final game = _gameWithSeaReachableTribeNoContact();
      final view = buildPlayerView(game, _seaReachableTopology, 'gp1');
      // The shared first-contact gate now lives in the helper itself, so the
      // sea-reachable tribe is excluded at the source (#3620).
      expect(
        knownDiplomaticTargetFactionIds(
          view: view,
          game: game,
          topology: _seaReachableTopology,
        ),
        isNot(contains('t1')),
      );

      final rows = buildDiplomacyRows(
        game,
        _seaReachableTopology,
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
          _gameWithTribeRelationButNoVisibility(),
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

  group('powerComparisonPercent', () {
    for (final c in <({String name, int gp, int player, int want})>[
      (
        name: 'GP stronger than player produces positive percentage',
        gp: 110,
        player: 100,
        want: 10,
      ),
      (
        name: 'GP weaker than player produces negative percentage',
        gp: 78,
        player: 100,
        want: -22,
      ),
      (
        name: 'equal scores produce zero percentage',
        gp: 100,
        player: 100,
        want: 0,
      ),
      (
        name: 'rounding uses banker-agnostic round() (positive mid)',
        gp: 105,
        player: 100,
        want: 5,
      ),
      (
        name: 'rounding uses banker-agnostic round() (positive high)',
        gp: 114,
        player: 100,
        want: 14,
      ),
      (
        name: 'zero playerPowerScore uses max(playerScore, 1) guard',
        gp: 50,
        player: 0,
        want: 5000,
      ),
      (name: 'zero/zero is finite 0% (no NaN)', gp: 0, player: 0, want: 0),
      (
        name: 'negative playerPowerScore is still guarded by max(.., 1)',
        gp: 50,
        player: -10,
        want: 6000,
      ),
    ]) {
      test(c.name, () {
        expect(powerComparisonPercent(c.gp, c.player), c.want);
      });
    }
  });

  group('formatPowerComparisonPercent', () {
    for (final c in <(int, String)>[
      (10, '+10%'),
      (1, '+1%'),
      (-22, '\u221222%'),
      (-1, '\u22121%'),
      (0, '0%'),
    ]) {
      test('formats ${c.$1} as ${c.$2}', () {
        expect(formatPowerComparisonPercent(c.$1), c.$2);
      });
    }

    test('negative percentage uses unicode minus sign (U+2212)', () {
      expect(formatPowerComparisonPercent(-22).startsWith('\u2212'), isTrue);
      expect(formatPowerComparisonPercent(-22).startsWith('-'), isFalse);
    });
  });

  group('powerComparisonTier (SPEC § Relative power line boundary table)', () {
    for (final c in <(int, PowerComparisonTier)>[
      (0, PowerComparisonTier.roughlyEqual),
      (10, PowerComparisonTier.roughlyEqual),
      (-10, PowerComparisonTier.roughlyEqual),
      (5, PowerComparisonTier.roughlyEqual),
      (-7, PowerComparisonTier.roughlyEqual),
      (11, PowerComparisonTier.superior),
      (30, PowerComparisonTier.superior),
      (22, PowerComparisonTier.superior),
      (31, PowerComparisonTier.vastlySuperior),
      (100, PowerComparisonTier.vastlySuperior),
      (4900, PowerComparisonTier.vastlySuperior),
      (-11, PowerComparisonTier.inferior),
      (-30, PowerComparisonTier.inferior),
      (-22, PowerComparisonTier.inferior),
      (-31, PowerComparisonTier.vastlyInferior),
      (-90, PowerComparisonTier.vastlyInferior),
    ]) {
      test('${c.$1} → ${c.$2}', () {
        expect(powerComparisonTier(c.$1), c.$2);
      });
    }
  });

  group('diplomacyFilterShowsKind', () {
    test('mode `all` shows every faction kind', () {
      for (final kind in FactionKind.values) {
        expect(
          diplomacyFilterShowsKind(DiplomacyFilterMode.all, kind),
          isTrue,
          reason: 'DiplomacyFilterMode.all must accept $kind',
        );
      }
    });

    for (final c
        in <
          ({String name, DiplomacyFilterMode mode, FactionKind kind, bool want})
        >[
          (
            name: 'greatPowersOnly shows Great Power',
            mode: DiplomacyFilterMode.greatPowersOnly,
            kind: FactionKind.greatPower,
            want: true,
          ),
          (
            name: 'greatPowersOnly hides Minor',
            mode: DiplomacyFilterMode.greatPowersOnly,
            kind: FactionKind.minor,
            want: false,
          ),
          (
            name: 'greatPowersOnly hides Tribe',
            mode: DiplomacyFilterMode.greatPowersOnly,
            kind: FactionKind.tribe,
            want: false,
          ),
          (
            name: 'minorsOnly shows Minor',
            mode: DiplomacyFilterMode.minorsOnly,
            kind: FactionKind.minor,
            want: true,
          ),
          (
            name: 'minorsOnly shows Tribe',
            mode: DiplomacyFilterMode.minorsOnly,
            kind: FactionKind.tribe,
            want: true,
          ),
          (
            name: 'minorsOnly hides Great Power',
            mode: DiplomacyFilterMode.minorsOnly,
            kind: FactionKind.greatPower,
            want: false,
          ),
        ]) {
      test(c.name, () {
        expect(diplomacyFilterShowsKind(c.mode, c.kind), c.want);
      });
    }
  });
}
