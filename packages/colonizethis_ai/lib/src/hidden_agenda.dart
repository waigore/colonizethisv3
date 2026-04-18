// Hidden agenda modifiers for goal and order weighting. SPEC/ai/hidden-agendas.md.

import 'package:colonizethis_data/colonizethis_data.dart';

/// Returns goal weight modifier for conquer (positive = more likely to conquer).
int agendaConquerModifier(String agendaId) {
  return getAgendaConquerModifier(agendaId);
}

/// Returns goal weight modifier for diplomacy (alliances, etc.).
int agendaDiplomacyModifier(String agendaId) {
  return getAgendaDiplomacyModifier(agendaId);
}

/// Returns modifier for research/spy order tendency (positive = more likely to pick research).
/// SPEC: tech_thief "prioritizes espionage tech; high spy usage".
int agendaResearchModifier(String agendaId) {
  return getAgendaResearchModifier(agendaId);
}

/// Returns modifier for build/order choice when mirroring human (positive = boost build tendency).
/// SPEC: envy "mirrors player builds and objectives".
int agendaBuildOrderModifier(String agendaId) {
  return getAgendaBuildOrderModifier(agendaId);
}

/// Returns modifier for peace acceptance / offer peace (positive = more likely to offer or accept peace).
/// SPEC: Peacemaker "offers peace earlier"; Warmonger "higher threshold" to accept peace.
int agendaPeaceAcceptanceModifier(String agendaId) {
  return getAgendaPeaceAcceptanceModifier(agendaId);
}

/// Returns modifier for alliance acceptance (positive = more likely to form/accept alliances).
/// SPEC: Isolationist "high decline chance" for alliances.
int agendaAllianceAcceptanceModifier(String agendaId) {
  return getAgendaAllianceAcceptanceModifier(agendaId);
}

/// Returns modifier for treaty/peace breaking (positive = more likely to declare war or break treaties).
/// SPEC: Backstabber "more likely to break when beneficial"; Warmonger "more likely to break peace early".
int agendaTreatyBreakingModifier(String agendaId) {
  return getAgendaTreatyBreakingModifier(agendaId);
}

/// Returns modifier for spy-type work orders (positive = more likely to pick steal_tech / counter_spy).
/// SPEC: tech_thief "high spy usage". Used when spy work candidates exist; no effect if no spy order type.
int agendaSpyOrderModifier(String agendaId) {
  return getAgendaSpyOrderModifier(agendaId);
}
