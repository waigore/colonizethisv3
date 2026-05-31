# Factions

**SPEC/game** — Faction types and capabilities. Baseline: Imperialism II. World model: [world-model.md](world-model.md). Turn resolution: [turn-resolution-phases.md](../program/turn-resolution-phases.md).

---

## Faction

A **faction** is an entity that owns provinces (in any region) and has a defined role. There are three types: **Great Power**, **Minor Nation**, and **Tribe**. Only Great Powers submit orders and can win the game.

---

## Great Power

- **Count:** Configurable per game (default 6). Human players only ever play Great Powers.
- **Can:** Win the game; submit all orders (movement, build, research, diplomacy, trade, etc.); initiate attacks; conduct great-power diplomacy (e.g. absorb Minor Nations and Tribes); expand territory; own provinces in Old World and New World; have capital (set in capital-choice phase), stockpile, workers, military, navy; research technology.
- **Cannot:** (Nothing within the rules.)
- **Capital:** Chosen in capital-choice phase (sea-bound province + tile). See [capital-choice-phase.md](capital-choice-phase.md).

---

## Minor Nation

- **Region:** Old World only. Their provinces **count toward victory** (for whoever controls them).
- **Can:** Own provinces; have capital (assigned at game setup); have military and forts; **defend** when their provinces are attacked; participate in **trade** (offer connected resources); be **targets** of diplomacy (overtures, Join Empire). Reactive only — they do not submit orders.
- **Cannot:** Win the game; submit orders; initiate attacks or declare war; build units or research (no order phase); own ships (no navy).
- **Capital:** Assigned during game setup (any owned province; sea-bound not required), not by player choice.

**Minor military parity:** Old World minor nations are difficult to conquer and automatically keep pace with the most advanced Great Power. Define a global **military level** (1–4) as the highest regiment era currently available to **any** Great Power (from [military-units.md](military-units.md) and tech). A minor nation's **effective military level** is set to this maximum, not the average.

**Timing:** In the **Minor Regiment Upgrade** phase (see [turn-resolution-phases.md](../program/turn-resolution-phases.md)), which runs after Movement and before all combat phases, compute `maxGreatPowerMilitaryLevel` from all Great Powers using post-Research buildable land regiment tiers. For every **Old World Minor Nation**, set `effectiveMilitaryLevel = maxGreatPowerMilitaryLevel`. Tribes do **not** receive parity (see Tribe section). Parity affects **defence and recruitment quality**, not army count caps or general bonuses.

**Upgrading in place:** If minor nations' **land regiments** are eligible for upgrade due to change in **effective military level**, their existing regiments become higher-tier versions in place. Damaged regiments stay damaged. This phase is distinct from combat resolution and has no combat effects other than ensuring parity-adjusted regiment tiers are in place before naval and land combat.

---

## Tribe

- **Region:** New World only. Their provinces **do not count toward victory**.
- **Can:** Own provinces; have capital (assigned at game setup; must be located for diplomacy); have **primitive** military (no firearms, cavalry, or artillery in baseline; no forts); **defend** when invaded; participate in **trade**; be **targets** of diplomacy (overtures, Join Empire / colony). Reactive only.
- **Cannot:** Win the game; submit orders; initiate attacks; build units or research; own ships. Can be invaded without declaration of war by Great Powers (unless another GP has invested in the province).
- **Capital:** Assigned at game setup (any owned province; sea-bound not required).
- **Military level:** Tribes have **no military parity**. They are meant to be easily conquered by Great Powers. Their **effective military level** is always **1** (capped). During the Minor Regiment Upgrade phase, the System sets each Tribe's `effectiveMilitaryLevel` to 1, regardless of Great Power tech.

---

## Minor and Tribe capital connectivity

Minor Nations and Tribes have **capital-tile-rooted tile connectivity** so the System can compute which of their owned tiles contribute to **non-Great-Power extraction** for the World Market phase ([world-market.md](world-market.md) § Minor and tribe auto-sell, [extraction-and-improvements.md](extraction-and-improvements.md) § Non-Great-Power extraction). Connectivity uses the **same Road rule and Town rule** as Great Powers ([capital-and-connectivity.md](capital-and-connectivity.md) § Connectivity (Game Rule)) and produces the same per-tile `ConnectivityResult` shape (`connected`, `pathTransportCap`, `connectedByRoadRule`).

Three Minor/Tribe-specific differences are normative in [capital-and-connectivity.md](capital-and-connectivity.md) § Non-Great-Power capital connectivity:

- **Land-only.** Output stays in the faction's capital region (Old World for Minors, New World for Tribes). Cross-region overseas connectivity does not apply because Minors and Tribes do not own provinces in the other region.
- **No blockade interaction for market access.** Even when a Great Power blockades a Minor's or Tribe's port province via fleet missions, the non-Great-Power connectivity resolver ignores blockade state for World-Market participation; the faction's connectivity output remains the same as with no blockade.
- **No `townDevelopmentLevel = 4` capital-province bump.** That bump applies only to Great Powers ([capital-and-connectivity.md](capital-and-connectivity.md) § Capital province town development (Great Powers)).

The resolver iterates `Game.minorNations` and `Game.tribes` and is invoked **separately** from the Great Power resolver, so Great Power connectivity, blockade evaluation, and capital reassignment paths are unchanged.

---

## Summary

| Capability        | Great Power | Minor Nation | Tribe   |
|-------------------|-------------|--------------|--------|
| Can win           | Yes         | No           | No     |
| Submit orders     | Yes         | No           | No     |
| Own provinces     | Yes (OW+NW) | Yes (OW)     | Yes (NW) |
| Capital           | Choice phase| Setup        | Setup  |
| Initiate attack   | Yes         | No           | No     |
| Defend            | Yes         | Yes          | Yes    |
| Provinces count to victory | OW yes | Yes (for controller) | No |

Extraction and ownership apply per faction; only Great Powers have stockpiles and receive extraction in the economy phase. Minors and Tribes' production may feed trade/market per economy spec.

---

## Acceptance Criteria

- Given a new game is created with at least one Great Power, one Minor Nation, and one Tribe configured in the ruleset  
  When the System runs the game-setup pipeline per [game-setup.md](game-setup.md)  
  Then the System creates Faction records for each configured Great Power, Minor Nation, and Tribe, assigns them the correct faction type, and sets their capabilities (such as ability to submit orders, own provinces in specific regions, and win the game) according to the summary table in this document.

- Given Movement has completed in turn resolution and the Minor Regiment Upgrade phase has not yet run  
  When the System runs the Minor Regiment Upgrade phase per [turn-resolution-phases.md](../program/turn-resolution-phases.md)  
  Then the System scans all Great Powers’ buildable **land regiment** types per [military-units.md](military-units.md) and current turn tech state, derives the highest available regiment era as `maxGreatPowerMilitaryLevel`, sets each **Old World Minor Nation** `effectiveMilitaryLevel` to that value, and sets each **Tribe** `effectiveMilitaryLevel` to **1** (no parity) before any naval or land combat phase starts.

- Given a Minor Nation's `effectiveMilitaryLevel` increases because `maxGreatPowerMilitaryLevel` increased during the Minor Regiment Upgrade phase  
  When the System applies parity upgrades for that faction in that phase  
  Then the System upgrades each eligible **land regiment** to the appropriate higher-tier version while preserving any existing damage on that regiment, so parity affects unit quality but not unit counts or general bonuses.

- Given a Minor Nation `M` with capital tile `C_m` set in an Old World province `P_m` owned by `M`, with no roads on the tile map  
  When the System runs the non-Great-Power capital connectivity resolver  
  Then the resolver returns a `ConnectivityResult` keyed by `M.id` whose `connected` set contains `C_m` and every owned 4-adjacent land tile reachable by the same Road rule and Town rule the Great Power resolver applies for an equivalent input — identical per-tile output to a Great Power on the same owned set, capital tile, and tile state.

- Given a Tribe `T` with capital tile `C_t` set in a New World province `P_t` owned by `T`, with a road chain from `C_t` to a non-adjacent owned land tile `T_far` of length ≥ 2  
  When the System runs the non-Great-Power capital connectivity resolver  
  Then the resolver returns a `ConnectivityResult` keyed by `T.id` whose `connected` set contains `T_far`, applying the same Road-rule path expansion as Great Power connectivity.

- Given a Minor Nation `M` whose `capitalTile` field is `null`  
  When the System runs the non-Great-Power capital connectivity resolver  
  Then the resolver emits an empty `ConnectivityResult` (`connected.isEmpty == true`) for `M.id` and does not throw or mutate Game state.

- Given a Tribe `T` whose `capitalTile` field is `null`  
  When the System runs the non-Great-Power capital connectivity resolver  
  Then the resolver emits an empty `ConnectivityResult` for `T.id` and does not throw or mutate Game state.

- Given a `Game` with `minorNations.isEmpty` and `tribes.isEmpty`  
  When the System runs the non-Great-Power capital connectivity resolver  
  Then the resolver returns an empty map and does not iterate `Game.players` or compute Great Power connectivity.

- Given a Minor Nation `M` owning a port province `P_port` in the same region as its capital, an enemy Great Power fleet on a Blockade mission targeting `P_port` from an adjacent sea zone, and `M`'s `P_port` tiles connected by Road or Town rule under no-blockade conditions  
  When the System runs the non-Great-Power capital connectivity resolver  
  Then `M`'s `ConnectivityResult.connected` for those `P_port` tiles is the **same** as with no blockade present (the resolver passes an empty blockade set per [capital-and-connectivity.md](capital-and-connectivity.md) § Non-Great-Power capital connectivity).

- Given a `Game` with at least one Great Power, one Minor Nation, and one Tribe — each with a valid `capitalTile`  
  When the System runs Great Power `resolveConnectivity` and the non-Great-Power `resolveNonGreatPowerConnectivity` independently against the same `Game`, tile maps, and topology  
  Then the Great Power result is keyed only by Great Power player ids, the non-Great-Power result is keyed only by Minor Nation and Tribe ids, and neither call mutates `Game` state.
