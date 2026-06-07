import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_resolver.dart';
import 'package:colonizethis_world/src/world/naval.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/world/topology_helpers.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_context.dart';
import 'order_suggestion_helpers.dart';

// Naval and diplomatic order-suggestion families share this library's imports
// and the private [_effectiveOrderResolutionContext] helper below. The naval
// move/mission suggesters live in the `_naval` part fragment and the
// diplomatic / declare-war suggesters in the `_diplomatic` part fragment
// (Refs #3290 Phase 0 file decomposition). Both `part of` fragments share this
// library's import set and private scope, so the move is behaviour-preserving —
// symbols, visibility, and helper sharing are unchanged.
part 'order_suggestion_naval.dart';
part 'order_suggestion_diplomatic.dart';

OrderResolutionContext _effectiveOrderResolutionContext({
  required PlayerView view,
  required Game game,
  OrderResolutionContext? resolution,
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  if (resolution != null) return resolution;
  if (sharedCandidateValidator != null) {
    return (
      view: sharedCandidateValidator.view,
      unitsById: sharedCandidateValidator.unitsById,
      provinceById: sharedCandidateValidator.view.provincesById,
    );
  }
  return orderResolutionContextFromView(view, game);
}
