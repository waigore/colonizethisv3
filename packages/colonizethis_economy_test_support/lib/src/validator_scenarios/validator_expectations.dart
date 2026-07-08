// Compact TradeOrderValidator result assertions (Refs #3939 phase 3 slice 10).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

/// Per-order validation outcome for data-driven validator scenarios.
typedef ValidatorOrderOutcome = ({bool accepted, String? reason});

/// Data-driven expectations for validator scenario rows.
class ValidatorExpectation {
  const ValidatorExpectation({
    this.outcomes,
    this.allAccepted = false,
    this.allRejectedWithReason,
    this.custom,
  });

  final List<ValidatorOrderOutcome>? outcomes;
  final bool allAccepted;
  final String? allRejectedWithReason;
  final void Function(List<OrderValidationResult> results)? custom;
}

void assertValidatorExpectation(
  List<OrderValidationResult> results,
  ValidatorExpectation expectation,
) {
  if (expectation.allAccepted) {
    for (final result in results) {
      expect(result.isAccepted, isTrue, reason: result.reason);
    }
  }
  if (expectation.allRejectedWithReason != null) {
    for (final result in results) {
      expect(result.reason, expectation.allRejectedWithReason);
    }
  }
  if (expectation.outcomes != null) {
    expect(results, hasLength(expectation.outcomes!.length));
    for (var i = 0; i < expectation.outcomes!.length; i++) {
      final expected = expectation.outcomes![i];
      final actual = results[i];
      expect(actual.isAccepted, expected.accepted);
      if (!expected.accepted) {
        expect(actual.reason, expected.reason);
      }
    }
  }
  expectation.custom?.call(results);
}
