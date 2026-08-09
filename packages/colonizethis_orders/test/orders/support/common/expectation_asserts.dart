// Shared unit / stockpile expectation asserts for orders support (Refs #3971).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Expects [result] status and optional reason fields (Refs #4109).
void expectOrderValidationResult(
  OrderValidationResult result, {
  required OrderValidationStatus status,
  String? reasonExact,
  Matcher? reasonContains,
  bool reasonIsNull = false,
}) {
  expect(result.status, status);
  if (reasonExact != null) {
    expect(result.reason, reasonExact);
  }
  if (reasonContains != null) {
    expect(result.reason, reasonContains);
  }
  if (reasonIsNull) {
    expect(result.reason, isNull);
  }
}

/// Expects [unit] idle with cleared work / origin / assignment fields.
void expectUnitIdleCleared(Unit unit, {String? tileKey}) {
  expect(unit.status, UnitStatus.idle);
  expect(unit.currentWork, isNull);
  expect(unit.originTileKey, isNull);
  expect(unit.assignedTileKey, isNull);
  if (tileKey != null) {
    expect(unit.tileKey, tileKey);
  }
}

/// Expects [unit].currentWork matches [workTarget] and optional turn fields.
void expectCurrentWorkFields(
  Unit unit, {
  required String workTarget,
  int? totalTurns,
  int? remainingTurns,
}) {
  expect(unit.currentWork, isNotNull);
  expect(unit.currentWork!.workTarget, workTarget);
  if (totalTurns != null) {
    expect(unit.currentWork!.totalTurns, totalTurns);
  }
  if (remainingTurns != null) {
    expect(unit.currentWork!.remainingTurns, remainingTurns);
  }
}

/// Expects each commodity in [cost] deducted from [before] → [after] stockpile.
void expectStockpileDeducted(
  Game before,
  Game after,
  Map<String, int> cost, {
  required String playerId,
}) {
  for (final e in cost.entries) {
    expect(
      after.playerById(playerId)!.stockpile.quantityOf(e.key),
      before.playerById(playerId)!.stockpile.quantityOf(e.key) - e.value,
    );
  }
}
