# Leader Bonuses

**SPEC/game** — Per–Great Power leader selection and combat bonuses. Reference: GDD 09. Implementation: colonizethis_models (Player.leaderKey), game_setup (assignment), combat_resolver and quick_battle_resolver (application).

---

## Leader Selection

- Each **Great Power** has one **leader** for the game, chosen at **game start** (capital-choice or setup phase).
- **Human players:** Select leader via UI (or accept default). **AI GPs:** Leader assigned from config (e.g. default variant per GP).
- Leader is stored as **leaderKey** on the Player; serialized with the game. No mid-game change.

---

## When Bonuses Apply

Leader bonuses apply in:

- **Auto-resolve combat** (main game turn resolution): when resolving a BattleContext, the combat resolver reads the defender’s and each attacker’s GP, looks up each player’s leaderKey, and applies the corresponding bonus to that side’s strength (or modifiers) before resolving the engagement.
- **Quick Battle** (ctdev or in-game quick battle): same rule; both sides get their GP’s leader bonus.

Bonuses are **combat-only** in Phase 5 (no economy or research bonus from leader).

---

## Bonus Table (ColonizeThis-Specific)

Leaders are identified by **leaderKey** (string). Each key maps to a **combat modifier**:

| leaderKey (example) | Effect |
|--------------------|--------|
| `napoleon` | +25% melee strength (attacker and defender side) |
| `frederick` | +15% melee strength |
| `reserve` / default | No bonus (0%) |

Implementation may use a table in colonizethis_data or colonizethis_logic keyed by leaderKey. Modifiers are applied as multipliers to the side’s effective strength (e.g. 1.25 for +25% melee) before the combat formula. If a leaderKey is unknown, treat as no bonus.

---

## Application Rule

- **Defender:** Use defender faction’s GP player (province owner); apply that player’s leader bonus to defender strength.
- **Attacker:** For each attacking side, use that side’s GP player; apply that player’s leader bonus to that attacker’s strength.
- Bonuses are symmetric (same multiplier type for attacker and defender); only the owning player’s leader matters for each side.
