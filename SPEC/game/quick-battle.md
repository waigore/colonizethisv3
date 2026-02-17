# Quick Battle (one-province tactical combat)

## Purpose and scope

Quick Battle is a **one-province attacker vs defender** tactical mini-game that replaces pure auto-resolve when players choose the Quick Battle mode. It offers a short, command-point-based, turn-by-turn system that preserves Phase 3 combat stats and formulas while giving players meaningful tactical choices (terrain, maneuvers, focus fire, timing of assaults). Output is compatible with the existing combat casualty/flip pipeline.

Constraints:

- One attacking stack vs one defending stack in a single province.
- At most **3 battle rounds**.
- Each round, each side has **2–3 Command Points (CP)** to spend on actions.
- System must be simple to operate but allow skilled players to trade better and occasionally win uphill fights.

## Battlefield layout and terrain

Each side arrays units on a simplified battlefield inspired by early modern deployments:

- **Lanes per side:** `LEFT`, `CENTER`, `RIGHT`, and `RESERVE`.
- **Lines per non-reserve lane:** `FRONT` and `SUPPORT`.
- Each `(lane, line)` holds 0–N regiments; these are treated as a **battalion group** for Quick Battle.

Province terrain provides a base context; each lane is tagged with a single terrain type (shared by both sides in that lane):

- `OPEN` — baseline.
- `HILL` — better defense and ranged fire; harder to charge uphill.
- `WOODS` — better cover; worse ranged visibility; harder to maneuver.
- `TOWN` — very strong defense; modest penalties to movement and some artillery fire.
- `SWAMP` — very poor footing; bad for both attack and defense; hard to maneuver.

Lane terrain is used as a modifier on top of existing tactical stats (FPN, FPM, RNG, DEF, MVR) from Phase 3.

## Cohesion (morale) model

Each battalion group (lane + line) has a **cohesion** value on a small integer scale (e.g. 0–3):

- Starts at maximum for all groups.
- Cohesion declines when:
  - The group suffers significant casualties in a round.
  - The group maneuvers through bad ground (e.g. into or out of `SWAMP`) under pressure.
  - A neighboring lane collapses (e.g. friendly flank breaks).
- Effects of low cohesion:
  - Reduces effective combat power for that group (applied as modifiers in Quick Battle resolution).
  - At **0 cohesion**, the group is **broken**: it no longer contributes offensive strength, and is treated as routed or pulled to `RESERVE` for casualty application.

In addition, each side has a coarse **battle morale index** derived from the sum of group cohesion and key lane status (especially `CENTER`). This is used to distinguish decisive wins from mutual exhaustion.

## Turn structure and actions

Quick Battle proceeds in at most **3 rounds**. In each round:

1. Determine which side acts first (initiative, consistent with Phase 3 combat rules; ties may alternate).
2. Side A receives **2–3 CP** and spends them on actions.
3. Side B receives **2–3 CP** and spends them on actions.
4. Resolve all fire, charges, maneuver consequences, casualties, cohesion changes, and possible lane collapses.

Core actions (examples; exact numbers live in technical spec):

- **Volley Fire (1 CP):** Front-line units (and eligible artillery/support) in a chosen lane fire at the opposing front-line group. Terrain and cohesion adjust hit chances and losses.
- **Defend / Entrench (1 CP):** Set a lane to a defensive stance for the round, improving defense (especially in `HILL`, `WOODS`, `TOWN`) at the cost of maneuverability.
- **Maneuver (1 CP):** Rotate `FRONT`/`SUPPORT` within a lane, or move a group between `RESERVE` and a lane. Maneuvering through bad terrain or while under heavy pressure can cost cohesion.
- **Fall Back / Refuse Flank (2 CP):** Pull a front-line group back to `RESERVE` (and optionally replace it) to avoid destruction, or deliberately weaken a flank to reinforce `CENTER` or the opposite flank. This trades space and cohesion for preservation of forces.
- **Assault / Charge (2 CP):** Launch a high-risk, high-reward attack in one lane, especially suited for cavalry or high-MVR infantry. Very strong against disrupted or badly positioned enemies; much weaker into `WOODS`, `TOWN`, or uphill `HILL`.

Players use CP to choose when to defend, when to trade space, when to concentrate fire, and when to attempt decisive assaults. Skilled use of terrain and timing allows weaker forces to inflict favorable losses or occasionally win against stronger opponents.

## Outcome and integration

After up to 3 rounds (or earlier if one side clearly collapses), the Quick Battle produces:

- Casualties per side (by unit type or equivalent granularity).
- Updated status of key lanes and side morale (e.g. broken center vs intact battle line).
- A single **battle result**: decisive attacker win, decisive defender hold, or mutual exhaustion.

Quick Battle does **not** change the underlying combat formula; it supplies structured inputs (lane-level strengths, modifiers, cohesion effects) into the existing resolution pipeline and receives standard outputs:

- Casualty lists for both sides.
- Whether the province flips to the attacker or remains with the defender (consistent with Phase 3 combat and siege rules).

The game then applies casualties and province ownership changes using the same world-state update logic as auto-resolve.

