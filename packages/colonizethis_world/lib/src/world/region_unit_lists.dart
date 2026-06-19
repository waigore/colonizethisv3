import 'package:colonizethis_models/colonizethis_models.dart' show Unit;

import '../world_constants.dart';

/// A pair of per-region working unit lists: [ow] for [kRegionOldWorld] and
/// [nw] for [kRegionNewWorld].
///
/// Shared across the civilian-movement and army-migration helpers so both
/// staging pipelines use one canonical `(ow, nw)` record type instead of
/// re-declaring an ad-hoc inline record (and divergent field names such as
/// `owUnits`/`nwUnits`) in each helper (Refs #3403 Phase 3).
typedef RegionUnitLists = ({List<Unit> ow, List<Unit> nw});

extension RegionUnitListsAccess on RegionUnitLists {
  /// Returns the working unit list for [regionId]: [ow] for [kRegionOldWorld],
  /// otherwise [nw]. Replaces the repeated `regionId == kRegionOldWorld ? ow :
  /// nw` region-dispatch ternary across movement/migration helpers (Refs #3544).
  List<Unit> unitListForRegion(String regionId) =>
      regionId == kRegionOldWorld ? ow : nw;
}
