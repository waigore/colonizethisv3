# Appendix: The Royal Decrees

## Purpose

Use this ledger to issue every decree available to your court, check its price and limits, and know when its result will be seen. “Phase” names are the player-facing stages of the next turn; rejected decrees change nothing.

## How it is done

### Orders issued for the next turn

| Decree | Entry point and control | Cost / chief refusal | Result appears | See |
|---|---|---|---|---|
| Civilian move | **Spy:** **Civilian units panel** → idle Spy **Relocate** → map destination (soft warn if last Spy leaves foreign intel). Other civilians: implicit leg of civilian work decree only (Chs. 4, 6). | Civilian must be yours; destination land, visible, occupiable; xor with civilian work decree on same unit. | **Movement** | Chs. 4–5 |
| Army move / invasion | **Military units panel** → **Move** on a non-Home Army → **Move army dialog** → destination; or **Province sea-zone overlay** Military **Move** / **Invade** (optional **Overlay army move picker** when several armies qualify; Invade preselects the viewed province). Invasion confirmation may add Declare War. | Free. Home Army cannot leave capital; own destinations or adjacent valid foreign targets only; war must exist or be declared in the same draft. | **Diplomacy**, then **Movement**; battle follows if contested. | Chs. 11–12 |
| Civilian work | **Civilian units panel** → idle unit **Assign** → target → highlighted valid map tile; **Province sea-zone overlay** shortcuts may open filtered assignment. | One pending work per unit; target, occupancy, terrain, ownership, technology, materials, and tile reservation must pass. | Implicit move: **Movement**; assignment/progress: **Build / work**. | Chs. 4, 6 |
| Recruit / train worker | **Production screen** → **Labour Controls** → tier **+**. | Peasant: fabric ×2. Higher tiers consume one peasant, need paper/treasury and required technologies; queued military/naval builds share the peasant reserve. | **Build / work** | Ch. 5 |
| Research | **Technology screen** → **Slots** → choose technology and funding. **Cancel** clears the slot and forfeits its progress. | Funding is paid from treasury; technology must be researchable, not complete, and fit an available slot. | **Research** | Ch. 9 |
| Build civilian | **Civilian units panel** → **Train** → **Train civilians dialog**. | Treasury + paper; Merchant/Rail Builder need their unlocks; capital tile required. | **Build / work**; unit appears at capital. | Ch. 5 |
| Build regiment | **Military units panel** → **Train** → **Train military dialog** (row shows category, combat-role gist, food upkeep / turn, and build costs). | Treasury, materials, one reserved peasant, and regiment technology. | **Build / work**; joins Home Army. | Ch. 11 |
| Build ship | **Naval units panel** → **Train** → **Train naval dialog**. | Treasury, materials, one reserved peasant, and ship technology where required. | **Build / work**; joins Home Fleet. | Ch. 13 |
| Fleet move | **Map:** tap in-port sea-going fleet marker (**Empire overview / map area**) → **Move fleet dialog**, or at-sea marker → **Naval mission menu dialog** → **Move fleet dialog**. **Panel:** **Naval units panel** → **Move** on a sea-going fleet → **Move fleet dialog** → legal destination. | Free. Home Fleet cannot move; only one adjacent sea/port step; ports must be yours. Replaces that fleet’s pending mission. | **Movement** | Ch. 13 |
| Fleet mission | **Map:** tap at-sea human fleet marker (**Empire overview / map area**) → **Naval mission fleet picker dialog** (if needed) → **Naval mission menu dialog** → **Naval mission target dialog** for Blockade/Beachhead targets. Home Fleet marker opens **Naval units panel** instead; in-port sea-going marker opens Move. **Panel:** **Naval units panel** → **Mission** on an at-sea sea-going fleet (same flow). **Cancel pending mission** clears a staged mission. | Free. Patrol/Blockade/Beachhead/Defend require a sea-going fleet at sea; Blockade/Beachhead need an adjacent at-war province target. A fleet moves or takes one mission, never both. Join Home Fleet: dock at capital or **Transfer to home fleet** transfer — not the mission menu. | Assignment: **Movement**; interceptions: **Naval Interception & Naval Combat**. | Ch. 13 |
| Trade bid / offer | Left-rail **Trade** → **Trade screen** → **Market** (bid/offer/none + quantity; last-turn price move beside the price) or **Deal Book** (last-turn fills / carry-forwards). | Bid/offer are mutually exclusive per commodity; quantity, cargo, treasury, stockpile, and bid-type caps apply; riches cannot trade. | **World Market** | Ch. 8 |

### Work targets

| Target and unit | Cost / key refusal | Result |
|---|---|---|
| `explore` — Explorer | Free; province must be partly revealed and occupiable. | Reveals province on completion. |
| `prospect` — Explorer | Free; mineral-eligible, visible, occupiable unprospected tile. | One-turn completion marks tile prospected. |
| `build_improvement` — Builder | Lumber + cast iron; resource required; mineral must be prospected; level/tech cap applies. | Raises improvement level. |
| `upgrade_town` — Builder | National Bureaucracy, materials, and province town tile; availability reflects current validator rules. **Province sea-zone overlay** on the Political Town development row opens Builder-only assignment for the province town tile when eligible. | Raises town development. |
| `build_road` — Engineer | Lumber + metal; terrain/road technology limits. | Raises transport level. |
| `build_port` — Engineer | Lumber + metal; valid coastal/river tile. **Province sea-zone overlay** shortcut on the Road / transport row opens Engineer-only assignment for the selected coastal tile when eligible; Port status reads None or Present. **Development screen** → **Counsel screen** Development tab can **Agree** a ranked port when the courts would dig one this turn. | Creates port and transport level 4. |
| `build_fort` — Engineer | Materials, town tile, and fort technology where required. **Province sea-zone overlay** shortcut on the Military fort row opens Engineer-only assignment for the selected town tile when eligible. | Raises fort level. |
| `build_rail` — Rail Builder | Steel ×2 + lumber ×2; road level 1–2, known terrain, matching rail technology. | Sets railroad transport level 4. |
| `counter_spy` — Spy | Free; owned province. | Ongoing empire-wide counter-espionage effect; spy checks occur in **Spy resolution**. |
| `purchase_land` — Merchant | Embassy, peace, resource tile, prospection for minerals, and treasury ≥ 15× base price; no prior buyer. **Province sea-zone overlay** shortcut on the Tile Resource row opens Merchant-only assignment for the selected tile when eligible. | One-turn completion debits treasury and records the tile purchase. |

### Diplomacy

All begin at **Diplomacy screen** → select faction → **Diplomacy detail screen** detail/actions → confirm. Most are pending decrees resolved in **Diplomacy**.

| Decree | Cost / key refusal | Result |
|---|---|---|
| Declare War | Must be at peace; may accompany an invasion. | War before Movement. |
| Offer Peace | Must be at war; target must accept. | Peace if accepted. |
| Alliance | Great Power only; peace; no existing formal alliance. | Treaty if accepted. |
| Break Alliance | Formal alliance required. **Diplomacy screen** panel **Break Alliance** confirmation is immediate for the human player. | Treaty ends immediately; same-pair alliance/overture/aid/subsidy blocked until next turn. |
| Establish Overture | One stage at a time; relation, treasury, target, and technology gates apply. | Target accepts/rejects in Diplomacy. |
| Grant Aid | Embassy; positive £1,000 steps; sufficient treasury. **Grant or subsidy dialog** dialog. | Transfer and relation effect in Diplomacy. |
| Set Subsidy | Embassy; Minor/Tribe only; 5–20% in steps of 5. **Grant or subsidy dialog**. | No treasury charge; active market/relation effect. |
| Boycott | Great Power target; own at least one colony; peace; no existing boycott. | Colonial trade embargo. |
| Revoke Boycott | Active boycott required. | Ends embargo. |

A non-economic decree blocks further ordinary diplomacy toward that faction that turn. Grant Aid and Set Subsidy may coexist once each; Boycott actions are separate.

### Immediate court actions

| Action | Entry point | Cost / limits |
|---|---|---|
| Disband trained worker | **Production screen** → **Labour Controls** → trained-tier **Disband**. | Immediate in **Orders**; tier −1, peasant +1; no refund. |
| Cancel pending or in-progress work | **Civilian units panel** → civilian **Cancel** → confirmation. | Pending order is removed; in-progress work clears and unit returns to origin; no material refund. |
| Split / combine armies | **Military units panel** → **Split Army**, or select same-province armies → **Combine**. | Immediate; split needs a non-empty regiment subset; combine requires same province. |
| Split / combine fleets | **Naval units panel** → **Split**, or select fleets sharing one port/sea zone → **Combine**. | Immediate; non-Home split retains one ship; Home Fleet survives empty. |
| Transfer to Home Fleet | **Naval units panel** → eligible fleet **Transfer to Home Fleet** → **Transfer to home fleet** → **Transfer**. | Immediate; selected hulls move home; source must meet capital-location rules. |

## Counsel

**Counsel.** Hark, my liege: issue related decrees together—war before invasion, prospect before mining, and workers before the banners that consume them.

**Warning.** Orders validate in submission order. The first rejected order, and those after it, do not proceed; inspect the stated reason before ending the turn.

## The other courts

Other Great Powers submit comparable decrees under the same validation and phase order. Their diplomacy may require your response through **Overture dialogue** Overture, **Call to arms dialogue overlay** Call to Arms, or **Pending intervention overlay** Intervention before resolution can continue.

## Consequences

- The turn clears its order list after resolution; reissue any intended decree next turn.
- Diplomacy precedes Research and Movement; movement precedes Build / work; World Market follows Build / work.
- **Turn news dialog** Turn news reports major outcomes after a completed turn. Inspect affected panels as news is a summary, not a complete ledger.
