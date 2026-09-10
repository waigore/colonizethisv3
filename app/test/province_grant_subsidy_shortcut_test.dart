// Pins MAP20001 Political Grant Aid / Set Subsidy action state (Refs #4761).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md — Political Grant/Subsidy.
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_grant_subsidy.dart';
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_grant_subsidy_shortcut_fixtures.dart';

void main() {
  suppressLogsForTests();

  ProvinceGrantSubsidyActionState grant({
    required Game game,
    Orders orders = const Orders(),
  }) => GameMapAreaStateLogicProvinceActions.provinceGrantAidActionState(
    game: game,
    humanPlayerId: kGrantSubsidyHumanPlayerId,
    provinceId: kGrantSubsidyProvinceId,
    topology: kGrantSubsidyTopology,
    currentOrders: orders,
  );

  ProvinceGrantSubsidyActionState subsidy({
    required Game game,
    Orders orders = const Orders(),
  }) => GameMapAreaProvinceActionStatesGrantSubsidy.compute(
    game: game,
    humanPlayerId: kGrantSubsidyHumanPlayerId,
    provinceId: kGrantSubsidyProvinceId,
    topology: kGrantSubsidyTopology,
    currentOrders: orders,
    type: DiplomaticOrderType.setSubsidy,
  );

  group('Grant Aid / Set Subsidy action state', () {
    test('shows both enabled when Embassy held and probes accept', () {
      final game = buildGrantSubsidyShortcutGame(ownerId: kGrantSubsidyMinorId);
      for (final state in [grant(game: game), subsidy(game: game)]) {
        expect(state.showControl, isTrue);
        expect(state.enabled, isTrue);
        expect(state.pending, isFalse);
        expect(state.ownerId, kGrantSubsidyMinorId);
      }
    });

    test('hides when Embassy is missing, own, GP-owned, or at war', () {
      for (final game in [
        buildGrantSubsidyShortcutGame(
          ownerId: kGrantSubsidyMinorId,
          overtureStage: OvertureStage.tradeConsulate,
        ),
        buildGrantSubsidyShortcutGame(
          ownerId: kGrantSubsidyHumanPlayerId,
          asMinor: false,
        ),
        buildGrantSubsidyShortcutGame(
          ownerId: kGrantSubsidyGpOwnerId,
          asMinor: false,
        ),
        buildGrantSubsidyShortcutGame(
          ownerId: kGrantSubsidyMinorId,
          atWar: true,
        ),
      ]) {
        expect(grant(game: game).showControl, isFalse);
        expect(subsidy(game: game).showControl, isFalse);
      }
    });

    test('pending grant or subsidy enables Cancel for that type only', () {
      final game = buildGrantSubsidyShortcutGame(ownerId: kGrantSubsidyMinorId);
      final pendingGrant = Orders(
        diplomaticOrdersByPlayerId: {
          kGrantSubsidyHumanPlayerId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.grantAid,
              targetFactionId: kGrantSubsidyMinorId,
              amount: 1000,
            ),
          ],
        },
      );
      expect(grant(game: game, orders: pendingGrant).pending, isTrue);
      expect(grant(game: game, orders: pendingGrant).enabled, isTrue);
      expect(subsidy(game: game, orders: pendingGrant).pending, isFalse);
    });

    test('disables Grant Aid when treasury is insufficient', () {
      final game = buildGrantSubsidyShortcutGame(
        ownerId: kGrantSubsidyMinorId,
        treasury: 0,
      );
      final state = grant(game: game);
      expect(state.showControl, isTrue);
      expect(state.enabled, isFalse);
      expect(state.rejectionReason, contains('Insufficient treasury'));
      expect(subsidy(game: game).enabled, isTrue);
    });
  });
}
