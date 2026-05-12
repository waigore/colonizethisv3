import 'package:colonizethis_models/colonizethis_models.dart';

/// Co-located forward/backward navigation for the overture chain (Refs #2391 AC1).
extension OvertureStageNavigation on OvertureStage {
  /// Forward progression; `null` when already at [OvertureStage.joinEmpire].
  OvertureStage? get next => switch (this) {
    OvertureStage.none => OvertureStage.tradeConsulate,
    OvertureStage.tradeConsulate => OvertureStage.embassy,
    OvertureStage.embassy => OvertureStage.nap,
    OvertureStage.nap => OvertureStage.joinEmpire,
    OvertureStage.joinEmpire => null,
  };

  /// Reverse progression; [OvertureStage.none] maps to itself.
  OvertureStage get previous => switch (this) {
    OvertureStage.tradeConsulate => OvertureStage.none,
    OvertureStage.embassy => OvertureStage.tradeConsulate,
    OvertureStage.nap => OvertureStage.embassy,
    OvertureStage.joinEmpire => OvertureStage.nap,
    OvertureStage.none => OvertureStage.none,
  };
}
