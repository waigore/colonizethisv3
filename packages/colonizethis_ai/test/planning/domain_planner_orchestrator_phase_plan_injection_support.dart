// Shared fixtures for phasePlan injection orchestrator pins (Refs #4602).

import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String phasePlanInjectionNationId = kOrchestratorGp1NationId;
const String phasePlanInjectionFieldArmyId = kOrchestratorFieldArmyId;
const String phasePlanInjectionOwMinorProvince = kOrchestratorOwMinorProvince;

// 7 GP-owned OW provinces: well below the observer quota of 10, so the
// natural phase is EXPAND. The conquest army-move planner runs and the
// orchestrator surfaces the fake suggestion below.

// Fake API drives a single conquest army-move candidate so the orchestrator
// output cleanly reflects whether the conquest planner ran (EXPAND) or
// short-circuited (DEVELOP).
const FakeOrderSuggestionAPIForDomainPlannerTests
phasePlanInjectionConquestCandidateApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
      work: [],
      build: [],
      move: [],
      research: [],
      navalMove: [],
      navalMission: [],
      armyMove: [
        ArmyMoveOrder(
          armyId: phasePlanInjectionFieldArmyId,
          destinationProvinceId: phasePlanInjectionOwMinorProvince,
        ),
      ],
    );

const EconomyPlan phasePlanInjectionEconomyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig phasePlanInjectionAiConfig = AIConfig(
  leaderId: 'napoleon',
  personalityId: 'napoleon',
  hiddenAgendaId: 'warmonger',
);
