import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'incremental_candidate_validator.dart';
import 'order_suggestion_pass_context.dart';
import 'order_visibility.dart';
import 'order_suggestion_army_move_picker.dart';

export 'order_suggestion_army_move_picker.dart'
    show
        ArmyMovePickerDestination,
        armyMoveCandidateDestinationProvinceIds,
        armyMovePickerDestinations,
        armyMovePlayerOwnedProvinceIds;

const int _kMaxArmyMoveSuggestionsPerArmy = 12;
const int _kMaxArmyMoveProbeAttemptsPerArmy = 80;

/// Suggests candidate [ArmyMoveOrder]s for non-home armies owned by [view.playerId].
///
/// Throughput hook: callers that enumerate multiple suggestion families against
/// the same `(game, view.playerId, currentOrders)` may supply
/// [sharedCandidateValidator] to amortize `PlayerView` / units-by-id
/// construction across families (Refs #2394). The shared instance must be
/// built with the same inputs; observable suggestions must match the default
/// path.
List<ArmyMoveOrder> suggestArmyMoveOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  final pass = SuggestionPassContext.forPlayerView(
    view: view,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    familyLabel: 'suggestArmyMoveOrders',
    sharedCandidateValidator: sharedCandidateValidator,
    useBuildIncrementalWrapper: false,
  );
  final playerId = pass.playerId;
  final suggestions = <ArmyMoveOrder>[];
  final candidateValidator = pass.candidateValidator;
  final existingArmyMoves = indexExistingTargetsByEntityId(
    currentOrders.armyMoveOrdersByPlayerId[playerId],
    (m) => m.armyId,
    (m) => m.destinationProvinceId,
  );

  final playerOwnedFullProvinceIds = armyMovePlayerOwnedProvinceIds(
    game: game,
    playerId: playerId,
    view: view,
  );

  for (final army in game.worldState.armies) {
    if (army.ownerId != playerId) continue;
    if (army.isHomeArmy) continue;

    final fromProvinceId = army.stationedProvinceId;
    final unitRegion = ProvinceId.regionIdFrom(fromProvinceId);

    if (!moveSourceVisibilityOk(view, unitRegion, fromProvinceId)) continue;

    final destIds = armyMoveCandidateDestinationProvinceIds(
      game: game,
      topology: topology,
      playerId: playerId,
      army: army,
      playerOwnedFullProvinceIds: playerOwnedFullProvinceIds,
    );

    runCappedSuggestionProbeLoop<String>(
      candidates: destIds,
      shouldSkip: (destinationProvinceId) {
        final already = existingArmyMoves[army.id];
        return already != null && already.contains(destinationProvinceId);
      },
      probe: (destinationProvinceId) {
        final candidate = ArmyMoveOrder(
          armyId: army.id,
          destinationProvinceId: destinationProvinceId,
        );
        return candidateValidator.isArmyMoveAccepted(candidate);
      },
      onAccepted: (destinationProvinceId) {
        suggestions.add(
          ArmyMoveOrder(
            armyId: army.id,
            destinationProvinceId: destinationProvinceId,
          ),
        );
      },
      maxAccepted: _kMaxArmyMoveSuggestionsPerArmy,
      maxProbes: _kMaxArmyMoveProbeAttemptsPerArmy,
    );
  }

  suggestions.sort((a, b) {
    final idCmp = a.armyId.compareTo(b.armyId);
    if (idCmp != 0) return idCmp;
    return a.destinationProvinceId.compareTo(b.destinationProvinceId);
  });
  return suggestions;
}
