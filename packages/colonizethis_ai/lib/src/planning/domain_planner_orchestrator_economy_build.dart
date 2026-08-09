import '../perception/perception_snapshot.dart';
import 'build_planner.dart';
import 'domain_planner_orchestrator_economy_build_gate.dart';
import 'domain_planner_orchestrator_economy_build_support.dart';
import 'planning_imports.dart';

export 'domain_planner_orchestrator_economy_build_support.dart';

final _log = packageLogger('domain_planner_orchestrator_economy_build');

BuildPassResult appendEconomyBuildOrders(EconomyBuildPassInput input) {
  final ctx = input.ctx;
  final snapshot = input.snapshot;
  final economyPlan = input.economyPlan;
  final ordersBuilder = input.ordersBuilder;
  final colonialPressure = input.colonialPressure;
  final civilianScoring = input.civilianScoring;

  final gate = resolveEconomyBuildPassGate(input);
  if (gate.skipWithoutRunning) {
    return BuildPassResult(
      buildPlannerRan: false,
      buildThreshold: gate.buildThreshold,
    );
  }

  final chosen = pickBuildOrder(
    ctx: ctx,
    input: BuildPickInput(
      buildCandidates: gate.candidatesForBuild,
      cargoPreference: economyPlan.cargoPreference,
      provincesToVictory: snapshot.conquest.provincesToVictory,
      oldWorldProvincesOwned: snapshot.conquest.oldWorldProvincesOwned,
      colonialPressure: colonialPressure,
      colonialPressureWeight: gate.colonialPressureWeight,
      civilianScoring: civilianScoring,
      militaryRebuildCrisis:
          !gate.firstNavalTransportBootstrap &&
          (gate.forceRegimentRebuild ||
              gate.expandEconomy.forceCheapestRegimentBuild) &&
          (gate.atWarWithGpBlocker ||
              gate.brokeBelowQuotaAtPeace ||
              gate.belowQuotaZeroRegimentsRebuild ||
              gate.belowQuotaPeaceInsufficientRegiments ||
              gate.expandEconomy.forceCheapestRegimentBuild ||
              (gate.regimentCount <= kStalledMilitaryRebuildCrisisRegimentCap &&
                  !(gate.observerQuotaPressure &&
                      snapshot.conquest.oldWorldProvincesOwned >
                          kFewOldWorldProvincesDefendThreshold))),
    ),
  );
  if (chosen == null) {
    return BuildPassResult(
      buildPlannerRan: true,
      buildThreshold: gate.buildThreshold,
    );
  }
  _log.i('build chosen nationId=${ctx.nationId} unitType=${chosen.unitType}');
  ordersBuilder.appendBuildOrders(ctx.nationId, [chosen]);
  return BuildPassResult(
    buildPlannerRan: true,
    buildThreshold: gate.buildThreshold,
  );
}
