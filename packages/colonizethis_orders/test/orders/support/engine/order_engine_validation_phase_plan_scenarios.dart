// Table-driven orderValidationPhasePlan scenarios (Refs #3949 wave 3).

import 'package:colonizethis_orders/src/orders/order_engine_validation.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
// dart format off

void oevppRunDeclaresCanonicalPerCategoryPhaseOrder() {expect(orderValidationPhasePlan.map((p) => p.name).toList(),<String>['move','army-move','recruit-worker','build','work','diplomatic','naval','trade',]);}

void oevppRunPhaseNamesAreUnique() {final names = orderValidationPhasePlan.map((p) => p.name).toList(); expect(names.toSet().length,names.length,reason: 'duplicate phase name in $names',);}

void oevppRunMoveArmyMoveShareInitialBundleResourcePhasesRefreshTradeReuses() {final refreshByName = <String,bool>{for (final p in orderValidationPhasePlan) p.name: p.refreshBundleBefore,}; expect(refreshByName['move'],isFalse); expect(refreshByName['army-move'],isFalse); for (final name in const ['recruit-worker','build','work','diplomatic','naval',]) {expect(refreshByName[name],isTrue,reason: '$name must refresh the validator bundle',); } expect(refreshByName['trade'],isFalse);}

/// Canonical scenarios for order_engine_validation_phase_plan family tests.
List<RunnableScenario> orderEngineValidationPhasePlanScenarios() => [
  rs('declares the canonical per-category phase order', oevppRunDeclaresCanonicalPerCategoryPhaseOrder, '#3543 AC2'),
  rs('phase names are unique (no category runs twice)', oevppRunPhaseNamesAreUnique, '#3543 AC2'),
  rs('move + army-move share the initial bundle; resource/diplomatic/naval phases refresh; trade reuses the advanced bundle', oevppRunMoveArmyMoveShareInitialBundleResourcePhasesRefreshTradeReuses, '#2391 AC7'),
];
