// Pure-function tests for DiplomacyPanel row building and power-comparison
// helpers, split out of diplomacy_panel_test.dart to keep each test file at or
// below the repo dart_file_non_comment_line_size gate. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';

import 'support/panel_test_fixtures.dart';

Game _gameWithNoDiscoveredFactions() {
  const ow = 'oldWorld';
  final p1 = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'P1',
    ownerId: 'gp1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: [p1], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  const player = Player(id: 'gp1', displayName: 'Solo', isHuman: true);
  return Game(
    id: 'empty-diplo',
    worldState: world,
    players: const [player],
    diplomacyRelations: const [],
  );
}

/// Fixture for the discovery-via-visibility ACs (Refs #3341): the human GP
/// `gp1` has fully-visible tile sight into a New-World province owned by Tribe
/// `t1` but holds **no** `DiplomacyRelation` with the tribe. Per
/// SPEC/ui/diplomacy-panel.md § Discovered factions, the panel must discover
/// the tribe via `knownDiplomaticTargetFactionIds` and surface the default
/// neutral first-contact standing.
Game _gameWithTribeDiscoveredByVisibility() {
  const nw = 'newWorld';
  const ow = 'oldWorld';
  final tribeProvince = Province(
    id: '$nw|t1prov',
    regionId: nw,
    displayName: 'Tribe Land',
    ownerId: 't1',
  );
  final homeProvince = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'Home',
    ownerId: 'gp1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
    oldWorld: RegionData(provinces: [homeProvince], units: const []),
    newWorld: RegionData(provinces: [tribeProvince], units: const []),
    playerVisibilityByTile: const {
      'gp1': {'newWorld|t1prov|0|0': 'fullyVisible'},
    },
    playerProspectedTiles: const {},
  );
  const player = Player(id: 'gp1', displayName: 'Solo', isHuman: true);
  return Game(
    id: 'tribe-visibility',
    worldState: world,
    players: const [player],
    tribes: const [Tribe(id: 't1', displayName: 'Tribe One')],
    diplomacyRelations: const [],
  );
}

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

/// Turn-0 fixture where Tribe `t1` owns a New-World province that is
/// sea-reachable from the human GP's Old-World anchor, but the GP has **no**
/// non-`unknown` New-World tile visibility and **no** GP↔Tribe relation
/// (Refs #3620 AC-1). The tribe must not be surfaced in the Tribes section.
Game _gameWithSeaReachableTribeNoContact() {
  return const Game(
    id: 'sea-reachable-no-contact',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          Province(
            id: 'newWorld|colony',
            regionId: 'newWorld',
            ownerId: 't1',
          ),
        ],
      ),
      playerVisibilityByTile: {
        'gp1': {'oldWorld|home|0|0': 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          'oldWorld|home': ['oldWorld|home|0|0'],
        },
        'newWorld': {
          'newWorld|colony': ['newWorld|colony|0|0'],
        },
      },
    ),
    players: [Player(id: 'gp1', displayName: 'Solo', isHuman: true)],
    tribes: [Tribe(id: 't1', displayName: 'Tribe One')],
    diplomacyRelations: [],
  );
}

/// Fixture for the contact-survives-fog-decay AC (Refs #3620 AC-7): the human
/// GP holds a persisted GP↔Tribe relation with `t1` but currently has **no**
/// non-`unknown` tile visibility into any province `t1` owns.
Game _gameWithTribeRelationButNoVisibility() {
  return const Game(
    id: 'tribe-relation-fog-decay',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 7),
      oldWorld: RegionData(
        provinces: [
          Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          Province(
            id: 'newWorld|colony',
            regionId: 'newWorld',
            ownerId: 't1',
          ),
        ],
      ),
      playerVisibilityByTile: {},
    ),
    players: [Player(id: 'gp1', displayName: 'Solo', isHuman: true)],
    tribes: [Tribe(id: 't1', displayName: 'Tribe One')],
    diplomacyRelations: [
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
}

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
    gameWithNoDiscovered = _gameWithNoDiscoveredFactions();
  });

  group('buildDiplomacyRows', () {
    test(
      'display mapping aligned with SPEC (relationScoreToDisplayLabel bands)',
      () {
        expect(relationScoreToDisplayLabel(0), 'Hostile');
        expect(relationScoreToDisplayLabel(29), 'Hostile');
        expect(relationScoreToDisplayLabel(30), 'Unfriendly');
        expect(relationScoreToDisplayLabel(49), 'Unfriendly');
        expect(relationScoreToDisplayLabel(50), 'Cordial');
        expect(relationScoreToDisplayLabel(69), 'Cordial');
        expect(relationScoreToDisplayLabel(70), 'Friendly');
        expect(relationScoreToDisplayLabel(100), 'Friendly');
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
          _gameWithTribeDiscoveredByVisibility(),
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

    test(
      'AC-1 (#3620): turn-0 sea-reachable tribe with no contact yields no '
      'tribe rows and is absent from knownDiplomaticTargetFactionIds',
      () {
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
      },
    );

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

    test('AC-6: minor row enumerates all overture stages with disabled reasons', () {
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
    });

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
    test('GP stronger than player produces positive percentage', () {
      expect(powerComparisonPercent(110, 100), 10);
    });

    test('GP weaker than player produces negative percentage', () {
      expect(powerComparisonPercent(78, 100), -22);
    });

    test('equal scores produce zero percentage', () {
      expect(powerComparisonPercent(100, 100), 0);
    });

    test('rounding uses banker-agnostic round() (positive)', () {
      // (105 - 100) / 100 = 0.05 → +5
      expect(powerComparisonPercent(105, 100), 5);
      // (114 - 100) / 100 = 0.14 → +14
      expect(powerComparisonPercent(114, 100), 14);
    });

    test('zero playerPowerScore uses max(playerScore, 1) guard', () {
      // With denominator clamped to 1, (50 - 0) / 1 = 50 → +5000%
      expect(powerComparisonPercent(50, 0), 5000);
      // (0 - 0) / max(0, 1) = 0 → 0%, finite (no NaN, no division-by-zero)
      expect(powerComparisonPercent(0, 0), 0);
    });

    test('negative playerPowerScore is still guarded by max(.., 1)', () {
      // The SPEC formula uses `max(playerPowerScore, 1)`; a defensive call
      // with a negative `playerPowerScore` must not produce a sign flip via a
      // negative denominator. Result must be a finite integer using `1` as
      // the effective denominator.
      expect(powerComparisonPercent(50, -10), 6000);
    });
  });

  group('formatPowerComparisonPercent', () {
    test('positive percentage uses ASCII plus and percent suffix', () {
      expect(formatPowerComparisonPercent(10), '+10%');
      expect(formatPowerComparisonPercent(1), '+1%');
    });

    test('negative percentage uses unicode minus sign (U+2212)', () {
      // U+2212 MINUS SIGN, not U+002D HYPHEN-MINUS.
      expect(formatPowerComparisonPercent(-22), '\u221222%');
      expect(formatPowerComparisonPercent(-1), '\u22121%');
      expect(formatPowerComparisonPercent(-22).startsWith('\u2212'), isTrue);
      expect(formatPowerComparisonPercent(-22).startsWith('-'), isFalse);
    });

    test('zero percentage formats as "0%" without sign', () {
      expect(formatPowerComparisonPercent(0), '0%');
    });
  });

  group('powerComparisonTier (SPEC § Relative power line boundary table)', () {
    test('roughly-equal band: −10 … +10 inclusive (and 0)', () {
      expect(powerComparisonTier(0), PowerComparisonTier.roughlyEqual);
      expect(powerComparisonTier(10), PowerComparisonTier.roughlyEqual);
      expect(powerComparisonTier(-10), PowerComparisonTier.roughlyEqual);
      expect(powerComparisonTier(5), PowerComparisonTier.roughlyEqual);
      expect(powerComparisonTier(-7), PowerComparisonTier.roughlyEqual);
    });

    test('superior band: +11 … +30 inclusive', () {
      expect(powerComparisonTier(11), PowerComparisonTier.superior);
      expect(powerComparisonTier(30), PowerComparisonTier.superior);
      expect(powerComparisonTier(22), PowerComparisonTier.superior);
    });

    test('vastly-superior band: ≥ +31 (no cap)', () {
      expect(powerComparisonTier(31), PowerComparisonTier.vastlySuperior);
      expect(powerComparisonTier(100), PowerComparisonTier.vastlySuperior);
      expect(powerComparisonTier(4900), PowerComparisonTier.vastlySuperior);
    });

    test('inferior band: −30 … −11 inclusive', () {
      expect(powerComparisonTier(-11), PowerComparisonTier.inferior);
      expect(powerComparisonTier(-30), PowerComparisonTier.inferior);
      expect(powerComparisonTier(-22), PowerComparisonTier.inferior);
    });

    test('vastly-inferior band: ≤ −31', () {
      expect(powerComparisonTier(-31), PowerComparisonTier.vastlyInferior);
      expect(powerComparisonTier(-90), PowerComparisonTier.vastlyInferior);
    });

    test('exact boundary integers map per the confirmed table', () {
      expect(powerComparisonTier(10), PowerComparisonTier.roughlyEqual);
      expect(powerComparisonTier(11), PowerComparisonTier.superior);
      expect(powerComparisonTier(30), PowerComparisonTier.superior);
      expect(powerComparisonTier(31), PowerComparisonTier.vastlySuperior);
      expect(powerComparisonTier(-10), PowerComparisonTier.roughlyEqual);
      expect(powerComparisonTier(-11), PowerComparisonTier.inferior);
      expect(powerComparisonTier(-30), PowerComparisonTier.inferior);
      expect(powerComparisonTier(-31), PowerComparisonTier.vastlyInferior);
    });
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

    test('mode `greatPowersOnly` shows only Great Power rows', () {
      expect(
        diplomacyFilterShowsKind(
          DiplomacyFilterMode.greatPowersOnly,
          FactionKind.greatPower,
        ),
        isTrue,
      );
      expect(
        diplomacyFilterShowsKind(
          DiplomacyFilterMode.greatPowersOnly,
          FactionKind.minor,
        ),
        isFalse,
      );
      expect(
        diplomacyFilterShowsKind(
          DiplomacyFilterMode.greatPowersOnly,
          FactionKind.tribe,
        ),
        isFalse,
      );
    });

    test(
      'mode `minorsOnly` shows Minor Nations and Tribes but not Great Powers',
      () {
        expect(
          diplomacyFilterShowsKind(
            DiplomacyFilterMode.minorsOnly,
            FactionKind.minor,
          ),
          isTrue,
        );
        expect(
          diplomacyFilterShowsKind(
            DiplomacyFilterMode.minorsOnly,
            FactionKind.tribe,
          ),
          isTrue,
        );
        expect(
          diplomacyFilterShowsKind(
            DiplomacyFilterMode.minorsOnly,
            FactionKind.greatPower,
          ),
          isFalse,
        );
      },
    );
  });
}
