import 'package:colonizethis_models/colonizethis_models.dart';

import 'tech_ids.dart';

/// Initial general cap for every Great Power at game start.
/// SPEC/game/military-generals.md § Count and tech-gated cap.
const int kInitialGeneralCap = 1;

/// Computes the tech-gated general cap from a Great Power's unlocked techs.
///
/// Stacking rules per SPEC/game/military-generals.md (non-stacking maxima):
/// - base 1; `organised_regiments` → 2;
/// - `national_bureaucracy` OR `improved_infantry_tactics` → 3 (no double count);
/// - `nationalism` → 4.
int generalCapForUnlockedTechs(Map<String, bool>? techUnlocked) {
  final t = techUnlocked ?? const <String, bool>{};
  var cap = kInitialGeneralCap;
  if (t[kTechIdOrganisedRegiments] == true && cap < 2) cap = 2;
  if ((t[kTechIdNationalBureaucracy] == true ||
          t[kTechIdImprovedInfantryTactics] == true) &&
      cap < 3) {
    cap = 3;
  }
  if (t[kTechIdNationalism] == true && cap < 4) cap = 4;
  return cap;
}

/// Re-derives each Great Power's general cap from unlocked techs, persists it on
/// the [Player], and spawns generals (0 medals) so each GP roster reaches the
/// cap.
///
/// Spawn-only: existing generals are never deleted and rosters that already
/// exceed the cap are retained. Used at game setup and after the Research phase
/// when tech unlocks may raise a cap. SPEC/game/military-generals.md.
Game syncGeneralCapsFromTech(Game game) =>
    _applyGeneralCaps(game, (p) => generalCapForUnlockedTechs(p.techUnlocked));

/// Load-time reconciliation of the generals roster against each Great Power's
/// effective general cap.
///
/// Uses the persisted [Player.generalCap] when present; otherwise derives the
/// cap from unlocked techs (legacy-save migration default). Spawn-only per
/// SPEC/game/military-generals.md: spawns missing generals (0 medals) up to the
/// effective cap, never deletes generals, and tolerates above-cap rosters.
Game reconcileGeneralsToGeneralCap(Game game) => _applyGeneralCaps(
  game,
  (p) => p.generalCap ?? generalCapForUnlockedTechs(p.techUnlocked),
);

/// Sets each GP's persisted cap from [capFor] and appends 0-medal generals so the
/// roster size is at least the cap. Never removes generals. Returns the original
/// [game] unchanged when no cap or roster change is needed.
Game _applyGeneralCaps(Game game, int Function(Player) capFor) {
  final usedIds = <String>{for (final g in game.generals) g.id};
  final ownerCounts = <String, int>{};
  for (final g in game.generals) {
    ownerCounts[g.ownerId] = (ownerCounts[g.ownerId] ?? 0) + 1;
  }

  final spawned = <General>[];
  final nextPlayers = <Player>[];
  var changed = false;
  for (final player in game.players) {
    final cap = capFor(player);
    if (player.generalCap != cap) {
      changed = true;
      nextPlayers.add(player.copyWith(generalCap: cap));
    } else {
      nextPlayers.add(player);
    }
    final existingCount = ownerCounts[player.id] ?? 0;
    for (var i = existingCount; i < cap; i++) {
      final id = _nextGeneralId(player.id, usedIds);
      usedIds.add(id);
      spawned.add(General(id: id, ownerId: player.id, medals: 0));
      changed = true;
    }
  }

  if (!changed) return game;
  return game.copyWith(
    players: nextPlayers,
    generals: spawned.isEmpty
        ? game.generals
        : <General>[...game.generals, ...spawned],
  );
}

/// Smallest `${ownerId}_gen_$n` id not already present in [usedIds] (deterministic).
String _nextGeneralId(String ownerId, Set<String> usedIds) {
  var n = 0;
  while (usedIds.contains('${ownerId}_gen_$n')) {
    n++;
  }
  return '${ownerId}_gen_$n';
}
