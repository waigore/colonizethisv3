part of '../app_events.dart';

// ---------------------------------------------------------------------------
// UISystemEvent — emitted by any layer to request transient system feedback.
// ---------------------------------------------------------------------------

sealed class UISystemEvent extends AppEvent {
  const UISystemEvent();
}

/// Show a snackbar / toast message.
class ShowSnackBarEvent extends UISystemEvent {
  const ShowSnackBarEvent({
    required this.message,
    this.actionLabel,
    this.action,
  });
  final String message;
  final String? actionLabel;
  final void Function()? action;
}

/// Show a transient overlay (e.g. "Combat resolving..." spinner).
class ShowOverlayEvent extends UISystemEvent {
  const ShowOverlayEvent({required this.overlayId, this.params});
  final String overlayId;
  final Map<String, Object?>? params;
}

/// Dismiss the transient overlay.
class DismissOverlayEvent extends UISystemEvent {
  const DismissOverlayEvent(this.overlayId);
  final String overlayId;
}

/// Show a non-blocking notification badge / toast for an event (combat, research, etc.).
/// Unlike SnackBar, this may auto-dismiss and is less intrusive.
class NotifyEvent extends UISystemEvent {
  const NotifyEvent({required this.title, required this.body, this.priority});
  final String title;
  final String body;
  final NotifyPriority? priority;
}

enum NotifyPriority { low, normal, high }
