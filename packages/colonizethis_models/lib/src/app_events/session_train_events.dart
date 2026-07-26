/// Train-dialog commit session commands (Refs #4136 Slice B).

import '../orders.dart';
import 'session_command_event_base.dart';

/// Train civilians dialog close: shell merges into current-turn orders draft.
class TrainCivilianBuildOrdersCommittedEvent extends SessionCommandEvent {
  TrainCivilianBuildOrdersCommittedEvent({required this.orders});

  final List<BuildUnitOrder> orders;
}

/// Train military dialog close: shell merges into current-turn orders draft.
class TrainMilitaryBuildOrdersCommittedEvent extends SessionCommandEvent {
  TrainMilitaryBuildOrdersCommittedEvent({required this.orders});

  final List<BuildUnitOrder> orders;
}

/// Train naval dialog close: shell merges into current-turn orders draft.
///
/// Carries naval [BuildUnitOrder]s (`isMilitary: false`, ship unit types
/// spawned at the player's capital). The shell listener replaces only
/// dialog-managed naval build orders, leaving civilian build orders intact.
/// SPEC/ui/train-naval-dialog.md, SPEC/program/app-ui-wiring.md.
class TrainNavalBuildOrdersCommittedEvent extends SessionCommandEvent {
  TrainNavalBuildOrdersCommittedEvent({required this.orders});

  final List<BuildUnitOrder> orders;
}
