import 'work_tile_candidate_index_prefilters.dart';
import 'work_tile_candidate_index_types.dart';

// Shared work-tile candidacy index (Refs #3877 AC4).
// Spec: SPEC/program/order-suggestions.md § Pre-filtering by work target type.

export 'work_tile_candidate_index_types.dart'
    show WorkTileCandidateIndex, WorkTilePrefilterSession;

extension WorkTileCandidateIndexPrefilter on WorkTileCandidateIndex {
  /// Returns raw candidate tile keys for [workTarget] before visibility or
  /// order-engine validation.
  Set<String> candidateTilesForWorkTarget(
    String workTarget, {
    Set<String>? exploreProvinceScope,
  }) {
    final result = <String>{};
    final session = WorkTilePrefilterSession(
      index: this,
      exploreProvinceScope: exploreProvinceScope,
      result: result,
    );
    final op = workTargetPrefilters[workTarget];
    if (op != null) {
      op(session);
    } else {
      prefilterWorkTargetDefault(session);
    }
    return result;
  }
}
