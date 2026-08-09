/// Observe-mode session commands (Refs #4136 Slice B).

import 'session_command_event_base.dart';

/// Exit in-app observe mode. SPEC/ui/observe-mode.md.
class SetObserveModeOffEvent extends SessionCommandEvent {
  const SetObserveModeOffEvent();
}

/// Enter global (omniscient) in-app observe mode. SPEC/ui/observe-mode.md.
class SetObserveModeGlobalEvent extends SessionCommandEvent {
  const SetObserveModeGlobalEvent();
}

/// Enter player-scoped in-app observe mode for [targetPlayerId].
class SetObserveModePlayerEvent extends SessionCommandEvent {
  const SetObserveModePlayerEvent({required this.targetPlayerId});

  final String targetPlayerId;
}
