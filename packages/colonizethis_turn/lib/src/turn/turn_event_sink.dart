import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Bundles the turn-resolution event transport behind a single value type.
///
/// Wraps the `(GameEventBus? eventBus, void Function(GameEvent)? onGameEvent,
/// void Function(DialogueEvent)? onDialogue)` trio that was previously threaded
/// positionally through the resolver, every emitter, and the phase handlers.
/// Emitters and phase handlers now depend on one sink and the `deliverGameEvent`
/// /dialogue dispatch is centralized here, so adding or altering a transport
/// channel no longer ripples through every emitter signature. Refs #3701,
/// `SPEC/program/game-events.md`.
class TurnEventSink {
  const TurnEventSink({this.eventBus, this.onGameEvent, this.onDialogue});

  final GameEventBus? eventBus;
  final void Function(GameEvent)? onGameEvent;
  final void Function(DialogueEvent)? onDialogue;

  /// Whether a dialogue consumer is attached. Emitters check this before
  /// building dialogue payloads so the per-entity hot loops keep their prior
  /// `onDialogue == null` short-circuit and do no dialogue work when unused.
  bool get hasDialogue => onDialogue != null;

  /// Whether a game-event callback is attached. Preserves the prior
  /// `onGameEvent != null` guard used where building the event itself is the
  /// only cost worth skipping (e.g. the combat-result emission).
  bool get hasGameEvent => onGameEvent != null;

  /// Delivers [event] via the shared [deliverGameEvent] transport: publishes to
  /// [eventBus] (or the default logger when absent) and invokes [onGameEvent].
  void emit(GameEvent event) =>
      deliverGameEvent(event, eventBus: eventBus, onGameEvent: onGameEvent);

  /// Forwards [event] to the dialogue callback when one is attached.
  void dialogue(DialogueEvent event) => onDialogue?.call(event);
}
