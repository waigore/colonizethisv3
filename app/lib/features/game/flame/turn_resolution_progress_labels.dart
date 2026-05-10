import 'package:flutter/scheduler.dart';

/// User-visible labels for [TurnResolutionRunner] progress `phase` ids (worker
/// isolate + resolver). Refs #2277.
String turnResolutionProgressPhaseLabel(String phase) {
  return switch (phase) {
    'aiPlanning' => 'Planning AI orders...',
    'orders' => 'Validating orders...',
    'extraction' => 'Resolving extraction...',
    'richesToTreasury' => 'Moving riches to treasury...',
    'consumption' => 'Resolving consumption...',
    'production' => 'Resolving production...',
    'research' => 'Resolving research...',
    'diplomacy' => 'Resolving diplomacy...',
    'movement' => 'Resolving movement...',
    'minorRegimentUpgrade' => 'Upgrading minor regiments...',
    'navalInterceptionCombat' => 'Resolving naval interceptions...',
    'combat' => 'Resolving combat...',
    'buildWork' => 'Resolving work orders...',
    'endOfTurn' => 'Finalizing turn...',
    _ => 'Resolving turn...',
  };
}

/// After scheduling [TurnResolutionProcessingDialog] (non-awaited
/// [showDialog]), waits until the next frame is presented so the modal can
/// paint before [TurnResolutionRunner.startResolution] runs main-isolate work
/// (spawn payload serialization). Refs #2277.
Future<void> awaitTurnResolutionProcessingDialogFirstPaint() async {
  await SchedulerBinding.instance.endOfFrame;
}
