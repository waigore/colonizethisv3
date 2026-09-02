/// Same-turn expanded staged-decree snapshot for `DLG60001` re-open.
/// SPEC: SPEC/ui/next-turn-confirmation.md § Open-path performance (Refs #4715).
library;

import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Caches the expanded [StagedDecreeReview] for a stable [Orders] identity so
/// **Review decrees** does not rebuild row copy on every confirm re-open.
class StagedDecreeReviewSessionCache {
  StagedDecreeReviewSessionCache._();

  static StagedDecreeReview? _expanded;
  static Object? _ordersIdentity;

  static StagedDecreeReview? readExpandedFor(Orders orders) {
    if (identical(orders, _ordersIdentity)) {
      return _expanded;
    }
    return null;
  }

  static void storeExpanded({
    required Orders orders,
    required StagedDecreeReview expanded,
  }) {
    _ordersIdentity = orders;
    _expanded = expanded;
  }

  static void clear() {
    _ordersIdentity = null;
    _expanded = null;
  }
}
