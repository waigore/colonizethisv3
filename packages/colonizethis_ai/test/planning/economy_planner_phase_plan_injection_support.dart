// Shared constants for `economy_planner_phase_plan_injection_test.dart`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/ai_api.dart';

import '../support/economy_satellite_test_support.dart';

const String economyPhasePlanNationId = economyBrokeAtPeaceNationId;
const String economyPhasePlanOwInvadableMinorProvince = 'oldWorld|minor1';

const AIWorldSnapshot economyPhasePlanExpandTrapSnapshot = AIWorldSnapshot(
  playerId: economyPhasePlanNationId,
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: 8,
    invadableProvinceIdsSorted: [economyPhasePlanOwInvadableMinorProvince],
  ),
  colonial: ColonialSummary(),
  economy: EconomySummary(),
  relations: {},
);

const AIConfig economyPhasePlanNapoleonConfig = AIConfig(
  leaderId: 'napoleon',
  personalityId: 'napoleon',
  hiddenAgendaId: 'warmonger',
);

int economyPhasePlanCargoLevel(CargoPreference p) =>
    p == CargoPreference.strongCargo
        ? 2
        : p == CargoPreference.preferCargo
        ? 1
        : 0;
