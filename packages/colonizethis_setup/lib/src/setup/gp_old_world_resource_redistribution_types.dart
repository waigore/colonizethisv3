// SPEC/game/tile-map-and-generation.md; SPEC/program/game-setup-pipeline.md (§7d.redist).
// Shared types/constants for GP OW resource redistribution (Refs #4086 Slice B).

import 'package:colonizethis_data/colonizethis_data.dart';

import 'setup_exceptions.dart';

/// Salt for `Object.hash` when building per-resource shuffle RNGs.
/// ASCII "REDO" packed (issue #1837 / SPEC/program/game-setup-pipeline.md).
const int kGpOwResourceRedistributionSalt = 0x5245444f;

/// Thrown when a resource cannot be placed back on GP Old World tiles after spillover.
class GpOldWorldResourceRedistributionInfeasibleException
    extends SetupConfigConstraintException {
  static const codeValue = 'gp_ow_resource_redistribution_infeasible';

  GpOldWorldResourceRedistributionInfeasibleException({
    required Resource resource,
    required String details,
  }) : super(code: codeValue, details: 'resource=${resource.name}: $details');
}
