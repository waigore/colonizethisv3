import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_shared_helpers.dart';

Game cleanupAfterMinorOrTribeAbsorb(Game next, String absorbedFactionId) {
  var minorNations = next.minorNations;
  var tribes = next.tribes;
  if (next.minorNations.any((m) => m.id == absorbedFactionId)) {
    minorNations = next.minorNations
        .where((m) => m.id != absorbedFactionId)
        .toList();
  }
  if (next.tribes.any((t) => t.id == absorbedFactionId)) {
    tribes = next.tribes.where((t) => t.id != absorbedFactionId).toList();
  }

  // Canonical full-faction overture teardown (Refs #3562 AC1).
  final overtures =
      clearOverturesInvolvingFaction(next, absorbedFactionId).game
          .overtureStates;

  final relations = next.diplomacyRelations
      .where(
        (r) =>
            r.factionId1 != absorbedFactionId &&
            r.factionId2 != absorbedFactionId,
      )
      .toList();

  return next.copyWith(
    minorNations: minorNations,
    tribes: tribes,
    overtureStates: overtures,
    diplomacyRelations: relations,
  );
}

Game cleanupAfterGreatPowerAbsorb(Game next, String absorbedFactionId) {
  final aiControl = Map<String, bool>.from(next.aiControlByGpId)
    ..remove(absorbedFactionId);
  final aiSeed = Map<String, int>.from(next.aiSeedByGpId)
    ..remove(absorbedFactionId);
  final hidden = Map<String, String>.from(next.hiddenAgendaByGpId)
    ..remove(absorbedFactionId);
  final glyphs = Map<String, String>.from(next.politicalGlyphByPlayerId)
    ..remove(absorbedFactionId);

  // Canonical full-faction overture teardown (Refs #3562 AC1).
  final overtures =
      clearOverturesInvolvingFaction(next, absorbedFactionId).game
          .overtureStates;

  final relations = next.diplomacyRelations
      .where(
        (r) =>
            r.factionId1 != absorbedFactionId &&
            r.factionId2 != absorbedFactionId,
      )
      .toList();

  final subsidies = next.subsidyStates
      .where(
        (s) =>
            s.payerId != absorbedFactionId && s.targetId != absorbedFactionId,
      )
      .toList();

  // When the removed GP held colonies, those Tribes lose their suzerain.
  // SPEC/game/diplomacy.md § GP–Tribe Rules (Refs #3753 R5.5 / R6.4).
  final colonies = next.colonyStates
      .where((c) => c.colonyOfGpId != absorbedFactionId)
      .toList();
  final boycotts = next.boycottStates
      .where(
        (b) =>
            b.gpId != absorbedFactionId && b.targetGpId != absorbedFactionId,
      )
      .toList();

  return next.copyWith(
    overtureStates: overtures,
    diplomacyRelations: relations,
    subsidyStates: subsidies,
    colonyStates: colonies,
    boycottStates: boycotts,
    aiControlByGpId: aiControl,
    aiSeedByGpId: aiSeed,
    hiddenAgendaByGpId: hidden,
    politicalGlyphByPlayerId: glyphs,
  );
}
