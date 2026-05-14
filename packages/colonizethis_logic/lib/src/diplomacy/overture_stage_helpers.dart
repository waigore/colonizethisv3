import 'package:colonizethis_models/colonizethis_models.dart';

/// Chain navigation for [OvertureStage] (Refs #2391 AC1 / Pattern 2).
///
/// Ladder semantics: `SPEC/game/diplomacy.md` (Establish Overture chain);
/// resolution ordering: `SPEC/program/diplomacy-resolution.md`.
extension OvertureStageChain on OvertureStage {
  /// Forward progression for suggestions (none → … → joinEmpire); null at terminal.
  OvertureStage? get next {
    switch (this) {
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

  /// Backward step for resolution; [OvertureStage.none] maps to itself.
  OvertureStage get previous {
    switch (this) {
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
}

/// Forward progression of [OvertureStage] for suggestions (none → … → joinEmpire).
///
/// Co-located with [previousStage] on [OvertureStageChain] (Refs #2391 Pattern 2).
OvertureStage? nextOvertureStage(OvertureStage current) => current.next;

/// Backward step used by turn-resolution overture handling.
///
/// Inverse of [nextOvertureStage] for every stage except [OvertureStage.none],
/// which maps to itself (Refs #2391 Pattern 2).
OvertureStage previousStage(OvertureStage stage) => stage.previous;
