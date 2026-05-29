# Military Armies (Land)

**SPEC/game** — First-class **armies**: player-defined groups of regiments, province-stationed, ordered and moved as a unit. **Parallels:** armies relate to regiments as **fleets** relate to ships ([ships-and-naval.md](ships-and-naval.md)). Generals: [military-generals.md](military-generals.md). Regiments: [military-units.md](military-units.md). Orders/movement: [../program/orders.md](../program/orders.md), [../program/movement.md](../program/movement.md).

---

## Definition

An **army** is a persistent, owner-scoped collection of **land military regiment instances** (unit ids). Armies are **not** tied to a single regiment type; composition may mix types.

- **Station:** Every army occupies exactly **one province** at a time (prefixed `regionId|localId`). All regiments in that army share that province.
- **Membership:** Every land military regiment belongs to **exactly one** army at all times. There are **no** “unassigned” regiments in valid game state.
- **Orders:** The player issues **movement and attack intent per army** (not per regiment). Resolution updates every regiment in the army to the destination province together.

---

## Home Army (capital)

Each Great Power has exactly one **Home Army**, analogous to the **Home Fleet**:

- **Location:** Always stationed in the player’s **capital province** (when a capital exists). The Home Army **does not** execute moves that would leave the capital province (it may reorganize composition via split/combine only; it does not “march” elsewhere). New land regiments from `BuildUnitOrder` **enter the Home Army** at the capital by default.
- **Persistence:** Like the Home Fleet, the Home Army is **never deleted** when empty (zero regiments). The Military Units panel always surfaces it for the capital region when the human player is a Great Power. **AI auto-split note:** Full AI may split the Home Army down to **zero** regiments under stalled Old World expansion — including the sole-regiment case — into a field army at the capital so that conquest army moves can issue from the field army id (the Home Army's no-march invariant is preserved verbatim; see [SPEC/ai/phase-planner-architecture.md](../ai/phase-planner-architecture.md) § AI conquest-prep auto-split; Refs #2925).

**Minors / Tribes / AI:** Use the same army container model in `WorldState`; composition and split/combine UI may be human-only. Until AI specs define army handling, non-human factions **may** use a deterministic implicit army layout (e.g. one army per province containing that faction’s regiments) implemented in logic — must not leave regiments without an army.

---

## Split and combine

**Semantics** mirror naval **split fleet** / **combine fleets** ([../ui/naval-units-fleet-management.md](../ui/naval-units-fleet-management.md)):

- **Locality:** Split/combine is allowed only among armies that share the **same province** (same owner). Cross-province combine is rejected.
- **Combine target:** If **Home Army** is among the selected armies, it is always the **merge target**; otherwise the target is the first selected army in **panel display order**.
- **Regiment instances:** Each regiment keeps its stable unit **instance id**; lists are concatenated when merging. **Remove** empty non-Home armies after a merge.
- **Split:** Produces a second army in the **same** province; player chooses which regiments move to the new army (same UX pattern as naval split transfer list).

---

## Movement and attacks

- **Land movement orders** reference **army id**, not regiment id. Validation uses the army’s **current** province and the same destination rules as today ([movement.md](../program/movement.md)): owned-destination anywhere; hostile/neutral adjacent P–P within region.
- **War and attacks:** Moving an army into a province the player does not own remains an act of war per existing diplomacy/combat rules; **general** commitment and caps are expressed in terms of **armies** and **pre-combat assignment** ([military-generals.md](military-generals.md)).

---

## Combat and province loss

- **Defensive resolution order:** For a defending province, **army casualties and army elimination** are applied **before** province ownership flips. If all defending armies of the defender faction in that province are **eliminated** (no regiments remain) as a result of combat, **then** province capture / flip rules apply per [combat.md](combat.md).
- **Battle grouping:** Multiple defending **armies** of the same faction in one province contribute regiments to a **single defender side** for that province’s land battle; **defender general medals** use the **primary defending army**’s bound general — deterministic choice: army with the **most regiments** before battle resolution, tie-break **lexical army id**.

---

## Acceptance criteria

- Given a Great Power at game setup with a capital province, when the System initializes land forces, then the System ensures exactly one Home Army exists for that player, stationed at the capital province, and every land military regiment (if any) belongs to exactly one army.

- Given two armies of the same owner in the same province, when the player combines them legally, then the System merges all regiment ids into the merge target army, removes the source armies from state, and leaves every regiment referenced by exactly one army.

- Given one army in province P with at least two regiments, when the player splits off a non-empty subset into a new army, then the System creates a new army in P, moves only those regiments to it, and both armies remain in P.

- Given a Great Power’s Home Army at the capital, when the player issues a land move order for that army whose destination is not the capital province, then the System rejects the order (Home Army cannot leave the capital).

- Given a non-Home army in province A, when the player issues a valid army move to province B, then the Movement phase updates every regiment in that army to province B and the army’s stationed province to B.

- Given a land battle in province P where the defender’s armies are eliminated with no regiments remaining in P for that defender, when combat resolution completes, then the System applies province flip (if attacker wins) only after army elimination is fully applied for that engagement chain.

- Given multiple defending armies of the same faction in P before battle resolution, when the System selects the primary defending army for general medal purposes, then the System chooses the army with the greatest regiment count, breaking ties by smallest army id string.
