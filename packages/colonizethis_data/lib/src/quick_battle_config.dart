/// Quick Battle configuration. SPEC/game/quick-battle.md, quick-battle-resolution.md.
/// Enums (QuickBattleLane, QuickBattleLine, QuickBattleLaneTerrain) live in colonizethis_models.
library;

/// Max cohesion per battalion group. At 0, group is broken.
const int quickBattleMaxCohesion = 3;

/// Max battle rounds. Phase 4: 3.
const int quickBattleMaxRounds = 3;

/// Command points per round (min and max). Phase 4: 2–3.
const int quickBattleCpPerRoundMin = 2;
const int quickBattleCpPerRoundMax = 3;
