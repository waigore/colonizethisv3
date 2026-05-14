import 'package:colonizethis_models/colonizethis_models.dart';

/// Forward progression of [OvertureStage] for suggestions (none → … → joinEmpire).
///
/// Co-located with [previousStage] so the overture chain stays single-source
/// (Refs #2391 Pattern 2).
OvertureStage? nextOvertureStage(OvertureStage current) {
  switch (current) {
    case OvertureStage.none:
      return OvertureStage.tradeConsulate;
    case OvertureStage.tradeConsulate:
      return OvertureStage.embassy;
    case OvertureStage.embassy:
      return OvertureStage.nap;
    case OvertureStage.nap:
      return OvertureStage.joinEmpire;
    case OvertureStage.joinEmpire:
      return null;
  }
}

/// Backward step used by turn-resolution overture handling.
///
/// Inverse of [nextOvertureStage] for every stage except [OvertureStage.none],
/// which maps to itself (Refs #2391 Pattern 2).
OvertureStage previousStage(OvertureStage stage) {
  switch (stage) {
    case OvertureStage.tradeConsulate:
      return OvertureStage.none;
    case OvertureStage.embassy:
      return OvertureStage.tradeConsulate;
    case OvertureStage.nap:
      return OvertureStage.embassy;
    case OvertureStage.joinEmpire:
      return OvertureStage.nap;
    case OvertureStage.none:
      return OvertureStage.none;
  }
}
