// Keep feedstock_common unpublished. Re-exporting it would put
// `regimentCountForPlayer` on the orders barrel, colliding with the AI
// planner helper of the same name when tests import both
// `colonizethis_logic` and `army_conquest_prep.dart` (Refs #4508).
export 'feedstock_extraction_gate_shared.dart' show isBelowQuotaZeroNwSeller;
export 'feedstock_seller_extraction_targets.dart';
export 'feedstock_supplier_extraction_targets.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'feedstock_seller_extraction_targets.dart';
import 'feedstock_supplier_extraction_targets.dart';

// Feedstock-extraction resource-id gates for the below-quota zero-NW
// lock-recovery seller / supplier roles (Refs #2847 § H8-extraction).
//
// Seller and supplier gates live in dedicated libraries; this barrel keeps
// stable imports for `order_suggestion_work_worker.dart` and bootstrap cost.

/// Union of the seller-side feedstock gates and the supplier-side gate for
/// [playerId] (Refs #2847 § H8-extraction).
Set<String> feedstockExtractionResourceIdsForPlayer(
  Game game,
  String playerId,
) {
  return <String>{
    ...regimentBuildInputFeedstockExtractionResourceIds(game, playerId),
    ...sellerImprovementInputFeedstockExtractionResourceIds(game, playerId),
    ...supplierImprovementInputFeedstockExtractionResourceIds(game, playerId),
  };
}
