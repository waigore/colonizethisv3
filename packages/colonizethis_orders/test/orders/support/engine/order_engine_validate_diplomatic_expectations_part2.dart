part of 'order_engine_validate_diplomatic_expectations.dart';

void _secondGrantAidTowardSameTargetRejected() {
  vedExpectGrantAidRejectedAfterPrior(prior: vedGrantAid(1000));
}

void _declarewarThenGrantAidTowardSameTargetRejected() {
  vedExpectGrantAidRejectedAfterPrior(prior: vedDeclareWarMinor);
}
