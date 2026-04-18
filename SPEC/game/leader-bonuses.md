# Leader Bonuses

**SPEC/game** — Per–Great Power leader selection and combat bonuses. Reference: GDD 09. Province identity (defender / province owner): [world-model-identity.md](world-model-identity.md).

---

## Leader Selection

- Each **Great Power** has one **leader** for the game, chosen at **game start** (capital-choice or setup phase).
- **Human players:** Select leader via UI (or accept default). **AI GPs:** Leader assigned from config (e.g. default variant per GP).
- Leader is stored as **leaderKey** on the Player; serialized with the game. No mid-game change.

---

## When Bonuses Apply

Leader bonuses apply to **land combat only** (not naval):

- **Auto-resolve combat** (main game turn resolution): when resolving a land BattleContext, the combat resolver reads the defender’s and each attacker’s GP, looks up each player’s leaderKey, and applies the corresponding bonus to that side’s strength (or modifiers) before resolving the engagement.
- **Quick Battle** (ctdev or in-game quick battle): same rule; both sides get their GP’s leader bonus.

Naval combat is resolved per [ships-and-naval.md](ships-and-naval.md) and [naval-combat-resolution.md](../program/naval-combat-resolution.md); leader bonuses are **not** applied there (medal and tech modifiers only).

Bonuses are **combat-only** (no economy or research bonus from leader).

---

## Bonus Table (ColonizeThis-Specific)

Leaders are identified by **leaderKey** (string). Each key maps to a **combat modifier**:

| leaderKey (example) | Effect |
|--------------------|--------|
| `napoleon` | +25% melee strength (attacker and defender side) |
| `frederick` | +15% melee strength |
| `reserve` / default | No bonus (0%) |

Modifiers are applied as multipliers to the side’s effective strength (e.g. 1.25 for +25% melee) before the combat formula. If a leaderKey is unknown, treat as no bonus.

**LeaderKey format and matching:** The value stored on the Player may be an exact key (`napoleon`, `frederick`, `reserve`) or a variant id (e.g. `france_napoleon_leader`, `prussia_frederick_leader`). Lookup is: (1) exact key in the table first; (2) if no exact match, case-insensitive substring: key containing `napoleon` → +25%, containing `frederick` → +15%. Any other or unknown key receives no bonus (multiplier 1.0).

**Where defined (current product):** The leaderKey → melee multiplier table above is the **source of truth** for design defaults. In the current (current product) implementation, the program does **not** read this table from the ruleset. The mapping is implemented as **code constants** in `colonizethis_logic` (e.g. `leader_bonuses.dart`: `_leaderMeleeBonus` or equivalent). Ruleset-driven override for the leader bonus table is **deferred**. When added, the key path and loader contract will be specified in this document and in [ruleset-config.md](ruleset-config.md); program loading: [ruleset-config.md](../program/ruleset-config.md).

---

## Application Rule

- **Defender:** Use defender faction’s GP player (province owner); apply that player’s leader bonus to defender strength. Province owner lookup uses prefixed province ids and region-scoped lookup; see [world-model-identity.md](world-model-identity.md).
- **Attacker:** For each attacking side, use that side’s GP player; apply that player’s leader bonus to that attacker’s strength.
- Bonuses are symmetric (same multiplier type for attacker and defender); only the owning player's leader matters for each side.

---

## Acceptance criteria

- **Leader selection:** Each Great Power has exactly one leader for the game, chosen at game start (human via UI or default; AI from config). Leader is stored as leaderKey on the Player and serialized; no mid-game change.
- **Combat-only (land):** Leader bonuses apply only in land auto-resolve combat and Quick Battle; they do not apply to naval combat. No economy or research effect.
- **Bonus table:** The leaderKey → modifier mapping (e.g. napoleon +25%, frederick +15%, reserve/default 0%) is the source of truth. Unknown leaderKey is treated as no bonus. Variant ids (e.g. france_napoleon_leader) are matched per § LeaderKey format and matching (exact first, then case-insensitive substring).
- **Application:** Defender uses province owner's GP leader (province lookup prefixed and region-scoped per [world-model-identity.md](world-model-identity.md)); each attacker side uses that side's GP leader. Bonuses are applied as multipliers to effective strength before resolution.
- **Implementation:** Combat resolver and quick battle apply leader bonuses per [combat-resolution.md](../program/combat-resolution.md) and [quick-battle-resolution.md](../program/quick-battle-resolution.md).
