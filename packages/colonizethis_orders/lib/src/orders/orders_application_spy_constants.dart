/// Base per-turn kill chance for a spy in foreign territory (Refs #3834 R5).
const int spyBaseKillChancePercent = 5;

/// Per garrison regiment kill bonus, capped at [spyGarrisonKillChanceCapPercent] (R4).
const int spyGarrisonKillChancePerRegiment = 1;
const int spyGarrisonKillChanceCapPercent = 8;

/// Empire-wide kill bonus when territory owner runs counter-espionage (R6).
const int spyCounterEspionageKillBoostPercent = 5;

/// Per-turn defection chance for enemy spies when counter-espionage is active (R7).
const int spyDefectionChancePercent = 10;

/// Diplomacy relation penalty per spy killed in foreign territory (R8).
const int spyDeathDiplomacyPenalty = 8;

/// Passive RP boost per rival GP with spy presence (R2); GA-tunable default 0.15.
const double spyResearchBoostPerGp = 0.15;
