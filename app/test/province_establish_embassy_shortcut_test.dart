// Pins MAP20001 Political Establish Embassy action state (Refs #4739).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md — Political Embassy shortcut.
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_establish_embassy.dart';
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_establish_embassy_shortcut_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('Establish Embassy action state', () {
    test('shows enabled when Consulate held and probe accepts', () {
      final game = buildEstablishEmbassyShortcutGame(
        ownerId: kEstablishEmbassyMinorId,
      );
      final state =
          GameMapAreaStateLogicProvinceActions.provinceEstablishEmbassyActionState(
            game: game,
            humanPlayerId: kEstablishEmbassyHumanPlayerId,
            provinceId: kEstablishEmbassyProvinceId,
            topology: kEstablishEmbassyTopology,
            currentOrders: const Orders(),
          );
      expect(state.showControl, isTrue);
      expect(state.enabled, isTrue);
      expect(state.pending, isFalse);
      expect(state.ownerId, kEstablishEmbassyMinorId);
      expect(state.order?.overtureStage, OvertureStage.embassy);
    });

    test('hides when Consulate is missing', () {
      final game = buildEstablishEmbassyShortcutGame(
        ownerId: kEstablishEmbassyMinorId,
        overtureStage: null,
      );
      final state = GameMapAreaProvinceActionStatesEstablishEmbassy.compute(
        game: game,
        humanPlayerId: kEstablishEmbassyHumanPlayerId,
        provinceId: kEstablishEmbassyProvinceId,
        topology: kEstablishEmbassyTopology,
        currentOrders: const Orders(),
      );
      expect(state.showControl, isFalse);
    });

    test('hides when Embassy already held', () {
      final game = buildEstablishEmbassyShortcutGame(
        ownerId: kEstablishEmbassyMinorId,
        overtureStage: OvertureStage.embassy,
      );
      final state = GameMapAreaProvinceActionStatesEstablishEmbassy.compute(
        game: game,
        humanPlayerId: kEstablishEmbassyHumanPlayerId,
        provinceId: kEstablishEmbassyProvinceId,
        topology: kEstablishEmbassyTopology,
        currentOrders: const Orders(),
      );
      expect(state.showControl, isFalse);
    });

    test('hides for own, GP-owned, and at-war provinces', () {
      for (final game in [
        buildEstablishEmbassyShortcutGame(
          ownerId: kEstablishEmbassyHumanPlayerId,
          asMinor: false,
        ),
        buildEstablishEmbassyShortcutGame(
          ownerId: kEstablishEmbassyGpOwnerId,
          asMinor: false,
        ),
        buildEstablishEmbassyShortcutGame(
          ownerId: kEstablishEmbassyMinorId,
          atWar: true,
        ),
      ]) {
        final state = GameMapAreaProvinceActionStatesEstablishEmbassy.compute(
          game: game,
          humanPlayerId: kEstablishEmbassyHumanPlayerId,
          provinceId: kEstablishEmbassyProvinceId,
          topology: kEstablishEmbassyTopology,
          currentOrders: const Orders(),
        );
        expect(state.showControl, isFalse);
      }
    });

    test('pending Embassy order enables Cancel path', () {
      final game = buildEstablishEmbassyShortcutGame(
        ownerId: kEstablishEmbassyMinorId,
      );
      final pending = DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: kEstablishEmbassyMinorId,
        overtureStage: OvertureStage.embassy,
      );
      final state = GameMapAreaProvinceActionStatesEstablishEmbassy.compute(
        game: game,
        humanPlayerId: kEstablishEmbassyHumanPlayerId,
        provinceId: kEstablishEmbassyProvinceId,
        topology: kEstablishEmbassyTopology,
        currentOrders: Orders(
          diplomaticOrdersByPlayerId: {
            kEstablishEmbassyHumanPlayerId: [pending],
          },
        ),
      );
      expect(state.showControl, isTrue);
      expect(state.enabled, isTrue);
      expect(state.pending, isTrue);
    });

    test('disabled when Diplomatic Expertise missing', () {
      final game = buildEstablishEmbassyShortcutGame(
        ownerId: kEstablishEmbassyMinorId,
        diplomaticExpertise: false,
      );
      final state = GameMapAreaProvinceActionStatesEstablishEmbassy.compute(
        game: game,
        humanPlayerId: kEstablishEmbassyHumanPlayerId,
        provinceId: kEstablishEmbassyProvinceId,
        topology: kEstablishEmbassyTopology,
        currentOrders: const Orders(),
      );
      expect(state.showControl, isTrue);
      expect(state.enabled, isFalse);
      expect(state.rejectionReason, isNotEmpty);
    });
  });
}
