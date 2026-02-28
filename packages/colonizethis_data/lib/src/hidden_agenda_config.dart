/// Hidden agenda behavior modifiers. SPEC/ai/hidden-agendas.md.
library;

/// Modifier values for hidden agenda behavior effects.
/// These values adjust AI decision-making based on the assigned agenda.
/// Positive values increase tendency, negative values decrease it.

/// Conquer modifier per agenda (positive = more likely to conquer).
/// warmonger: +40, peacemaker: -50, backstabber: +20, isolationist: -30.
const Map<String, int> agendaConquerModifiers = {
  'warmonger': 40,
  'peacemaker': -50,
  'backstabber': 20,
  'isolationist': -30,
};

/// Diplomacy modifier per agenda (positive = more likely to pursue diplomacy).
const Map<String, int> agendaDiplomacyModifiers = {
  'isolationist': -50,
  'peacemaker': 30,
};

/// Research/spy order tendency modifier (positive = more likely to pick research).
/// SPEC: tech_thief "prioritizes espionage tech; high spy usage".
const Map<String, int> agendaResearchModifiers = {
  'tech_thief': 35,
};

/// Build/order choice modifier when mirroring human (positive = boost build tendency).
/// SPEC: envy "mirrors player builds and objectives".
const Map<String, int> agendaBuildOrderModifiers = {
  'envy': 20,
};

/// Peace acceptance/offer modifier (positive = more likely to offer or accept peace).
/// SPEC: Peacemaker "offers peace earlier"; Warmonger "higher threshold" to accept peace.
const Map<String, int> agendaPeaceAcceptanceModifiers = {
  'peacemaker': 30,
  'warmonger': -25,
};

/// Alliance acceptance modifier (positive = more likely to form/accept alliances).
/// SPEC: Isolationist "high decline chance" for alliances.
const Map<String, int> agendaAllianceAcceptanceModifiers = {
  'isolationist': -40,
  'peacemaker': 10,
};

/// Treaty/peace breaking modifier (positive = more likely to declare war or break treaties).
/// SPEC: Backstabber "more likely to break when beneficial"; Warmonger "more likely to break peace early".
const Map<String, int> agendaTreatyBreakingModifiers = {
  'backstabber': 25,
  'warmonger': 20,
};

/// Spy-type work order modifier (positive = more likely to pick steal_tech / counter_spy).
/// SPEC: tech_thief "high spy usage". Used when spy work candidates exist; no effect if no spy order type.
const Map<String, int> agendaSpyOrderModifiers = {
  'tech_thief': 25,
};

/// Returns goal weight modifier for conquer (positive = more likely to conquer).
int getAgendaConquerModifier(String agendaId) {
  return agendaConquerModifiers[agendaId] ?? 0;
}

/// Returns goal weight modifier for diplomacy (alliances, etc.).
int getAgendaDiplomacyModifier(String agendaId) {
  return agendaDiplomacyModifiers[agendaId] ?? 0;
}

/// Returns modifier for research/spy order tendency (positive = more likely to pick research).
int getAgendaResearchModifier(String agendaId) {
  return agendaResearchModifiers[agendaId] ?? 0;
}

/// Returns modifier for build/order choice when mirroring human (positive = boost build tendency).
int getAgendaBuildOrderModifier(String agendaId) {
  return agendaBuildOrderModifiers[agendaId] ?? 0;
}

/// Returns modifier for peace acceptance / offer peace (positive = more likely to offer or accept peace).
int getAgendaPeaceAcceptanceModifier(String agendaId) {
  return agendaPeaceAcceptanceModifiers[agendaId] ?? 0;
}

/// Returns modifier for alliance acceptance (positive = more likely to form/accept alliances).
int getAgendaAllianceAcceptanceModifier(String agendaId) {
  return agendaAllianceAcceptanceModifiers[agendaId] ?? 0;
}

/// Returns modifier for treaty/peace breaking (positive = more likely to declare war or break treaties).
int getAgendaTreatyBreakingModifier(String agendaId) {
  return agendaTreatyBreakingModifiers[agendaId] ?? 0;
}

/// Returns modifier for spy-type work orders (positive = more likely to pick steal_tech / counter_spy).
int getAgendaSpyOrderModifier(String agendaId) {
  return agendaSpyOrderModifiers[agendaId] ?? 0;
}
