// Hidden agenda assignment and modifiers. SPEC/ai/hidden-agendas.md.

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
  const int prime = 0x9E3779B1;
  final newAgendas = <String, String>{};
  for (final p in game.players) {
    final isAi = game.aiControlByGpId[p.id] ?? !p.isHuman;
    if (!isAi) continue;
    final aiSeed = game.aiSeedByGpId[p.id] ?? p.id.hashCode;
    final agendaSeed = (global ^ (aiSeed * prime)) & 0x7fffffff;
    final idx = agendaSeed % kHiddenAgendaIds.length;
    newAgendas[p.id] = kHiddenAgendaIds[idx];
  }
  if (newAgendas.isEmpty) return game;
  return game.copyWith(
    hiddenAgendaByGpId: {...game.hiddenAgendaByGpId, ...newAgendas},
  );
}

/// Returns goal weight modifier for conquer (positive = more likely to conquer).
int agendaConquerModifier(String agendaId) {
  switch (agendaId) {
    case 'warmonger':
      return 40;
    case 'peacemaker':
      return -50;
    case 'backstabber':
      return 20;
    case 'isolationist':
      return -30;
    default:
      return 0;
  }
}

/// Returns goal weight modifier for diplomacy (alliances, etc.).
int agendaDiplomacyModifier(String agendaId) {
  switch (agendaId) {
    case 'isolationist':
      return -50;
    case 'peacemaker':
      return 30;
    default:
      return 0;
  }
}
