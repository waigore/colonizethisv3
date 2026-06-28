// Pins the first AI / unit-integration AC from issue #2509:
//
//   Given a fixed-seed Full AI game state where a GP has embassy with a tribe
//   and treasury covers Join Empire, when diplomacy planning runs with
//   colonial-support weights active, then merged orders may include
//   `establishOverture` (Join Empire) or `declareWar` toward that tribe
//   deterministically.
//
// Pins the *candidate emission* contract at the logic suggestion API. Full AI
// diplomacy planning runs two separate suggestion passes
// (`packages/colonizethis_ai/lib/src/planning/diplomacy_planner.dart`
// `_suggestDiplomacyCandidates`):
//
//   - `suggestDeclareWarOrders` — declare-war-only pass that emits
//     `declareWar` candidates for every known at-peace target, including
//     tribes (per-target single-diplo cap does not block war).
//   - `suggestDiplomaticOrders` — non-war pass that picks one diplomatic
//     candidate per target; for an embassy-stage colonial scenario the
//     candidate is `establishOverture(joinEmpire)`.
//
// Both passes must surface the relevant candidate so the AI layer
// (`packages/colonizethis_ai`) can score and rank them. AI-side ranking is
// already pinned by:
//
//   - `packages/colonizethis_ai/test/observer_goal_phase_test.dart`
//       group `COLONIAL personality colonial acquisition` (must-have #4:
//       `napoleon` ranks `declareWar` above `establishOverture`,
//       `henry` reverses).
//   - `packages/colonizethis_ai/test/diplomatic_candidate_scoring_suppression_test.dart`
//       group `establishOverture toward tribe owning sea-reachable NW gets
//       invadable bonus` (COLONIAL phase bonus path).
//
// The candidate-set guarantee was previously implicit; this file makes it
// explicit so future tuning cannot silently drop the Join Empire candidate
// from `suggestDiplomaticOrders` or the declare-war candidate from
// `suggestDeclareWarOrders` for the embassy-stage colonial scenario.
//
// SPEC:
//   - `SPEC/ai/ai-architecture.md` § Colonial expansion (Full AI)
//   - `SPEC/program/order-suggestions.md` § Diplomatic orders (visibility)
//   - `SPEC/game/diplomacy.md` § Overtures and Join Empire

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Minimal four-node topology: gp1 home OW province ↔ OW sea ↔ NW sea ↔
/// tribe1 colony NW province. Same shape as
/// `order_suggestion_declare_war_colonial_discovery_test.dart` and the
/// in-flight `order_suggestion_declare_war_intervention_risk_test.dart`
/// (PR #2602): keeps fixtures comparable across the issue's AC pinning set.
const MapTopology _topology = MapTopology(
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

/// Builds the embassy-stage colonial scenario: gp1 has NAP overture with
/// tribe1 (`hasEmbassy == true` per `OvertureState.hasEmbassy`), score at
/// the friendly threshold, and treasury comfortably above the Join Empire
/// cost for a single-province tribe (`joinEmpireBaseCost + 1 *
/// joinEmpirePerProvinceCost == 7000`).
///
/// Using NAP as the *current* overture stage is the only configuration that
/// lets the candidate generator emit `establishOverture(joinEmpire)` —
/// `OvertureStage.next` advances `nap → joinEmpire`, and the explicit
/// `OvertureStage.joinEmpire` cost / score gates in
/// `_establishOvertureSuggestionOrder` evaluate against
/// `joinEmpireCostForMinorOrTribe(game, targetId)` and
/// `relationScoreMinFriendly`.
Game _embassyColonialScenarioGame() {
  return Game(
    id: 'g-2509-colonial-acquisition',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: 'oldWorld|home',
            regionId: 'oldWorld',
            ownerId: 'gp1',
          ),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: 'newWorld|colony',
            regionId: 'newWorld',
            ownerId: 'tribe1',
          ),
        ],
      ),
      playerVisibilityByTile: const {
        'gp1': {'oldWorld|home|0|0': 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          'oldWorld|home': const ['oldWorld|home|0|0'],
        },
        'newWorld': {
          'newWorld|colony': const ['newWorld|colony|0|0'],
        },
      },
    ),
    players: const [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        // 10000 > joinEmpireBaseCost (5000) + 1 * joinEmpirePerProvinceCost
        // (2000) = 7000 for the single-province tribe1.
        treasury: 10000,
      ),
    ],
    tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'tribe1',
        state: RelationState.atPeace,
        score: relationScoreMinFriendly,
      ),
    ],
    overtureStates: const [
      OvertureState(
        gpId: 'gp1',
        targetId: 'tribe1',
        stage: OvertureStage.nap,
      ),
    ],
  );
}

String _orderKey(DiplomaticOrder o) =>
    '${o.type.name}:${o.targetFactionId}:${o.overtureStage?.name ?? ""}';

void main() {
  group('colonial acquisition suggestions (Refs #2509)', () {
    test(
      'embassy-stage tribe: suggestDiplomaticOrders surfaces Join Empire',
      () {
        const api = DefaultOrderSuggestionAPI();
        final game = _embassyColonialScenarioGame();
        final view = buildPlayerView(game, _topology, 'gp1');

        // Sanity: `tribe1` must be a known diplomatic target so the
        // candidate generator considers it (otherwise both Join Empire and
        // declare-war would be filtered before scoring).
        expect(
          knownDiplomaticTargetFactionIds(
            view: view,
            game: game,
            topology: _topology,
          ),
          contains('tribe1'),
        );

        final orders = api.suggestDiplomaticOrders(
          view,
          game,
          _topology,
          const Orders(),
        );

        final joinEmpireForTribe = orders.where(
          (o) =>
              o.targetFactionId == 'tribe1' &&
              o.type == DiplomaticOrderType.establishOverture &&
              o.overtureStage == OvertureStage.joinEmpire,
        );
        expect(
          joinEmpireForTribe,
          isNotEmpty,
          reason:
              'AC: merged orders may include establishOverture (Join Empire) '
              'when GP has embassy-stage overture and treasury covers cost',
        );
      },
    );

    test(
      'embassy-stage tribe: suggestDeclareWarOrders surfaces declareWar',
      () {
        const api = DefaultOrderSuggestionAPI();
        final game = _embassyColonialScenarioGame();
        final view = buildPlayerView(game, _topology, 'gp1');

        final orders = api.suggestDeclareWarOrders(
          view,
          game,
          _topology,
          const Orders(),
        );

        final declareForTribe = orders.where(
          (o) =>
              o.targetFactionId == 'tribe1' &&
              o.type == DiplomaticOrderType.declareWar,
        );
        expect(
          declareForTribe,
          isNotEmpty,
          reason:
              'AC: merged orders may include declareWar toward an at-peace '
              'tribe in the known target set (colonial-support weights must '
              'not gate emission); declare-war-only pass is independent of '
              'the per-target single-diplo cap in suggestDiplomaticOrders',
        );
      },
    );

    test(
      'candidate set is deterministic across repeated suggestion calls',
      () {
        const api = DefaultOrderSuggestionAPI();
        final game = _embassyColonialScenarioGame();
        final view = buildPlayerView(game, _topology, 'gp1');

        List<String> overtureKeys() => api
            .suggestDiplomaticOrders(view, game, _topology, const Orders())
            .map(_orderKey)
            .toList();
        List<String> declareKeys() => api
            .suggestDeclareWarOrders(view, game, _topology, const Orders())
            .map(_orderKey)
            .toList();

        final overtureFirst = overtureKeys();
        final overtureSecond = overtureKeys();
        final declareFirst = declareKeys();
        final declareSecond = declareKeys();

        expect(
          overtureSecond,
          equals(overtureFirst),
          reason:
              'AC: deterministic for fixed seed (suggestDiplomaticOrders '
              'returns the same candidate set every pass)',
        );
        expect(
          declareSecond,
          equals(declareFirst),
          reason:
              'AC: deterministic for fixed seed (suggestDeclareWarOrders '
              'returns the same candidate set every pass)',
        );
        expect(
          overtureFirst,
          contains('establishOverture:tribe1:joinEmpire'),
          reason:
              'deterministic Join Empire candidate must appear in the '
              'overture-pass suggestions',
        );
        expect(
          declareFirst,
          contains('declareWar:tribe1:'),
          reason:
              'deterministic declare-war candidate must appear in the '
              'declare-war-only pass suggestions',
        );
      },
    );
  });
}
