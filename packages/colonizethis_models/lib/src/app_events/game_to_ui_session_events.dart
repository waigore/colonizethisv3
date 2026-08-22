/// Session lifecycle Game-to-UI bridge events (Refs #4334 wave 3).

import '../turn_news_digest.dart';
import 'game_to_ui_event_base.dart';

/// Emitted when turn resolution completes; UI may refresh panels.
class TurnResolutionCompleteEvent extends GameToUIEvent {
  const TurnResolutionCompleteEvent({
    required this.gameId,
    required this.turnNumber,
    this.turnNewsDigest,
  });
  final String gameId;
  final int turnNumber;

  /// Prior-turn digest for the news dialog; null when victory was set this resolution.
  final TurnNewsDigest? turnNewsDigest;
}

/// Emitted when overture decisions are required; UI should show overture dialog.
class OvertureRequiredEvent extends GameToUIEvent {
  const OvertureRequiredEvent({required this.overtures});
  final List<Object> overtures; // OvertureOffer
}

/// Emitted when intervention choices are required (Diplomacy phase).
class InterventionRequiredEvent extends GameToUIEvent {
  const InterventionRequiredEvent({required this.prompts});
  final List<Object> prompts; // InterventionPrompt from colonizethis_logic
}

/// Emitted when human ally must accept or refuse call to arms after a GP war declaration.
class CallToArmsRequiredEvent extends GameToUIEvent {
  const CallToArmsRequiredEvent({required this.pending});

  /// [CallToArmsPending] from colonizethis_logic (kept as Object to avoid package cycle).
  final List<Object> pending;
}

/// Emitted when Favored Trading Partner offers need a human Accept/Reject.
class FtpRequiredEvent extends GameToUIEvent {
  const FtpRequiredEvent({required this.offers});

  /// [FtpOffer] from colonizethis_diplomacy (kept as Object to avoid package cycle).
  final List<Object> offers;
}

/// Emitted when save/load completes.
class SaveGameCompleteEvent extends GameToUIEvent {
  const SaveGameCompleteEvent({required this.gameId});
  final String gameId;
}

/// Emitted when a new game is created.
class NewGameCreatedEvent extends GameToUIEvent {
  const NewGameCreatedEvent({required this.gameId});
  final String gameId;
}
