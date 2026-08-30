/// Target-selection UI actions (Refs #4334 wave 3).

import 'ui_action_event_base.dart';

/// Request to start civilian target-selection mode from the units panel.
/// Emit [ClosePanelEvent] first when the civilian units sheet should close.
class StartCivilianWorkTargetSelectionEvent extends UIActionEvent {
  const StartCivilianWorkTargetSelectionEvent({
    required this.unitId,
    required this.workTarget,
  });

  final String unitId;
  final String workTarget;
}

/// Request to start Spy relocate destination selection from the units panel.
/// Emit [ClosePanelEvent] first when the civilian units sheet should close.
class StartCivilianRelocateSelectionEvent extends UIActionEvent {
  const StartCivilianRelocateSelectionEvent({required this.unitId});

  final String unitId;
}

/// Request to start a unit target-selection mode (map enters target-pick state).
class StartTargetSelectionEvent extends UIActionEvent {
  const StartTargetSelectionEvent({
    required this.unitId,
    required this.action,
    this.onComplete,
    this.onCancel,
  });
  final String unitId;
  final String action;
  final void Function(String provinceId)? onComplete;
  final void Function()? onCancel;
}

/// Cancel any active target-selection mode.
class CancelTargetSelectionEvent extends UIActionEvent {
  const CancelTargetSelectionEvent();
}
