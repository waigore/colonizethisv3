# Appendix: The Royal Decrees

## Purpose

Use this ledger to issue every decree available to your court, check its price and limits, and know when its result will be seen. “Phase” names are the player-facing stages of the next turn; rejected decrees change nothing.

## How it is done

### Orders issued for the next turn

| Decree | Entry point and control | Cost / chief refusal | Result appears | See |
|---|---|---|---|---|
| Civilian move | **Spy:** **Province sea-zone overlay** Civilian **Station spy** then **Civilian units panel** (posts to the selected tile, no second map pick), or **Civilian units panel** idle Spy **Relocate** then map destination (soft warn if last Spy leaves foreign intel). Other civilians: implicit leg of civilian work decree only (Chs. 4, 6). | Civilian must be yours; destination land, visible, occupiable; xor with civilian work decree on same unit. | **Movement** | Chs. 4–5 |
| Army move / invasion | **Map:** tap your army stack marker on **Empire overview / map area** (town-tile bottom-right) → **Move army dialog** (or **Overlay army move picker** when several field armies share the tile — rows show each army’s regiment mix). A non-empty Home Army in that stack with no marching field army opens Split Army then **Move army dialog** for the new army. Empty Home-Army-only marker opens **Military units panel**. **Overlay:** **Province sea-zone overlay** Military **Move** / **Invade** (optional **Overlay army move picker**, or the same detach path; Invade preselects the viewed province). **Panel:** **Military units panel** → **Move** on a non-Home Army → **Move army dialog**. Invasion confirmation may add Declare War. | Free. Home Army cannot leave capital; own destinations or adjacent valid foreign targets only; war must exist or be declared in the same draft. | **Diplomacy**, then **Movement**; battle follows if contested. | Chs. 11–12 |
| Civilian work | **Civilian units panel** → idle unit **Assign** → target → highlighted valid map tile; **Province sea-zone overlay** shortcuts may open filtered assignment; **Tile context radial** / **Prospect** / **Build improvement** (right-click or press-and-hold a tile) uses the same shortcuts; **More** (**More tile actions**) **Province details** opens **Province sea-zone overlay**. | One pending work per unit; target, occupancy, terrain, ownership, technology, materials, and tile reservation must pass. | Implicit move: **Movement**; assignment/progress: **Build / work**. | Chs. 4, 6 |
| Recruit / train worker | **Production screen** → **Labour Controls** → tier **+**. Each row shows catalog cost and food/labour upkeep; locked tiers print **Requires:** technology names. | Peasant: fabric ×2. Higher tiers consume one peasant, need paper/treasury and required technologies; queued military/naval builds share the peasant reserve. Hover a disabled **+** to see the shortage. | **Build / work** | Ch. 5 |
| Research | **Technology screen** → **Slots** → choose technology and funding, **or** **Tree** → open a ready node → **Research this** (or replace a full seat). **Cancel** on **Slots** clears the slot and forfeits its progress. | Funding is paid from treasury; technology must be researchable, not complete, and fit an available slot. | **Research** | Ch. 9 |
| Build civilian | **Civilian units panel** → **Train** → **Train civilians dialog** (each row shows a muted role gist under the type name). | Treasury + paper; Merchant/Rail Builder need their unlocks; capital tile required. | **Build / work**; unit appears at capital. | Ch. 5 |
| Build regiment | **Military units panel** → **Train** → **Train military dialog** (row shows category, combat-role gist, food upkeep / turn, and build costs). | Treasury, materials, one reserved peasant, and regiment technology. | **Build / work**; joins Home Army. | Ch. 11 |
| Build ship | **Naval units panel** → **Train** → **Train naval dialog**. | Treasury, materials, one reserved peasant, and ship technology where required. | **Build / work**; joins Home Fleet. | Ch. 13 |
| Fleet move | **Map:** tap in-port sea-going fleet marker (**Empire overview / map area**) → **Move fleet dialog**, or at-sea marker → **Naval mission menu dialog** → **Move fleet dialog**. **Home Fleet with ships:** harbor marker or **Province sea-zone overlay** → **Detach a squadron** → **Move fleet dialog** for the new fleet. **Panel:** **Naval units panel** → **Move** on a sea-going fleet → **Move fleet dialog** → legal destination. | Free. Home Fleet cannot move; only one adjacent sea/port step; ports must be yours. Replaces that fleet’s pending mission. | **Movement** | Ch. 13 |
| Fleet mission | **Map:** tap at-sea human fleet marker (**Empire overview / map area**) → **Naval mission fleet picker dialog** (if needed; rows show ship mix and any pending mission) → **Naval mission menu dialog** → **Naval mission target dialog** for Blockade/Beachhead targets (rows show fog-honest defender or harbor intel). Home Fleet with ships detaches then sails (see Fleet move); empty Home Fleet marker opens **Naval units panel**; in-port sea-going marker opens Move. **Overlay:** **Province sea-zone overlay** Naval **Blockade** / **Beachhead** (skip **Naval mission menu dialog**; **Naval mission fleet picker dialog** when several fleets qualify; target dialog preselects the viewed province). **Panel:** **Naval units panel** → **Mission** on an at-sea sea-going fleet (same flow as the map marker). **Cancel pending mission** clears a staged mission. | Free. Patrol/Blockade/Beachhead/Defend require a sea-going fleet at sea; Blockade/Beachhead need an adjacent at-war province target. A fleet moves or takes one mission, never both. Join Home Fleet: dock at capital or **Transfer to home fleet** transfer — not the mission menu. | Assignment: **Movement**; interceptions: **Naval Interception & Naval Combat**. | Ch. 13 |
| Trade bid / offer | Left-rail **Trade** → **Trade screen** → **Market** (bid/offer/none + quantity; last-turn price move beside the price) or **Deal Book** (last-turn fills / carry-forwards). | Bid/offer are mutually exclusive per commodity; quantity, cargo, treasury, stockpile, and bid-type caps apply; riches cannot trade. | **World Market** | Ch. 8 |

### Work targets

| Target and unit | Cost / key refusal | Result |
|---|---|---|
| `explore` — Explorer | Free; province must be partly revealed and occupiable. **Tile context radial** (right-click or press-and-hold) opens the same Explorer shortcut as **Province sea-zone overlay**. | Reveals province on completion. |
| `prospect` — Explorer | Free; mineral-eligible, visible, occupiable unprospected tile. **Tile context radial** opens the same Explorer shortcut as **Province sea-zone overlay**. | One-turn completion marks tile prospected. |
| `build_improvement` — Builder | Lumber + cast iron; resource required; mineral must be prospected; level/tech cap applies. **Tile context radial** opens the same Builder shortcut as **Province sea-zone overlay**. | Raises improvement level. |
| `upgrade_town` — Builder | National Bureaucracy, materials, and province town tile; availability reflects current validator rules. **Province sea-zone overlay** on the Political Town development row opens Builder-only assignment for the province town tile when eligible. | Raises town development. |
| `build_road` — Engineer | Lumber + metal; terrain/road technology limits. | Raises transport level. |
| `build_port` — Engineer | Lumber + metal; valid coastal/river tile. **Province sea-zone overlay** shortcut on the Road / transport row opens Engineer-only assignment for the selected coastal tile when eligible; Port status (**None** / **Present**) is under **Tile details**. **Development screen** → **Counsel screen** Development tab can **Agree** a ranked port when the courts would dig one this turn. | Creates port and transport level 4. |
| `build_fort` — Engineer | Materials, town tile, and fort technology where required. **Province sea-zone overlay** shortcut on the Military fort row opens Engineer-only assignment for the selected town tile when eligible. | Raises fort level. |
| `build_rail` — Rail Builder | Steel ×2 + lumber ×2; road level 1–2, known terrain, matching rail technology. **Province sea-zone overlay** shortcut on the Road / railroad row opens Rail-Builder-only assignment for the selected tile when eligible (not on transport 0 or 4). | Sets railroad transport level 4. |
| `counter_spy` — Spy | Free; owned province. | Ongoing empire-wide counter-espionage effect; spy checks occur in **Spy resolution**. |
| `purchase_land` — Merchant | Embassy, peace, resource tile, prospection for minerals, and treasury ≥ 15× base price; no prior buyer. **Province sea-zone overlay** shortcut on the Tile Resource row opens Merchant-only assignment for the selected tile when eligible. | One-turn completion debits treasury and records the tile purchase. |

### Diplomacy

Most begin at **Diplomacy screen** → select faction → choose an action → confirm, then resolve in **Diplomacy**. The first Consulate stage also has a focused entry at **Province sea-zone overlay** Political when that missing relationship blocks Explore or Prospect. **Offer Peace** is also available on **Province sea-zone overlay** Political when the province owner is at war with you.

| Decree | Cost / key refusal | Result |
|---|---|---|
| Declare War | Must be at peace; may accompany an invasion. Confirm names other courts that may be called to defend or asked to intervene. | War before Movement. |
| Offer Peace | Must be at war; target must accept. **Diplomacy screen** row, or **Province sea-zone overlay** Political when that province’s owner is at war with you. | Peace if accepted; borders unchanged. |
| Alliance | Great Power only; peace; no existing formal alliance. | Treaty if accepted. |
| Break Alliance | Formal alliance required. **Diplomacy screen** panel **Break Alliance** confirmation is immediate for the human player. | Treaty ends immediately; same-pair alliance/overture/aid/subsidy blocked until next turn. |
| Establish Overture | **Diplomacy screen**, or **Province sea-zone overlay** Political **Establish Consulate** for a Consulate-gated Minor/Tribe province. One stage at a time; relation, treasury, target, and technology gates apply. | Target accepts/rejects in Diplomacy; pending Consulate may be cancelled from the same map control. |
| Grant Aid | Embassy; positive £1,000 steps; sufficient treasury. **Grant or subsidy dialog** dialog — **Submit** stages the pending transfer (Cost / Effect shown there; no second confirmation). | Transfer and relation effect in Diplomacy. |
| Set Subsidy | Embassy; Minor/Tribe only; 5–20% in steps of 5. **Grant or subsidy dialog** stages the pending subsidy (no second confirmation). | No treasury charge; active market/relation effect. |
| Boycott | Great Power target; own at least one colony; peace; no existing boycott. | Colonial trade embargo. |
| Revoke Boycott | Active boycott required. | Ends embargo. |

A non-economic decree blocks further ordinary diplomacy toward that faction that turn. Grant Aid and Set Subsidy may coexist once each; Boycott actions are separate.

### Immediate court actions

| Action | Entry point | Cost / limits |
|---|---|---|
| Disband trained worker | **Production screen** → **Labour Controls** → trained-tier **Disband**. | Immediate in **Orders**; tier −1, peasant +1; no refund. |
| Cancel pending or in-progress work | **Civilian units panel** → civilian **Cancel** → confirmation. | Pending order is removed; in-progress work clears and unit returns to origin; no material refund. |
| Split / combine armies | **Military units panel** → **Split Army**, or select same-province armies → **Combine**. Map/overlay detach-then-move also opens Split Army (**Detach a field army**) before **Move army dialog**. | Immediate; split needs a non-empty regiment subset; combine requires same province. |
| Split / combine fleets | **Naval units panel** → **Split**, or select fleets sharing one port/sea zone → **Combine**. Map **Detach and sail** also opens Home Fleet split (**Detach a squadron**) before **Move fleet dialog**. Home Fleet split shows remaining cargo holds versus this turn’s overseas load. | Immediate; non-Home split retains one ship; Home Fleet survives empty. |
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
