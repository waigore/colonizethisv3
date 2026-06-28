import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'incremental_candidate_validator.dart';
import 'order_suggestion_context.dart';
import 'order_work_constants.dart';
import 'work_suggestion_pipeline.dart';

void addSpySuggestionsForUnit({
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required String playerId,
  required Unit unit,
  required String type,
  required String unitRegionId,
  required String atProvinceId,
  required String? ownerId,
  required List<String> tilesInProvince,
  required Map<String, Set<String>> existingTargetsByUnit,
  required List<WorkOrder> suggestions,
  required IncrementalCandidateValidator candidateValidator,
  required WorkSuggestionProbeBudget workProbeBudget,
}) {
  final allowedTargets = workOrderTargetsByUnitType[type];
  if (allowedTargets == null) return;

  _addCounterSpySuggestionIfEligible(
    allowedTargets: allowedTargets,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    playerId: playerId,
    unit: unit,
    type: type,
    unitRegionId: unitRegionId,
    atProvinceId: atProvinceId,
    ownerId: ownerId,
    tilesInProvince: tilesInProvince,
    existingTargetsByUnit: existingTargetsByUnit,
    suggestions: suggestions,
    candidateValidator: candidateValidator,
    workProbeBudget: workProbeBudget,
  );

  if (!allowedTargets.contains(kWorkTargetStealTech)) return;
  WorkSuggestionPipeline.run(
    unit: unit,
    unitType: type,
    unitRegionId: unitRegionId,
    atProvinceId: atProvinceId,
    workTarget: kWorkTargetStealTech,
    existingTargetsByUnit: existingTargetsByUnit,
    suggestions: suggestions,
    noCandidateReason: 'no_valid_tile',
    candidatesProvider: () sync* {
      for (final other in game.players) {
        if (other.id == playerId || other.capitalProvinceId == null) continue;
        final capProvinceId = other.capitalProvinceId!;
        final capRegionId = ProvinceId.regionIdFrom(capProvinceId);
        final capTiles =
            tileKeysByRegion[capRegionId]?[capProvinceId] ?? const <String>[];
        if (capTiles.isEmpty) continue;
        yield WorkOrder(
          unitId: unit.id,
          target: kWorkTargetStealTech,
          targetTileKey: capTiles.first,
        );
      }
    },
    candidateAcceptor: (candidate) =>
        isWorkOrderAcceptedWithValidator(candidateValidator, candidate),
    probeBudget: workProbeBudget,
  );
}

void _addCounterSpySuggestionIfEligible({
  required List<String> allowedTargets,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required String type,
  required String unitRegionId,
  required String atProvinceId,
  required String? ownerId,
  required List<String> tilesInProvince,
  required Map<String, Set<String>> existingTargetsByUnit,
  required List<WorkOrder> suggestions,
  required IncrementalCandidateValidator candidateValidator,
  required WorkSuggestionProbeBudget workProbeBudget,
}) {
  if (!allowedTargets.contains(kWorkTargetCounterSpy)) return;
  if (ownerId != playerId) {
    logWorkOrderSuggestion(
      unitId: unit.id,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: kWorkTargetCounterSpy,
      outcome: 'excluded',
      reason: 'not_applicable',
    );
    return;
  }

  WorkSuggestionPipeline.run(
    unit: unit,
    unitType: type,
    unitRegionId: unitRegionId,
    atProvinceId: atProvinceId,
    workTarget: kWorkTargetCounterSpy,
    existingTargetsByUnit: existingTargetsByUnit,
    suggestions: suggestions,
    noCandidateReason: 'no_valid_tile',
    candidatesProvider: () sync* {
      if (tilesInProvince.isEmpty) return;
      yield WorkOrder(
        unitId: unit.id,
        target: kWorkTargetCounterSpy,
        targetTileKey: tilesInProvince.first,
      );
    },
    candidateAcceptor: (candidate) =>
        isWorkOrderAcceptedWithValidator(candidateValidator, candidate),
    probeBudget: workProbeBudget,
  );
}
