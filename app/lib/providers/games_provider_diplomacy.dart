import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart' show CallToArmsPending, FtpOffer, InterventionPrompt, OvertureOffer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// At most one blocking diplomacy gate from turn resolution (overture, intervention, CTA).
/// SPEC/ui/pending-diplomacy-state.md, SPEC/program/dialogue-system.md.
sealed class PendingDiplomacyState {
  const PendingDiplomacyState();
}

final class PendingDiplomacyOvertures extends PendingDiplomacyState {
  const PendingDiplomacyOvertures(this.offers);
  final List<OvertureOffer> offers;
}

final class PendingDiplomacyIntervention extends PendingDiplomacyState {
  const PendingDiplomacyIntervention(this.prompts);
  final List<InterventionPrompt> prompts;
}

final class PendingDiplomacyCallToArms extends PendingDiplomacyState {
  const PendingDiplomacyCallToArms(this.pending);
  final List<CallToArmsPending> pending;
}

final class PendingDiplomacyFtp extends PendingDiplomacyState {
  const PendingDiplomacyFtp(this.offers);
  final List<FtpOffer> offers;
}

class PendingDiplomacyNotifier extends Notifier<PendingDiplomacyState?> {
  PendingDiplomacyNotifier([this._initial]);

  final PendingDiplomacyState? _initial;

  @override
  PendingDiplomacyState? build() => _initial;

  void setOvertures(List<OvertureOffer> offers) {
    state = PendingDiplomacyOvertures(offers);
  }

  void setIntervention(List<InterventionPrompt> prompts) {
    state = PendingDiplomacyIntervention(prompts);
  }

  void setCallToArms(List<CallToArmsPending> pending) {
    state = PendingDiplomacyCallToArms(pending);
  }

  void setFtp(List<FtpOffer> offers) {
    state = PendingDiplomacyFtp(offers);
  }

  void clear() {
    state = null;
  }
}

final pendingDiplomacyProvider =
    NotifierProvider<PendingDiplomacyNotifier, PendingDiplomacyState?>(
      PendingDiplomacyNotifier.new,
    );

/// Payload for one tribe first-contact herald (OVL80001).
class TribeFirstContactHeraldPayload {
  const TribeFirstContactHeraldPayload({
    required this.tribeId,
    required this.tribeName,
    required this.capitalName,
  });

  final String tribeId;
  final String tribeName;
  final String capitalName;
}

/// Herald keys `"$gameId|$tribeId"` already shown this session (OVL80001).
class TribeFirstContactHeraldsShownNotifier extends Notifier<Set<String>> {
  TribeFirstContactHeraldsShownNotifier([this._initial = const <String>{}]);

  final Set<String> _initial;

  @override
  Set<String> build() => _initial;

  bool isShown(String gameId, String tribeId) =>
      state.contains('$gameId|$tribeId');

  void markShown(String gameId, String tribeId) {
    state = {...state, '$gameId|$tribeId'};
  }

  void clear() {
    state = <String>{};
  }
}

final tribeFirstContactHeraldsShownProvider =
    NotifierProvider<TribeFirstContactHeraldsShownNotifier, Set<String>>(
      TribeFirstContactHeraldsShownNotifier.new,
    );

/// FIFO queue of tribe first-contact heralds pending presentation.
class TribeFirstContactHeraldQueueNotifier
    extends Notifier<List<TribeFirstContactHeraldPayload>> {
  TribeFirstContactHeraldQueueNotifier([this._initial = const []]);

  final List<TribeFirstContactHeraldPayload> _initial;

  @override
  List<TribeFirstContactHeraldPayload> build() => List.of(_initial);

  void enqueue(TribeFirstContactHeraldPayload payload) {
    if (state.any((p) => p.tribeId == payload.tribeId)) return;
    state = [...state, payload];
  }

  void dequeueHead() {
    if (state.isEmpty) return;
    state = state.sublist(1);
  }

  void clear() {
    state = const [];
  }
}

final tribeFirstContactHeraldQueueProvider =
    NotifierProvider<
      TribeFirstContactHeraldQueueNotifier,
      List<TribeFirstContactHeraldPayload>
    >(TribeFirstContactHeraldQueueNotifier.new);
