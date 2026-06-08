// Hidden agenda assignment at game start. SPEC/ai/hidden-agendas.md.

import 'package:colonizethis_models/colonizethis_models.dart';

/// Agenda ids per SPEC/ai/hidden-agendas.md.
const List<String> kHiddenAgendaIds = [
  'warmonger',
  'isolationist',
  'backstabber',
  'tech_thief',
  'peacemaker',
  'envy',
];

/// Assigns hidden agendas for all AI-controlled Great Powers. Call at game start.
/// Deterministic: agendaSeed[P] = hash(globalGameSeed, aiSeed[P]); map to agenda id.
Game assignHiddenAgendasForGame(Game game) {
  if (game.players.isEmpty) return game;
  final global = game.globalGameSeed ?? 0;
  final newAgendas = <String, String>{};
  for (final p in game.players) {
    final isAi = game.aiControlByGpId[p.id] ?? !p.isHuman;
    if (!isAi) continue;
    final aiSeed = game.aiSeedByGpId[p.id] ?? p.id.hashCode;
    final agendaSeed =
        (global ^ (aiSeed * kDeterministicHashMixPrime32)) &
        kDeterministicLcg31Mask;
    final idx = agendaSeed % kHiddenAgendaIds.length;
    newAgendas[p.id] = kHiddenAgendaIds[idx];
  }
  if (newAgendas.isEmpty) return game;
  return game.copyWith(
    hiddenAgendaByGpId: {...game.hiddenAgendaByGpId, ...newAgendas},
  );
}
