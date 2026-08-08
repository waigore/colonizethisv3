// Shared fixtures for default-start / near-quota peace pins (Refs #4291 Slice D).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

const String defaultStartPeaceGpOwn = 'gp_own';
const String defaultStartPeaceGpA = 'gp_a';
const String defaultStartPeaceGpB = 'gp_b';
const String defaultStartPeaceGpC = 'gp_c';
const String defaultStartPeaceMinorM1 = 'minor_m1';
const String defaultStartPeaceMinorM2 = 'minor_m2';
const String defaultStartPeaceTribeT1 = 'tribe_t1';

AIWorldSnapshot defaultStartPeaceSnapshot({
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
  List<String> invadableProvinceIdsSorted = const [],
}) {
  return AIWorldSnapshot(
    playerId: defaultStartPeaceGpOwn,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}
