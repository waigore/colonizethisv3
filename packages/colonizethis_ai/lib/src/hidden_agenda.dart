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

/// Returns modifier for research/spy order tendency (positive = more likely to pick research).
/// SPEC: tech_thief "prioritizes espionage tech; high spy usage".
int agendaResearchModifier(String agendaId) {
  switch (agendaId) {
    case 'tech_thief':
      return 35;
    default:
      return 0;
  }
}

/// Returns modifier for build/order choice when mirroring human (positive = boost build tendency).
/// SPEC: envy "mirrors player builds and objectives".
int agendaBuildOrderModifier(String agendaId) {
  switch (agendaId) {
    case 'envy':
      return 20;
    default:
      return 0;
  }
}

/// Returns modifier for peace acceptance / offer peace (positive = more likely to offer or accept peace).
/// SPEC: Peacemaker "offers peace earlier"; Warmonger "higher threshold" to accept peace.
int agendaPeaceAcceptanceModifier(String agendaId) {
  switch (agendaId) {
    case 'peacemaker':
      return 30;
    case 'warmonger':
      return -25;
    default:
      return 0;
  }
}

/// Returns modifier for alliance acceptance (positive = more likely to form/accept alliances).
/// SPEC: Isolationist "high decline chance" for alliances.
int agendaAllianceAcceptanceModifier(String agendaId) {
  switch (agendaId) {
    case 'isolationist':
      return -40;
    case 'peacemaker':
      return 10;
    default:
      return 0;
  }
}

/// Returns modifier for treaty/peace breaking (positive = more likely to declare war or break treaties).
/// SPEC: Backstabber "more likely to break when beneficial"; Warmonger "more likely to break peace early".
int agendaTreatyBreakingModifier(String agendaId) {
  switch (agendaId) {
    case 'backstabber':
      return 25;
    case 'warmonger':
      return 20;
    default:
      return 0;
  }
}

/// Returns modifier for spy-type work orders (positive = more likely to pick steal_tech / counter_spy).
/// SPEC: tech_thief "high spy usage". Used when spy work candidates exist; no effect if no spy order type.
int agendaSpyOrderModifier(String agendaId) {
  switch (agendaId) {
    case 'tech_thief':
      return 25;
    default:
      return 0;
  }
}
