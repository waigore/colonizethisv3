part of 'order_suggestion_work.dart';

void _addMerchantSuggestionsForUnit({
  required Unit unit,
  required String type,
  required String unitRegionId,
  required String atProvinceId,
  required Map<String, Set<String>> existingTargetsByUnit,
  required List<String> purchaseLandCandidateTileKeys,
  required List<WorkOrder> suggestions,
  required IncrementalCandidateValidator candidateValidator,
  required WorkSuggestionProbeBudget workProbeBudget,
}) {
  final allowedTargets = workOrderTargetsByUnitType[type];
  if (allowedTargets == null ||
      !allowedTargets.contains(kWorkTargetPurchaseLand)) {
    return;
  }

  WorkSuggestionPipeline.run(
    unit: unit,
    unitType: type,
    unitRegionId: unitRegionId,
    atProvinceId: atProvinceId,
    workTarget: kWorkTargetPurchaseLand,
    existingTargetsByUnit: existingTargetsByUnit,
    suggestions: suggestions,
    noCandidateReason: 'no_valid_tile',
    candidatesProvider: () sync* {
      for (final tk in purchaseLandCandidateTileKeys) {
        yield WorkOrder(
          unitId: unit.id,
          target: kWorkTargetPurchaseLand,
          targetTileKey: tk,
        );
      }
    },
    candidateAcceptor: (candidate) =>
        isWorkOrderAcceptedWithValidator(candidateValidator, candidate),
    probeBudget: workProbeBudget,
  );
}
