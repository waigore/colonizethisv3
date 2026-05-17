import 'package:colonizethis_models/colonizethis_models.dart';

import '../../order_validation_result.dart';

/// Per-`DiplomaticOrderType` validator extracted from
/// [DiplomaticOrderValidator] (SPEC/program/orders.md § Diplomatic orders).
///
/// Sub-validators only own the **type-specific** rules for one
/// [DiplomaticOrderType]. Cross-cutting checks that apply to every diplomatic
/// order — target existence, self-targeting, the per-target diplomatic-order
/// cap, and recording the accepted (target, type) pair — are owned by the
/// dispatching parent validator and run **before** the sub-validator is
/// invoked.
///
/// Sub-validators are pure with respect to game state: they read [game] and
/// the supplied current [treasury] and return an [OrderValidationResult]
/// together with the **post-validation treasury**. Sub-validators that do
/// not change treasury (declare war, offer peace, alliance) return [treasury]
/// unchanged. Sub-validators that consume treasury (overtures, grant aid,
/// set subsidy) return the debited treasury **only on accept**; on reject
/// they return the input [treasury] unchanged so the caller can commit the
/// new value unconditionally.
abstract interface class DiplomaticSubValidator {
  /// Validate the type-specific portion of [order]. Caller is responsible
  /// for the cross-cutting target/self/cap checks before calling this.
  ({OrderValidationResult result, int treasury}) validate({
    required DiplomaticOrder order,
    required int treasury,
  });
}

/// Helper for sub-validator implementations: builds a rejected result that
/// preserves the input treasury value (no debit on reject).
({OrderValidationResult result, int treasury}) rejectDiplomaticSub(
  String reason,
  int treasury,
) => (result: OrderValidationResult.rejected(reason), treasury: treasury);

/// Helper for sub-validator implementations: builds an accepted result with
/// the supplied (possibly debited) treasury value.
({OrderValidationResult result, int treasury}) acceptDiplomaticSub(
  int treasury,
) => (result: OrderValidationResult.accepted(), treasury: treasury);
