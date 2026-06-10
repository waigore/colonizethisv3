import 'package:colonizethis_models/colonizethis_models.dart' show Unit;

/// A pair of per-region working unit lists: [ow] for [kRegionOldWorld] and
/// [nw] for [kRegionNewWorld].
///
/// Shared across the civilian-movement and army-migration helpers so both
/// staging pipelines use one canonical `(ow, nw)` record type instead of
/// re-declaring an ad-hoc inline record (and divergent field names such as
/// `owUnits`/`nwUnits`) in each helper (Refs #3403 Phase 3).
typedef RegionUnitLists = ({List<Unit> ow, List<Unit> nw});
