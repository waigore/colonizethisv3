// Compact army-move picker destination assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_army_move_picker_fixtures.dart';

/// Pins for [orderSuggestionArmyMovePickerScenarios] rows.
enum OrderSuggestionArmyMovePickerTarget {
  cachedPlayerOwnedMatchesDefaultDestinationPickerPath,
  sharedPlayerViewMatchesDefaultArmyMovePickerDestinations,
  sharedFactionMembershipMatchesDefaultArmyMovePickerDestinations,
  sharedCandidateValidatorMatchesDefaultAndSkipsForPlayerRebuild,
}

void runOrderSuggestionArmyMovePickerExpectation(
  OrderSuggestionArmyMovePickerTarget target,
) {
  switch (target) {
    case OrderSuggestionArmyMovePickerTarget
        .cachedPlayerOwnedMatchesDefaultDestinationPickerPath:
      final game = armyMovePickerGameTwoNeighborsWithNw(
        id: 'g_army_picker_dest_ids',
      );
      final topology = armyMovePickerTopologyFourProvinces();
      final army = armyMovePickerFieldArmy(game);
      final uncached = armyMovePickerDestinations(
        game: game,
        topology: topology,
        playerId: armyMovePickerGp,
        army: army,
        currentOrders: const Orders(),
      );
      final owned = <String>{
        for (final p in allProvinces(game.worldState))
          if (p.ownerId == armyMovePickerGp)
            toFullProvinceId(p.regionId, p.id),
      };
      final cached = armyMovePickerDestinations(
        game: game,
        topology: topology,
        playerId: armyMovePickerGp,
        army: army,
        currentOrders: const Orders(),
        playerOwnedFullProvinceIds: owned,
      );
      expect(cached, uncached);

    case OrderSuggestionArmyMovePickerTarget
        .sharedPlayerViewMatchesDefaultArmyMovePickerDestinations:
      final game = armyMovePickerGameTwoNeighborsWithNw(
        id: 'g_army_picker_shared_view',
      );
      final topology = armyMovePickerTopologyFourProvinces();
      final army = armyMovePickerFieldArmy(game);
      final baseline = armyMovePickerDestinations(
        game: game,
        topology: topology,
        playerId: armyMovePickerGp,
        army: army,
        currentOrders: const Orders(),
      );
      final view = buildPlayerView(game, topology, armyMovePickerGp);
      final unitsById = unitsByIdFromWorld(game.worldState);
      final withShared = armyMovePickerDestinations(
        game: game,
        topology: topology,
        playerId: armyMovePickerGp,
        army: army,
        currentOrders: const Orders(),
        resolution: orderResolutionContextFromView(
          view,
          game,
          unitsById: unitsById,
        ),
      );
      expect(withShared, baseline);

    case OrderSuggestionArmyMovePickerTarget
        .sharedFactionMembershipMatchesDefaultArmyMovePickerDestinations:
      final game = armyMovePickerGameMinimal(id: 'g_army_picker_shared_membership');
      final topology = armyMovePickerEmptyTopology;
      final army = armyMovePickerFieldArmy(game);
      final baseline = armyMovePickerDestinations(
        game: game,
        topology: topology,
        playerId: armyMovePickerGp,
        army: army,
        currentOrders: const Orders(),
      );
      final membership = DiplomacyFactionMembership.from(game);
      final withShared = armyMovePickerDestinations(
        game: game,
        topology: topology,
        playerId: armyMovePickerGp,
        army: army,
        currentOrders: const Orders(),
        factionMembership: membership,
      );
      expect(withShared, baseline);

    case OrderSuggestionArmyMovePickerTarget
        .sharedCandidateValidatorMatchesDefaultAndSkipsForPlayerRebuild:
      final game = armyMovePickerGameTwoNeighborsOnly(
        id: 'g_army_picker_shared_validator',
      );
      final topology = armyMovePickerTopologyThreeProvinces();
      const orders = Orders();
      final army = armyMovePickerFieldArmy(game);
      final baseline = armyMovePickerDestinations(
        game: game,
        topology: topology,
        playerId: armyMovePickerGp,
        army: army,
        currentOrders: orders,
      );
      final view = buildPlayerView(game, topology, armyMovePickerGp);
      final shared = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: armyMovePickerGp,
        basePrefix: orders,
        resolution: orderResolutionContextFromView(view, game),
      );
      resetIncrementalCandidateValidatorBuildCountForTests();
      final withSharedValidator = armyMovePickerDestinations(
        game: game,
        topology: topology,
        playerId: armyMovePickerGp,
        army: army,
        currentOrders: orders,
        sharedCandidateValidator: shared,
      );
      expect(withSharedValidator, baseline);
      expect(
        incrementalCandidateValidatorBuildCountForTests,
        0,
        reason:
            'army picker must reuse supplied pass validator (Refs #2394)',
      );
  }
}
