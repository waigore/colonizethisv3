// Pins MAP20001 Political owner standing + Offer Peace (Refs #4479).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md — Political standing / Offer Peace.
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_detail_overlay_host_support_fixtures.dart';
import 'province_offer_peace_shortcut_test_support.dart';

void main() {
  suppressLogsForTests();

  group('Owner standing / Offer Peace action state', () {
    test('at war shows standing and Offer Peace when probe accepts', () {
      final game = offerPeaceBuildGame(
        ownerId: offerPeaceRivalId,
        relationState: RelationState.atWar,
      );
      final state =
          GameMapAreaStateLogicProvinceActions.provinceOfferPeaceActionState(
            game: game,
            humanPlayerId: offerPeaceHumanPlayerId,
            provinceId: offerPeaceProvinceId,
            topology: offerPeaceTopology,
            currentOrders: const Orders(),
            isSeaZone: false,
          );
      expect(state.showStanding, isTrue);
      expect(state.atWar, isTrue);
      expect(state.showOfferPeaceControl, isTrue);
      expect(state.offerPeaceEnabled, isTrue);
      expect(state.offerPeacePending, isFalse);
      expect(state.order?.type, DiplomaticOrderType.offerPeace);
    });

    test('at peace shows standing without Offer Peace', () {
      final game = offerPeaceBuildGame(ownerId: offerPeaceRivalId);
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: game,
        humanPlayerId: offerPeaceHumanPlayerId,
        provinceId: offerPeaceProvinceId,
        topology: offerPeaceTopology,
        currentOrders: const Orders(),
        isSeaZone: false,
      );
      expect(state.showStanding, isTrue);
      expect(state.atWar, isFalse);
      expect(state.showOfferPeaceControl, isFalse);
      expect(state.showAllianceBadge, isFalse);
    });

    test('formal alliance shows ALLIANCE badge at peace', () {
      final game = offerPeaceBuildGame(
        ownerId: offerPeaceRivalId,
        formalAlliance: true,
      );
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: game,
        humanPlayerId: offerPeaceHumanPlayerId,
        provinceId: offerPeaceProvinceId,
        topology: offerPeaceTopology,
        currentOrders: const Orders(),
        isSeaZone: false,
      );
      expect(state.showStanding, isTrue);
      expect(state.showAllianceBadge, isTrue);
      expect(state.showOfferPeaceControl, isFalse);
    });

    test('hides when own province', () {
      final game = offerPeaceBuildGame(ownerId: offerPeaceHumanPlayerId);
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: game,
        humanPlayerId: offerPeaceHumanPlayerId,
        provinceId: 'oldWorld|p_human',
        topology: offerPeaceTopology,
        currentOrders: const Orders(),
        isSeaZone: false,
      );
      expect(state.showStanding, isFalse);
      expect(state.showOfferPeaceControl, isFalse);
    });

    test('hides when no DiplomacyRelation', () {
      final game = offerPeaceBuildGame(
        ownerId: offerPeaceRivalId,
        includeRelation: false,
      );
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: game,
        humanPlayerId: offerPeaceHumanPlayerId,
        provinceId: offerPeaceProvinceId,
        topology: offerPeaceTopology,
        currentOrders: const Orders(),
        isSeaZone: false,
      );
      expect(state.showStanding, isFalse);
      expect(state.showOfferPeaceControl, isFalse);
    });

    test('hides when sea-zone context', () {
      final game = offerPeaceBuildGame(
        ownerId: offerPeaceRivalId,
        relationState: RelationState.atWar,
      );
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: game,
        humanPlayerId: offerPeaceHumanPlayerId,
        provinceId: offerPeaceProvinceId,
        topology: offerPeaceTopology,
        currentOrders: const Orders(),
        isSeaZone: true,
      );
      expect(state.showStanding, isFalse);
      expect(state.showOfferPeaceControl, isFalse);
    });

    test('pending offerPeace enables Cancel path', () {
      final game = offerPeaceBuildGame(
        ownerId: offerPeaceRivalId,
        relationState: RelationState.atWar,
      );
      final state = GameMapAreaProvinceActionStatesOfferPeace.compute(
        game: game,
        humanPlayerId: offerPeaceHumanPlayerId,
        provinceId: offerPeaceProvinceId,
        topology: offerPeaceTopology,
        currentOrders: const Orders(
          diplomaticOrdersByPlayerId: {
            offerPeaceHumanPlayerId: [
              DiplomaticOrder(
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: offerPeaceRivalId,
              ),
            ],
          },
        ),
        isSeaZone: false,
      );
      expect(state.showOfferPeaceControl, isTrue);
      expect(state.offerPeaceEnabled, isTrue);
      expect(state.offerPeacePending, isTrue);
    });
  });

  group('Offer Peace shortcut callbacks', () {
    test('enabled tap emits confirm then append', () async {
      final bus = AppEventBus();
      const order = DiplomaticOrder(
        type: DiplomaticOrderType.offerPeace,
        targetFactionId: offerPeaceRivalId,
      );
      final game = offerPeaceBuildGame(
        ownerId: offerPeaceRivalId,
        relationState: RelationState.atWar,
      );
      final confirmFuture = bus.on<ConfirmDialogEvent>().first.timeout(
        const Duration(seconds: 2),
      );
      final appendFuture = bus
          .on<AppendDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      final callbacks = provinceDetailCallbacks(
        game: game,
        selectedTileKey: offerPeaceTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        provinceId: offerPeaceProvinceId,
        offerPeaceEnabled: true,
        offerPeacePending: false,
        offerPeaceOrder: order,
        offerPeaceTargetName: 'Rival',
        combinedTopology: offerPeaceTopology,
        bus: bus,
      );
      expect(callbacks.onOfferPeaceTap, isNotNull);
      callbacks.onOfferPeaceTap!();
      final confirm = await confirmFuture;
      confirm.result(true);
      final append = await appendFuture;
      expect(append.order.type, DiplomaticOrderType.offerPeace);
    });

    test('pending tap emits remove only', () async {
      final bus = AppEventBus();
      const order = DiplomaticOrder(
        type: DiplomaticOrderType.offerPeace,
        targetFactionId: offerPeaceRivalId,
      );
      final game = offerPeaceBuildGame(
        ownerId: offerPeaceRivalId,
        relationState: RelationState.atWar,
      );
      final removeFuture = bus
          .on<RemoveDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      final callbacks = provinceDetailCallbacks(
        game: game,
        selectedTileKey: offerPeaceTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        offerPeaceEnabled: true,
        offerPeacePending: true,
        offerPeaceOrder: order,
        offerPeaceTargetName: 'Rival',
        bus: bus,
      );
      callbacks.onOfferPeaceTap!();
      final remove = await removeFuture;
      expect(remove.type, DiplomaticOrderType.offerPeace);
      expect(remove.targetFactionId, offerPeaceRivalId);
    });
  });
}
