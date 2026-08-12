// Case bodies for `phase_planner_dispatch_test.dart` (Refs #4310 Slice D).
// EXPAND outcome composition.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart'
    show phasePlanFullColonialOutputsActive;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';
import 'ai_planner_fixtures.dart';

const String _minor1 = kColonialPhaseMinor1;

void registerPhasePlannerDispatchExpandCases() {
  group('EXPAND outcome composition', () {
    test('EXPAND populates EXPAND slots and colonial bundle when NW weight > 0 '
        '(Refs #2847)', () {
      final game = buildPhasePlannerDispatchExpandGame();
      final snapshot = buildPhasePlannerDispatchExpandSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);

      // EXPAND fields paired with the per-planner outputs the
      // dispatcher composes. The declare-war target flows into
      // `planExpandMilitary`, so the two plans target the same
      // faction.
      expect(outcome.expandDeclareWarTargetFactionId, _minor1);
      expect(
        outcome.expandPeaceTargetFactionIdsSorted,
        planExpandPeace(game: game, snapshot: snapshot),
      );
      // Distraction-peace slot sources the below-quota tribe distraction
      // decider only (Refs #2847 § H5 — the minor decider stays confined
      // to the no-phasePlan fallback to protect multi-minor conquest).
      expect(
        outcome.expandDistractionPeaceTargetFactionIdsSorted,
        belowQuotaRegimentThinTribeDistractionPeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
      );
      expect(
        outcome.expandEconomyPlan,
        planExpandEconomy(game: game, snapshot: snapshot),
      );
      expect(
        outcome.expandMilitaryPlan,
        planExpandMilitary(
          game: game,
          snapshot: snapshot,
          declaredWarTargetFactionId: _minor1,
        ),
      );
      expect(outcome.priorityWeights.newWorldAcquisition, greaterThan(0.0));
      expect(phasePlanFullColonialOutputsActive(outcome), isTrue);

      final colonial = planColonialAcquisition(game: game, snapshot: snapshot);
      expect(outcome.colonialAcquisitionTarget, colonial);
      expect(
        outcome.colonialPeaceTargetFactionIdsSorted,
        planColonialPeace(game: game, snapshot: snapshot),
      );
      final declaredColonialTarget =
          (colonial != null && colonial.method == AcquisitionMethod.declareWar)
          ? colonial.targetFactionId
          : null;
      expect(
        outcome.colonialMilitaryPlan,
        planColonialMilitary(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: declaredColonialTarget,
        ),
      );
      expect(
        outcome.colonialNavalPlan,
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: declaredColonialTarget,
        ),
      );
      expect(
        outcome.colonialCivilianWorkOrders,
        planColonialCivilian(game: game, snapshot: snapshot),
      );

      // COLONIAL-lite and DEVELOP slots stay default under EXPAND.
      expect(outcome.colonialLiteOverturesSorted, isEmpty);
      expect(outcome.colonialLiteNavalPlan, ColonialLiteNavalPlan.defaultPlan);
      expect(outcome.developPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.developCivilianWorkOrders, isEmpty);
    });
  });
}
