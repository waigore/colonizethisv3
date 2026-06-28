import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'capital_reassignment.dart';
import 'town_capital_tile_strip.dart';
import 'game_world_mutations.dart';
import 'player_state_pipeline.dart';
import 'port_seaboard_registry_key.dart';
import 'province_lookup.dart';
import 'province_owner_cache.dart';
import 'capital_reassignment_fatal.dart';

part 'capital_and_gp_fall_reassignment.dart';
part 'capital_and_gp_fall_terminal.dart';

class CapitalReassignmentEligibility {
  const CapitalReassignmentEligibility({
    required this.eligible,
    required this.reasonCode,
    required this.ownedProvinceIdsInRegion,
    this.candidateProvinceId,
  });

  final bool eligible;
  final String reasonCode;
  final List<String> ownedProvinceIdsInRegion;
  final String? candidateProvinceId;
}

CapitalReassignmentEligibility evaluateCapitalReassignmentEligibility({
  required Game state,
  required String playerId,
  required String regionId,
  required MapTopology regionTopology,
  String? excludedProvinceId,
}) {
  final region = regionDataForId(state.worldState, regionId);
  if (region == null) {
    return const CapitalReassignmentEligibility(
      eligible: false,
      reasonCode: 'region_not_found',
      ownedProvinceIdsInRegion: <String>[],
    );
  }

  // Phase 6b slice 15 (SPEC/program/worldstate-projection.md; Refs #3393):
  // this eligibility check runs per player/minor/tribe each end-of-turn
  // reassignment pass, so the prior `region.provinces.where((p) => p.ownerId
  // == playerId ...)` rescanned the whole region list per falling faction.
  // [ProvinceOwnerCache.provincesOwnedByInRegion] preserves the region's
  // `RegionData.provinces` order, so the remaining `excludedProvinceId`
  // filter yields an identical id list to the prior compound-predicate scan.
  final ownedInRegion = ProvinceOwnerCache.of(state.worldState)
      .provincesOwnedByInRegion(playerId, regionId)
      .where((p) => excludedProvinceId == null || p.id != excludedProvinceId)
      .map((p) => p.id)
      .toList(growable: false);
  if (ownedInRegion.isEmpty) {
    return const CapitalReassignmentEligibility(
      eligible: false,
      reasonCode: 'no_owned_provinces_in_region',
      ownedProvinceIdsInRegion: <String>[],
    );
  }

  final candidateProvinceId = pickCapitalProvinceIdForReassignment(
    ownedInRegion,
    regionTopology,
  );
  return CapitalReassignmentEligibility(
    eligible: true,
    reasonCode: 'eligible',
    ownedProvinceIdsInRegion: ownedInRegion,
    candidateProvinceId: candidateProvinceId,
  );
}
