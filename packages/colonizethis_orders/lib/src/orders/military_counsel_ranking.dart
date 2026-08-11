/// Human Military Counsel ranking API. SPEC/program/military-counsel-ranking.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'incremental_candidate_validator.dart';
import 'military_counsel_affordance.dart';
import 'military_counsel_invasion_intel.dart';
import 'military_counsel_scoring.dart';
import 'military_counsel_types.dart';
import 'order_suggestion_army_move_picker.dart';
import 'order_suggestion_build.dart';

const int _kMaxRecommendations = 3;

int _kindPrecedence(MilitaryCounselRecommendationKind kind) {
  switch (kind) {
    case MilitaryCounselRecommendationKind.trainUnit:
      return 0;
    case MilitaryCounselRecommendationKind.invade:
      return 1;
  }
}

String _stableTrainId(String unitType) => 'train:$unitType';

String _stableInvadeId(String armyId, String destinationProvinceId) =>
    'invade:$armyId:$destinationProvinceId';

List<MilitaryCounselRecommendation> rankMilitaryCounselRecommendations({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
}) {
  final player = game.playerById(playerId);
  if (player == null) return const [];

  final view = buildPlayerView(game, topology, playerId);
  final sharedValidator = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: currentOrders,
  );

  final candidates = <MilitaryCounselRecommendation>[];

  final buildSuggestions = suggestBuildOrders(
    view,
    game,
    topology,
    currentOrders,
    sharedCandidateValidator: sharedValidator,
  );
  final seenUnitTypes = <String>{};
  for (final order in buildSuggestions) {
    if (!seenUnitTypes.add(order.unitType)) continue;
    final score = militaryCounselScoreBuildUnit(order.unitType);
    if (score <= 0) continue;
    final count = militaryCounselGreedyAffordableBuildCount(
      player: player,
      template: order,
      currentOrders: currentOrders,
    );
    if (count <= 0) continue;
    candidates.add(
      MilitaryCounselRecommendation(
        recommendationId: _stableTrainId(order.unitType),
        kind: MilitaryCounselRecommendationKind.trainUnit,
        rankScore: score,
        briefReasonKey: MilitaryCounselReasonKey.affordableTrain,
        detailReasonKeys: const [MilitaryCounselReasonKey.affordableTrain],
        isHighlight: false,
        unitType: order.unitType,
        count: count,
        costSnapshot: militaryCounselBuildCostSnapshotFor(order.unitType),
      ),
    );
  }

  final ownedProvinceIds = armyMovePlayerOwnedProvinceIds(
    game: game,
    playerId: playerId,
    view: view,
  );
  for (final army in game.worldState.armies) {
    if (army.ownerId != playerId) continue;
    if (army.isHomeArmy) continue;

    final destinations = armyMovePickerDestinations(
      game: game,
      topology: topology,
      playerId: playerId,
      army: army,
      currentOrders: currentOrders,
      playerOwnedFullProvinceIds: ownedProvinceIds,
      sharedCandidateValidator: sharedValidator,
    );
    for (final destination in destinations) {
      if (destination.isPlayerOwned) continue;
      final ownerId = destination.ownerFactionId == '__unowned__'
          ? ''
          : destination.ownerFactionId;
      final score = militaryCounselScoreInvade(
        game: game,
        playerId: playerId,
        ownerFactionId: ownerId,
      );
      if (score <= 0) continue;
      final reason = militaryCounselReasonForInvade(
        game: game,
        playerId: playerId,
        ownerFactionId: ownerId,
        requiresDeclareWar: destination.requiresDeclareWarOnConfirm,
      );
      candidates.add(
        MilitaryCounselRecommendation(
          recommendationId: _stableInvadeId(
            army.id,
            destination.fullProvinceId,
          ),
          kind: MilitaryCounselRecommendationKind.invade,
          rankScore: score,
          briefReasonKey: reason,
          detailReasonKeys: [reason],
          isHighlight: false,
          armyId: army.id,
          destinationProvinceId: destination.fullProvinceId,
          destinationProvinceLabel: destination.provinceLabel,
          ownerFactionId: ownerId,
          requiresDeclareWar: destination.requiresDeclareWarOnConfirm,
          invasionIntel: militaryCounselInvasionIntelSummary(
            game: game,
            view: view,
            playerId: playerId,
            destinationProvinceId: destination.fullProvinceId,
          ),
        ),
      );
    }
  }

  candidates.sort((a, b) {
    final scoreCmp = b.rankScore.compareTo(a.rankScore);
    if (scoreCmp != 0) return scoreCmp;
    final kindCmp =
        _kindPrecedence(a.kind).compareTo(_kindPrecedence(b.kind));
    if (kindCmp != 0) return kindCmp;
    return a.recommendationId.compareTo(b.recommendationId);
  });

  final capped = candidates.length <= _kMaxRecommendations
      ? candidates
      : candidates.sublist(0, _kMaxRecommendations);
  return [
    for (final candidate in capped)
      MilitaryCounselRecommendation(
        recommendationId: candidate.recommendationId,
        kind: candidate.kind,
        rankScore: candidate.rankScore,
        briefReasonKey: candidate.briefReasonKey,
        detailReasonKeys: candidate.detailReasonKeys,
        isHighlight: true,
        unitType: candidate.unitType,
        count: candidate.count,
        costSnapshot: candidate.costSnapshot,
        armyId: candidate.armyId,
        destinationProvinceId: candidate.destinationProvinceId,
        destinationProvinceLabel: candidate.destinationProvinceLabel,
        ownerFactionId: candidate.ownerFactionId,
        requiresDeclareWar: candidate.requiresDeclareWar,
        invasionIntel: candidate.invasionIntel,
      ),
  ];
}
