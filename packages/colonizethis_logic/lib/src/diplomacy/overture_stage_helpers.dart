import 'package:colonizethis_models/colonizethis_models.dart';

/// Co-located forward/backward state-machine helpers for [OvertureStage].
///
/// Forward progression: none -> tradeConsulate -> embassy -> nap -> joinEmpire
///   -> null (no further stage).
/// Backward progression: joinEmpire -> nap -> embassy -> tradeConsulate ->
///   none (and `none` stays `none`).
///
/// Keeps the two halves of the same state machine in one place so a fix to one
/// direction cannot drift from the other. Refs SPEC/program/diplomacy-resolution.md.
extension OvertureStageProgression on OvertureStage {
  /// Next stage in the overture chain, or `null` if already terminal.
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

  /// Previous stage in the overture chain. `none` stays `none`.
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

/// Top-level shim preserved for existing callers; delegates to the extension.
OvertureStage? nextOvertureStage(OvertureStage current) => current.next;

/// Top-level shim preserved for existing callers; delegates to the extension.
OvertureStage previousStage(OvertureStage stage) => stage.previous;
