// Table-driven army-move picker destination scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_suggestion_army_move_picker_fixtures.dart';

void osampRunCachedPlayerOwnedMatchesDefaultDestinationPickerPath() {
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
      if (p.ownerId == armyMovePickerGp) toFullProvinceId(p.regionId, p.id),
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
}

void osampRunSharedPlayerViewMatchesDefaultArmyMovePickerDestinations() {
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
}

void osampRunSharedFactionMembershipMatchesDefaultArmyMovePickerDestinations() {
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
}

void osampRunSharedCandidateValidatorMatchesDefaultAndSkipsForPlayerRebuild() {
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
    reason: 'army picker must reuse supplied pass validator (Refs #2394)',
  );
}

List<RunnableScenario> orderSuggestionArmyMovePickerScenarios() => const [
  RunnableScenario(
    label: 'cached player-owned set matches default destination picker path',
    run: osampRunCachedPlayerOwnedMatchesDefaultDestinationPickerPath,
  ),
  RunnableScenario(
    label:
        'shared playerView and unitsById matches default armyMovePickerDestinations',
    run: osampRunSharedPlayerViewMatchesDefaultArmyMovePickerDestinations,
  ),
  RunnableScenario(
    label:
        'shared factionMembership matches default armyMovePickerDestinations',
    run:
        osampRunSharedFactionMembershipMatchesDefaultArmyMovePickerDestinations,
  ),
  RunnableScenario(
    label:
        'sharedCandidateValidator matches default and skips forPlayer rebuild',
    run: osampRunSharedCandidateValidatorMatchesDefaultAndSkipsForPlayerRebuild,
  ),
];
