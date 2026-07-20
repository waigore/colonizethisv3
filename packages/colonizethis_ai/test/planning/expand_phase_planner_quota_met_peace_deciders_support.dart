// Shared fixtures for `expand_phase_planner_quota_met_peace_deciders_*` pins.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String quotaMetPeaceGpOwn = 'gp_own';
const String quotaMetPeaceGpPartner = 'gp_partner';
const String quotaMetPeaceGpThird = 'gp_third';
const String quotaMetPeaceGpFourth = 'gp_fourth';
const String quotaMetPeaceMinor1 = 'minor1';

/// Builds a minimal `Game` whose OW region contains per-faction province
/// rows matching [provincesByOwner]. Each entry becomes that many
/// `oldWorld|<owner>_<i>` provinces; ownership is the only signal the
/// helpers read via `provinceCountOwnedBy`.
///
/// The optional [extraInvadableMinorOwnerId] adds a single
/// `oldWorld|invadable_minor` row owned by that minor so the
/// `quotaMetFutileBelowQuotaGpPeaceTargets` blocker check can resolve to a
/// non-GP owner if needed.
Game buildQuotaMetPeaceDecidersGame({
  required Map<String, int> provincesByOwner,
  required List<Player> players,
  List<MinorNation> minorNations = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
  String? extraInvadableMinorOwnerId,
}) {
  final provinces = <Province>[];
  provincesByOwner.forEach((owner, count) {
    for (var i = 0; i < count; i++) {
      provinces.add(
        Province(
          id: 'oldWorld|${owner}_$i',
          regionId: 'oldWorld',
          ownerId: owner,
        ),
      );
    }
  });
  if (extraInvadableMinorOwnerId != null) {
    provinces.add(
      Province(
        id: 'oldWorld|invadable_minor',
        regionId: 'oldWorld',
        ownerId: extraInvadableMinorOwnerId,
      ),
    );
  }
  return Game(
    id: 'g-2509-quota-met-peace-deciders-canonical',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
      oldWorld: RegionData(provinces: provinces, units: const []),
      newWorld: const RegionData(provinces: [], units: []),
    ),
    players: players,
    minorNations: minorNations,
    diplomacyRelations: diplomacyRelations,
  );
}

AIWorldSnapshot quotaMetPeaceDecidersFocusSnapshot({
  required int focusOw,
  required List<String> atWarWith,
  List<String> invadableProvinceIdsSorted = const [],
}) {
  return AIWorldSnapshot(
    playerId: quotaMetPeaceGpOwn,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: focusOw,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}
