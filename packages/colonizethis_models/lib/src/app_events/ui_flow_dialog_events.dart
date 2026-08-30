/// Flow-dialog UI actions (Refs #4334 wave 3).

import '../combat_mode.dart';
import 'ui_action_event_base.dart';

/// Emitted when the user chooses auto-resolve or quick battle in [CombatModeChoiceDialog].
class CombatModeChosenEvent extends UIActionEvent {
  const CombatModeChosenEvent(this.mode);

  final CombatMode mode;
}

/// Player choice from the Development panel disconnected-improve warn dialog.
/// SPEC/ui/development-panel.md — disconnected warn dialog.
enum DevelopmentDisconnectedAssignChoice { improveAnyway, roadFirst, cancel }

/// Request the disconnected-improve warn dialog; returns choice via callback.
/// Handled by the shell-level event handler (app layer).
class DevelopmentDisconnectedAssignDialogEvent extends UIActionEvent {
  const DevelopmentDisconnectedAssignDialogEvent({
    required this.roadFirstEnabled,
    this.roadFirstDisabledReason,
    this.assignPreviewLine,
    void Function(DevelopmentDisconnectedAssignChoice)? onResult,
  }) : _onResult = onResult;

  final bool roadFirstEnabled;
  final String? roadFirstDisabledReason;
  final String? assignPreviewLine;
  final void Function(DevelopmentDisconnectedAssignChoice)? _onResult;

  void result(DevelopmentDisconnectedAssignChoice choice) =>
      _onResult?.call(choice);
}

/// Emitted by GrantOrSubsidyDialog when user submits the amount form.
/// Carries the data needed to show a final confirmation dialog.
class GrantOrSubsidySubmittedEvent extends UIActionEvent {
  const GrantOrSubsidySubmittedEvent({
    required this.targetFactionId,
    required this.amount,
    required this.isSubsidy,
  });
  final String targetFactionId;
  final int amount;
  final bool isSubsidy;
}
