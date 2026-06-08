// Pins the **must-have #2 (Merchant `purchase_land`)** AC from issue #2509:
//
//   Given a GP in **COLONIAL** phase with idle Merchant units, embassy with a
//   tribe, a visible `newWorld|` province containing a valid `purchase_land`
//   target tile (resource present, prospected if mineral, treasury
//   sufficient), when civilian work planning runs, then a `purchase_land`
//   work order toward that tile is among suggested orders before lower-
//   priority colonial work (deterministic for fixed seed).
//
// Pins the *candidate-emission* contract at the logic suggestion API
// (`DefaultOrderSuggestionAPI.suggestWorkOrders`) — the same boundary
// `order_suggestion_colonial_acquisition_join_empire_or_war_test.dart`
// (PR #2603) pins for the `establishOverture` / `declareWar` diplomatic
// passes. The AI-side ordering of `purchase_land` versus lower-priority
// colonial work is separately pinned by
// `packages/colonizethis_logic/test/full_ai_civilian_work_selection_colonial_test.dart`
// ("Merchant prefers purchase_land in newWorld tribe province"), and the
// AI-side COLONIAL-phase orchestrator integration is pinned by
// `packages/colonizethis_ai/test/domain_planner_orchestrator_colonial_civilian_work_test.dart`
// ("COLONIAL phase emits purchase_land when merchant work is suggested").
// Both rely on the candidate set actually surfacing `purchase_land` from
// the logic API — that pre-requisite was previously implicit. This file
// makes it explicit so future tuning cannot silently drop the
// `purchase_land` candidate for the embassy-stage NW tribe scenario.
//
// SPEC:
//   - `SPEC/ai/ai-architecture.md` § Colonial expansion (Full AI) and
//     § Observer goal phases (Full AI) — COLONIAL imperative pursues NW
//     acquisition via the existing colonial paths (Join Empire,
//     `purchase_land`, declare-war + invasion).
//   - `SPEC/program/order-suggestions.md` § Rules / Work orders —
//     `suggestWorkOrders` is the canonical suggestion entry point.
//   - `SPEC/game/civilian-units.md` § Merchant — purchase_land cost +
//     embassy / treasury / resource preconditions.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Four-node topology: gp1 home OW province ↔ OW sea ↔ NW sea ↔ tribe1
/// colony NW province. Mirrors the shape used by
/// `order_suggestion_colonial_acquisition_join_empire_or_war_test.dart`
/// (PR #2603) and `order_suggestion_declare_war_colonial_discovery_test.dart`
/// so the colonial-acquisition pin tests share a consistent fixture spine.
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

const String _gpId = 'gp1';
const String _tribeId = 'tribe1';
const String _merchantId = 'm1';
const String _homeProvinceId = 'oldWorld|home';
const String _colonyProvinceId = 'newWorld|colony';
const String _homeTileKey = 'oldWorld|home|0|0';
const String _colonyTileKey = 'newWorld|colony|0|0';

/// Builds the embassy-stage NW colonial scenario:
///
/// - gp1 owns its single OW home province (and has visibility on its own
///   home tile).
/// - tribe1 owns the single NW colony province; gp1 has fog visibility on
///   the NW colony tile (`fullyVisible`) and a Merchant unit standing on
///   that tile (the only legal stance for a `purchase_land` work order in
///   a foreign province per `WorkOrderTargetPrechecks.precheckPurchaseLand`).
/// - The NW colony tile has a non-mineral resource (`grain`) — non-mineral
///   means no prospection is required, isolating the AC's "valid
///   purchase_land target tile" clauses to embassy + treasury + resource.
/// - gp1 has an `OvertureStage.embassy` overture with tribe1 and friendly
///   peace relations, so the validator's embassy gate accepts.
/// - Treasury is `1000` — well above the grain `purchaseLandCost`
///   (`15 × landPurchaseDefaultBasePrice = 150`).
///
/// The fixture is deliberately minimal: a single Merchant on a single
/// candidate tile so the resulting candidate set has exactly one expected
/// `purchase_land` order. That keeps the pin precise about the AC's
/// "is among suggested orders" requirement without over-constraining the
/// rest of the suggestion pipeline.
Game _embassyNwTribeScenarioGame({bool withEmbassy = true}) {
  return Game(
    id: 'g-2509-purchase-land-colonial',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 110),
      oldWorld: const RegionData(
        provinces: [
          Province(id: _homeProvinceId, regionId: 'oldWorld', ownerId: _gpId),
        ],
      ),
      newWorld: RegionData(
        provinces: const [
          Province(
            id: _colonyProvinceId,
            regionId: 'newWorld',
            ownerId: _tribeId,
          ),
        ],
        units: [
          Unit(
            id: _merchantId,
            type: kUnitTypeMerchant,
            ownerId: _gpId,
            locationProvinceId: _colonyProvinceId,
            tileKey: _colonyTileKey,
          ),
        ],
      ),
      playerVisibilityByTile: const {
        _gpId: {
          _homeTileKey: 'fullyVisible',
          _colonyTileKey: 'fullyVisible',
        },
      },
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          _homeProvinceId: [_homeTileKey],
        },
        'newWorld': {
          _colonyProvinceId: [_colonyTileKey],
        },
      },
      resourceByTileKey: const {_colonyTileKey: 'grain'},
    ),
    players: const [
      Player(
        id: _gpId,
        displayName: 'GP1',
        isHuman: false,
        treasury: 1000,
        techUnlocked: {kTechIdMerchantCompanies: true},
      ),
    ],
    tribes: const [Tribe(id: _tribeId, displayName: 'T1')],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: _gpId,
        factionId2: _tribeId,
        state: RelationState.atPeace,
        score: relationScoreMinFriendly,
      ),
    ],
    overtureStates: withEmbassy
        ? const [
            OvertureState(
              gpId: _gpId,
              targetId: _tribeId,
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ]
        : const <OvertureState>[],
  );
}

String _workOrderKey(WorkOrder o) =>
    '${o.unitId}:${o.target}:${o.targetTileKey}';

void main() {
  group('colonial purchase_land suggestions (Refs #2509)', () {
    test(
      'embassy-stage NW tribe: suggestWorkOrders surfaces purchase_land for Merchant',
      () {
        const api = DefaultOrderSuggestionAPI();
        final game = _embassyNwTribeScenarioGame();
        final view = buildPlayerView(game, _topology, _gpId);

        final orders = api.suggestWorkOrders(
          view,
          game,
          _topology,
          const Orders(),
        );

        final purchaseLandForMerchant = orders.where(
          (o) =>
              o.unitId == _merchantId &&
              o.target == kWorkTargetPurchaseLand &&
              o.targetTileKey == _colonyTileKey,
        );
        expect(
          purchaseLandForMerchant,
          isNotEmpty,
          reason:
              'AC must-have #2: suggested orders must include a '
              '`purchase_land` WorkOrder toward the embassy-stage NW tribe '
              'tile when the validator preconditions (embassy + at peace + '
              'treasury + resource) all hold. Future tuning must not '
              'silently drop the candidate from the merchant suggestion '
              'pipeline.',
        );
      },
    );

    test(
      'embassy-stage NW tribe: suggestWorkOrders is deterministic for repeated calls',
      () {
        const api = DefaultOrderSuggestionAPI();
        final game = _embassyNwTribeScenarioGame();
        final view = buildPlayerView(game, _topology, _gpId);

        List<String> orderKeys() => api
            .suggestWorkOrders(view, game, _topology, const Orders())
            .map(_workOrderKey)
            .toList();

        final first = orderKeys();
        final second = orderKeys();

        expect(
          second,
          equals(first),
          reason:
              'AC: deterministic for fixed seed — suggestWorkOrders must '
              'return the same candidate set across repeated calls on '
              'identical inputs (per the determinism pattern shared with '
              '`order_suggestion_colonial_acquisition_join_empire_or_war_test.dart`).',
        );
        expect(
          first,
          contains('$_merchantId:$kWorkTargetPurchaseLand:$_colonyTileKey'),
          reason:
              'deterministic purchase_land candidate must appear in the '
              'logic suggestion API output for the embassy-stage scenario.',
        );
      },
    );

    test(
      'no embassy with NW tribe: suggestWorkOrders omits purchase_land for Merchant',
      () {
        const api = DefaultOrderSuggestionAPI();
        final game = _embassyNwTribeScenarioGame(withEmbassy: false);
        final view = buildPlayerView(game, _topology, _gpId);

        final orders = api.suggestWorkOrders(
          view,
          game,
          _topology,
          const Orders(),
        );

        final purchaseLandForMerchant = orders.where(
          (o) =>
              o.unitId == _merchantId &&
              o.target == kWorkTargetPurchaseLand,
        );
        expect(
          purchaseLandForMerchant,
          isEmpty,
          reason:
              'Negative pin: without embassy, the candidate validator '
              '(`precheckPurchaseLand`) rejects the order, so '
              'suggestWorkOrders must not surface it. Confirms the embassy '
              'precondition is enforced at the suggestion layer (not only '
              'at order validation time).',
        );
      },
    );
  });
}
