// Pins MAP20001 Political Establish Consulate action state (Refs #4346).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md — Political Consulate shortcut.
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_establish_consulate.dart';
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_detail_overlay_host_support_fixtures.dart';
import 'province_establish_consulate_shortcut_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('Establish Consulate action state', () {
    test('shows enabled when gate applies and probe accepts', () {
      final game = buildEstablishConsulateShortcutGame(
        ownerId: kEstablishConsulateMinorId,
      );
      final state =
          GameMapAreaStateLogicProvinceActions.provinceEstablishConsulateActionState(
            game: game,
            humanPlayerId: kEstablishConsulateHumanPlayerId,
            provinceId: kEstablishConsulateProvinceId,
            topology: kEstablishConsulateTopology,
            currentOrders: const Orders(),
          );
      expect(state.showControl, isTrue);
      expect(state.enabled, isTrue);
      expect(state.pending, isFalse);
      expect(state.ownerId, kEstablishConsulateMinorId);
      expect(state.order?.overtureStage, OvertureStage.tradeConsulate);
    });

    test('hides when Consulate already held', () {
      final game = buildEstablishConsulateShortcutGame(
        ownerId: kEstablishConsulateMinorId,
        overtureStage: OvertureStage.tradeConsulate,
      );
      final state = GameMapAreaProvinceActionStatesEstablishConsulate.compute(
        game: game,
        humanPlayerId: kEstablishConsulateHumanPlayerId,
        provinceId: kEstablishConsulateProvinceId,
        topology: kEstablishConsulateTopology,
        currentOrders: const Orders(),
      );
      expect(state.showControl, isFalse);
    });

    test('hides for human-owned province', () {
      final game = buildEstablishConsulateShortcutGame(
        ownerId: kEstablishConsulateHumanPlayerId,
        asMinor: false,
      );
      final state = GameMapAreaProvinceActionStatesEstablishConsulate.compute(
        game: game,
        humanPlayerId: kEstablishConsulateHumanPlayerId,
        provinceId: kEstablishConsulateProvinceId,
        topology: kEstablishConsulateTopology,
        currentOrders: const Orders(),
      );
      expect(state.showControl, isFalse);
    });

    test('pending Consulate order enables Cancel path', () {
      final game = buildEstablishConsulateShortcutGame(
        ownerId: kEstablishConsulateMinorId,
      );
      final pending = DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: kEstablishConsulateMinorId,
        overtureStage: OvertureStage.tradeConsulate,
      );
      final state = GameMapAreaProvinceActionStatesEstablishConsulate.compute(
        game: game,
        humanPlayerId: kEstablishConsulateHumanPlayerId,
        provinceId: kEstablishConsulateProvinceId,
        topology: kEstablishConsulateTopology,
        currentOrders: Orders(
          diplomaticOrdersByPlayerId: {
            kEstablishConsulateHumanPlayerId: [pending],
          },
        ),
      );
      expect(state.showControl, isTrue);
      expect(state.enabled, isTrue);
      expect(state.pending, isTrue);
    });

    test('disabled when Diplomatic Expertise missing', () {
      final game = buildEstablishConsulateShortcutGame(
        ownerId: kEstablishConsulateMinorId,
        diplomaticExpertise: false,
      );
      final state = GameMapAreaProvinceActionStatesEstablishConsulate.compute(
        game: game,
        humanPlayerId: kEstablishConsulateHumanPlayerId,
        provinceId: kEstablishConsulateProvinceId,
        topology: kEstablishConsulateTopology,
        currentOrders: const Orders(),
      );
      expect(state.showControl, isTrue);
      expect(state.enabled, isFalse);
      expect(state.rejectionReason, isNotEmpty);
    });
  });

  group('shortcut callback emit', () {
    test(
      'enabled tap emits ConfirmDialogEvent then Append on confirm',
      () async {
        final game = buildEstablishConsulateShortcutGame(
          ownerId: kEstablishConsulateMinorId,
        );
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final confirmFuture = bus.on<ConfirmDialogEvent>().first.timeout(
          const Duration(seconds: 2),
        );
        final appendFuture = bus
            .on<AppendDiplomaticOrderRequestedEvent>()
            .first
            .timeout(const Duration(seconds: 2));

        final order = DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: kEstablishConsulateMinorId,
          overtureStage: OvertureStage.tradeConsulate,
        );
        final callbacks = provinceDetailCallbacks(
          game: game,
          selectedTileKey: kEstablishConsulateTileKey,
          exploreEnabled: false,
          prospectEnabled: false,
          buildImprovementEnabled: false,
          buildRoadEnabled: false,
          buildFortEnabled: false,
          buildPortEnabled: false,
          purchaseLandEnabled: false,
          provinceId: kEstablishConsulateProvinceId,
          establishConsulateEnabled: true,
          establishConsulatePending: false,
          establishConsulateOrder: order,
          establishConsulateTargetName: 'Minor One',
          combinedTopology: kEstablishConsulateTopology,
          bus: bus,
        );
        expect(callbacks.onEstablishConsulateTap, isNotNull);
        callbacks.onEstablishConsulateTap!();
        final confirm = await confirmFuture;
        confirm.result(true);
        final append = await appendFuture;
        expect(append.order.targetFactionId, kEstablishConsulateMinorId);
        expect(append.order.overtureStage, OvertureStage.tradeConsulate);
      },
    );

    test('pending tap emits RemoveDiplomaticOrderRequestedEvent', () async {
      final game = buildEstablishConsulateShortcutGame(
        ownerId: kEstablishConsulateMinorId,
      );
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final removeFuture = bus
          .on<RemoveDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      final order = DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: kEstablishConsulateMinorId,
        overtureStage: OvertureStage.tradeConsulate,
      );
      final callbacks = provinceDetailCallbacks(
        game: game,
        selectedTileKey: kEstablishConsulateTileKey,
        exploreEnabled: false,
        prospectEnabled: false,
        buildImprovementEnabled: false,
        buildRoadEnabled: false,
        buildFortEnabled: false,
        buildPortEnabled: false,
        purchaseLandEnabled: false,
        provinceId: kEstablishConsulateProvinceId,
        establishConsulateEnabled: true,
        establishConsulatePending: true,
        establishConsulateOrder: order,
        establishConsulateTargetName: 'Minor One',
        bus: bus,
      );
      expect(callbacks.onEstablishConsulateTap, isNotNull);
      callbacks.onEstablishConsulateTap!();
      final remove = await removeFuture;
      expect(remove.targetFactionId, kEstablishConsulateMinorId);
      expect(remove.type, DiplomaticOrderType.establishOverture);
    });
  });
}
