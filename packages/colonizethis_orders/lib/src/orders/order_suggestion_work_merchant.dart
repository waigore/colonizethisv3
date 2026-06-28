import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'incremental_candidate_validator.dart';
import 'order_suggestion_context.dart';
import 'order_work_constants.dart';
import 'work_suggestion_pipeline.dart';

void addMerchantSuggestionsForUnit({
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
