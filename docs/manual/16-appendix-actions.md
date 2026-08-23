# Appendix: The Royal Decrees

## Purpose

This ledger lists every decree your court may issue. A **decree** is an action you choose on your turn — move an army, assign work, open trade, and the rest. Use it to check what each decree costs, what may refuse it, and **when you will see the result after you confirm Next turn**. Rejected decrees change nothing.

## How it is done

A **Great Power** is a playable nation at the map table. Your **Home Army** and **Home Fleet** stay at your capital; they do not march or sail on ordinary move decrees. A **Consulate** and **Embassy** are stages of diplomatic relationship with another court. **Riches** — gold, silver, gems, diamonds, and spices — never appear on the Trade screen.

### Orders issued for the next turn

| Decree | Entry point and control | Cost / chief refusal | Result appears | See |
|---|---|---|---|---|
| Move a civilian | **Spy:** `MAP20001` **Province sea-zone overlay** Civilian **Station spy**, then `UNIT10001` **Civilian units panel** **Relocate** (sends the Spy to the tile already selected; you do not pick a second tile), or `UNIT10001` idle Spy **Relocate** then a map destination. If this is your last Spy leaving that foreign land, the game asks you to confirm: full intel there will fog after the turn ends. Dismissing the ask leaves the decree unchanged. Other civilians only travel as part of the work you assign them (Chs. 4, 6). | The civilian must be yours. The destination must be land your Spy may stand on, and you must be able to see it. You cannot also assign work to that same civilian this turn. | After you confirm Next turn, during movement | Chs. 4–5 |
| Move army / invade | **Map:** tap your army stack marker on `MAP10001` (town-tile bottom-right) → `DLG20001` (or `DLG20002` when several field armies share the tile — rows show each army’s regiment mix). A non-empty Home Army in that stack with no marching field army opens Split Army then `DLG20001` for the new army. Empty Home-Army-only marker opens `UNIT20001` **Military units panel**. **Province panel:** `MAP20001` **Province sea-zone overlay** Military **Move** / **Invade** (optional `DLG20002`, or the same detach path; Invade preselects the viewed province). **Panel:** `UNIT20001` → **Move** on a non-Home Army → `DLG20001`. Invasion confirmation may add Declare War. | Free. Home Army cannot leave capital; own destinations or adjacent valid foreign targets only; war must exist or be declared on this turn, before you tap Next turn. | After Next turn, during diplomacy, then movement; battle follows if contested | Chs. 11–12 |
| Assign civilian work | `UNIT10001` **Civilian units panel** → idle unit **Assign** → target → highlighted valid map tile; `MAP20001` shortcuts may open filtered assignment; right-click a tile (or press and hold on a phone) to open `MAP30001`, a small ring of nearby civilian work (**Explore**, **Prospect**, **Build improvement**, **Build road**, **Purchase land**, **Upgrade town**, **Build port**, **Build railroad**, **Build fort**, **More**); overflow and **Province details** sit on `MAP30002`. | One pending work per unit. Target, who may stand on the tile, terrain, ownership, technology, materials, and whether another of your Builders, Engineers, or Merchants is already working that tile must all pass. | Implicit move after Next turn during movement; assignment and progress while work finishes | Chs. 4, 6 |
| Recruit / train worker | `GAME20001` **Production screen** → **Labour Controls** → tier **+** or **−**. Each labour row shows the printed cost and food/labour upkeep; locked tiers print **Requires:** technology names. | Peasant: fabric ×2. Higher tiers consume one peasant, need paper/treasury and required technologies; peasants already set aside for other training or for building regiments and ships are not free to spend again. Rest on a disabled **+** (or use the button’s accessibility text) to read the shortage. **−** takes back a queued recruit or train. | While work finishes after Next turn | Ch. 5 |
| Research | `GAME40001` **Technology screen** → **Slots** → choose technology and funding, **or** **Tree** → open a ready node → **Research this** (or replace a full seat). **Cancel** on **Slots** with progress opens a confirm; dismiss keeps the seat; confirm clears the seat and progress is forfeited when the turn is carried out, not at the tap. No progress → Cancel with no warning. Tree replace-seat uses the same forfeiture confirm. | Funding is paid from treasury; technology must be researchable, not complete, and fit an available slot. | After Next turn, during research | Ch. 9 |
| Build civilian | `UNIT10001` **Civilian units panel** → **Train** → `UNIT40001` **Train civilians** (each row shows a short line under the type name that says what that civilian does). | Treasury + paper; Merchant/Rail Builder need their unlocks; capital tile required. | While work finishes after Next turn; unit appears at capital | Ch. 5 |
| Build regiment | `UNIT20001` **Military units panel** → **Train** → `UNIT50001` **Train Military** (each row shows the regiment’s category, a short combat-role line, food upkeep per turn, and build costs). | Treasury, materials, one reserved peasant, and regiment technology. | While work finishes after Next turn; joins Home Army | Ch. 11 |
| Build ship | `UNIT30001` **Naval units panel** → **Train** → `UNIT60001` **Train Naval**. | Treasury, materials, one reserved peasant, and ship technology where required. | While work finishes after Next turn; joins Home Fleet | Ch. 13 |
| Move fleet | **Map:** tap in-port sea-going fleet marker (`MAP10001`) → `DLG30001`, or at-sea marker → `DLG31001` **Sail / Move** → `DLG30001`. **Home Fleet with ships:** harbor marker or `MAP20001` **Detach and sail** → **Detach a squadron** → `DLG30001` for the new fleet. **Panel:** `UNIT30001` **Naval units panel** → **Move** on a sea-going fleet → `DLG30001` **Move Fleet** → legal destination (sea rows may show **Hostile patrol** / **Hostile blockade** / **Hostile fleets: N**, or **Fleets unknown** when you cannot see that water). | Free. Home Fleet cannot move; only one adjacent sea/port step; ports must be yours. Replaces that fleet’s pending mission. | After Next turn, during movement | Ch. 13 |
| Assign fleet mission | **Map:** tap at-sea human fleet marker (`MAP10001`) → `DLG31003` (if needed; rows show ship mix and any pending mission) → `DLG31001` **Assign mission** → `DLG31002` for Blockade/Beachhead targets (rows show a harbor line — port or empty harbor, or harbor unknown when you lack intel — and the Blockade caption that names the warehouse / capital-link cut, plus an extra line when the target is a capital port). Home Fleet with ships detaches then sails (see Move fleet); empty Home Fleet marker opens `UNIT30001`; in-port sea-going marker opens Move. **Province panel:** `MAP20001` **Province sea-zone overlay** Naval **Blockade** / **Beachhead** on a foreign coast at war (skip `DLG31001`; `DLG31003` when several fleets qualify; target dialog preselects the viewed province). **Sea panel:** same overlay on a revealed sea you occupy with a sea-going fleet offers **Patrol** / **Defend** (skip `DLG31001` and the target dialog; `DLG31003` when several fleets qualify). Owned blockaded ports show **Under blockade** on **Naval**; **Tile details** names blockade when an owned tile is not linked to the capital. **Panel:** `UNIT30001` → **Mission** on an at-sea sea-going fleet (same flow as the map marker). **Cancel pending mission** clears a staged mission. | Free. Patrol/Blockade/Beachhead/Defend require a sea-going fleet at sea; Blockade/Beachhead need an adjacent at-war province target. A fleet moves or takes one mission, never both. Join Home Fleet: dock at capital or `DLG40001` transfer — not the mission menu. | Assignment after Next turn during movement; interceptions during naval combat. Blockade also cuts that port’s link to its capital. | Ch. 13 |
| Trade bid / offer | The **Trade** icon on the left of the map opens `GAME60001` **Trade screen** → **Market** (bid/offer/none + quantity; last-turn price move beside the price) or **Deal Book** (last-turn fills / carry-forwards). From `GAME20001` **Production screen**, tap a tradeable **Available** good to open Market already focused on that good. | Bid/offer are mutually exclusive per commodity; quantity, cargo space, treasury, stockpile, and the bid-type limit apply; riches cannot trade. | When the world market clears after Next turn | Ch. 8 |

### Work targets

| Target and unit | Cost / key refusal | Result |
|---|---|---|
| Explore — Explorer | Free; province must be partly revealed; on Minor/Tribe land with no Consulate+, `MAP20001` **Explore with explorer** and **Prospect with explorer** show visible but disabled with **Establish a consulate before exploring or prospecting** (see Diplomacy **Establish Consulate**). **`MAP30001` Explore** (right-click or press-and-hold) opens the same Explorer shortcut as `MAP20001`. | Takes up to three turns, then reveals the province. |
| Prospect — Explorer | Free; swamp, hills, mountain, or desert tiles that are visible and not yet prospected. **`MAP30001` Prospect** opens the same Explorer shortcut as `MAP20001`. | One-turn completion marks tile prospected. |
| Build improvement — Builder | Lumber + cast iron; the tile must have a resource; if the resource is a mineral, the tile must already be prospected; the next level must still be allowed by terrain and your technologies. **`MAP30001` Build improvement** opens the same Builder shortcut as `MAP20001`. | Raises improvement level. |
| Upgrade town — Builder | **National Bureaucracy**, materials, and the province town tile; town level cap 4. On your own towns, or on Minor/Tribe town tiles when at peace with **embassy-tier** overture; completing foreign work does not change ownership. **`MAP20001` Upgrade town** on the Political Town development row (and **`MAP30001` Upgrade town** when the ring opens on that town tile) opens Builder-only assignment for your owned province town tile when eligible (Assign from the panel can target embassy foreign towns). | Raises town development. |
| Build road — Engineer | Lumber + metal; terrain/road technology limits. **`MAP20001` Build road** and **`MAP30001` Build road** open Engineer-only assignment for the selected tile when eligible. | Raises transport level. |
| Build port — Engineer | Lumber + metal; coastal town or river tile that can take that province’s seaboard port (human-owned land cardinally adjacent to a sea zone whose seaboard has no port yet). **`MAP20001` Build port** and **`MAP30001` Build port** open Engineer-only assignment for the selected coastal tile when eligible; Port status (**None** / **Present**) is under **Tile details**. `GAME80001` **Development screen** → header **Counsel** → `GAME90001` **Counsel screen** **Development** tab → **Agree** (when the courts would dig a port this turn). | Creates port and transport level 4. |
| Build fort — Engineer | Materials, town tile, and fort technology where required. **`MAP20001` Build fort** and **`MAP30001` Build fort** open Engineer-only assignment for the selected town tile when eligible. | Raises fort level. |
| Build railroad — Rail Builder | Steel ×2 + lumber ×2; road level 1–2, known terrain, matching rail technology. **`MAP20001` Build railroad** and **`MAP30001` Build railroad** open Rail-Builder-only assignment for the selected tile when eligible (not on transport 0 or 4). | Sets railroad transport level 4. |
| Counter-espionage — Spy | Free; owned province. **`MAP20001` Counter-espionage** on Civilian opens Spy-only assignment for that province when eligible (protects the whole realm; one Spy is enough). One Spy on this work anywhere raises your empire-wide chance to catch enemy Spies by five percent and allows a ten-percent-per-turn defection roll against enemy Spies (after diplomacy, before research). | Ongoing while assigned. |
| Purchase land — Merchant | Embassy, peace, tile in a **Minor or Tribe** province that has a resource (not Great Power land, not your own); if the resource is a mineral, the tile must already be prospected; treasury ≥ 15× base price; not already purchased by any Great Power. **`MAP20001` Purchase land** and **`MAP30001` Purchase land** open Merchant-only assignment for the selected tile when eligible. | One-turn completion debits treasury and records the tile purchase. |

### Diplomacy

Most begin at `GAME30001` **Diplomacy screen** → select a court (which opens `GAME30002` **Diplomacy detail screen**, or use list-row actions on `GAME30001`) → choose a printed action and confirm, then resolve after Next turn during diplomacy. The first Consulate stage also has a focused entry at `MAP20001` Political when that missing relationship blocks Explore or Prospect. **Offer Peace** is also available on `MAP20001` Political when the province owner is at war with you.

**Counsel.** The Diplomacy screen also offers **Establish Favored partner**. That treaty prefers fills at the same bid rank; it does not change prices and does not beat First right of refusal.

| Decree | Cost / key refusal | Result |
|---|---|---|
| Declare War | Must be at peace; may accompany an invasion. Confirm names other courts that may be called to defend or asked to intervene. | War before movement after Next turn. |
| Offer Peace | Must be at war; target must accept. `GAME30001` row, or `MAP20001` Political when that province’s owner is at war with you. | Peace if accepted; borders unchanged. |
| Alliance | Great Power only; peace; no existing formal alliance. | Treaty if accepted. |
| Break Alliance | Formal alliance required. `GAME30001` panel **Break Alliance** confirmation is immediate for the human player. | Treaty ends immediately; same-pair alliance, overture, aid, subsidy, and Favored Trading Partner blocked until next turn; Declare War and Offer Peace remain allowed. |
| Establish Favored partner | Great Power target; Embassy; peace. Confirm names same-rank fill preference, unchanged prices, and that First right still wins. | Treaty if accepted; matching tie-break after Next turn. |
| Establish Overture | `GAME30001`, or `MAP20001` Political **Establish Consulate** for a Consulate-gated Minor/Tribe province. One stage at a time; relation, treasury, target, and technology gates apply. Stages: Trade Consulate → Embassy → Non-Aggression Pact → **Join Empire** (last stage — Great Power: Empire Building tech and nearly defeated target; Minor: absorption; Tribe: colony). | Target accepts/rejects after Next turn during diplomacy; pending Consulate may be cancelled from the same map control. |
| Grant Aid | Embassy; positive £1,000 steps; sufficient treasury. `DIPL20001` **Grant or subsidy dialog** — **Submit** stages the pending transfer (Cost / Effect shown there; no second confirmation). | Transfer and relation effect after Next turn during diplomacy. |
| Set Subsidy | Embassy; Minor/Tribe only; 5–20% in steps of 5. `DIPL20001` **Submit** stages the pending subsidy (no second confirmation). Cost / Effect name pay-more / receive-less percents on fills with that court. | No per-turn gold charge; those percents apply only to fills with that court. |
| Boycott | Great Power target; own at least one colony; peace; no existing boycott. | Confirm: no treasury charge; blocks market fills with your colony Tribes; blocks that court’s purchase land, Grant Aid, and Set Subsidy toward them; cancels their subsidies to those colonies. |
| Revoke Boycott | Active boycott required. | Confirm: no treasury charge; ends the embargo so that court may trade, purchase land, grant aid, and set subsidies toward your colony Tribes again. |

Declare War, Offer Peace, Alliance, Break Alliance, or Establish Overture toward a court blocks further ordinary diplomacy toward that same court this turn. Grant Aid and Set Subsidy may still sit together, once each. Boycott and Revoke Boycott are separate.

### Immediate court actions

| Action | Entry point | Cost / limits |
|---|---|---|
| Disband trained worker | `GAME20001` **Production screen** → **Labour Controls** → trained-tier **Disband** → confirm. | Immediate before Next turn after confirm; tier −1, peasant +1; no refund. Cancel leaves the pool unchanged. |
| Cancel pending or in-progress work | `UNIT10001` **Civilian units panel** → civilian **Cancel** → confirmation. | Pending order is removed; in-progress work clears and unit returns to origin; no material refund. |
| Split / combine armies | `UNIT20001` **Military units panel** → **Split Army**, or select same-province armies → **Combine**. Map/province-panel detach-then-move also opens Split Army (**Detach a field army**) before `DLG20001`. | Immediate; split needs a non-empty regiment subset; combine requires same province. |
| Split / combine fleets | `UNIT30001` **Naval units panel** → **Split**, or select fleets sharing one port/sea zone → **Combine**. Map **Detach and sail** also opens Home Fleet split (**Detach a squadron**) before `DLG30001`. Home Fleet split shows remaining cargo holds versus this turn’s overseas load. | Immediate; non-Home split retains one ship; Home Fleet survives empty. |
| Transfer to Home Fleet | `UNIT30001` **Naval units panel** → eligible fleet **Transfer to Home Fleet** → `DLG40001` → **Transfer**. | Immediate; selected hulls move home; the fleet must be in a port that meets the capital-port rules for transfer. A line shows remaining Home Fleet holds, this turn’s overseas load, and holds free for trade bids. |

## Counsel

**Counsel.** Hark, my liege: issue related decrees together—war before invasion, prospect before mining, and workers before the banners that consume them.

**Warning.** The game checks decrees in the order you issued them. The first one it refuses, and every decree after it, does nothing; read the stated reason before you tap Next turn.

## The other courts

Other Great Powers submit comparable decrees under the same validation and turn order. Their diplomacy may pause the turn until you answer through `OVL30001` **Overture dialogue**, `OVL40001` **Call to arms dialogue overlay**, `OVL50001` **Pending intervention overlay**, or `OVL90001` **Favored Trading Partner dialogue overlay**.

## Consequences

- After the turn finishes, staged decrees are gone; issue them again next turn if you still want them.
- Diplomacy runs before research and movement; movement before build and work; the world market clears after build and work.
- `DLG50001` **Turn news dialog** reports major outcomes after a completed turn. Inspect affected panels — news is a summary, not a complete ledger.

## Acceptance criteria for this chapter

- [ ] Lists every current order type, every civilian work target, and every diplomacy decree subtype (including Join Empire under Establish Overture).
- [ ] Gives each action an entry point, control, cost summary, refusal highlights, when the result appears after Next turn, and chapter cross-link.
- [ ] Distinguishes queued orders from immediate disband, cancellation, army/fleet organization, and Home-Fleet transfer.
- [ ] Documents `GAME60001` **Trade screen** as an operable left-side icon / route entry for the trade bid and offer decree.
- [ ] Uses only active player-manual screen IDs (debug/observe surfaces remain omitted).

## Sources

- `SPEC/program/orders.md`
- `SPEC/program/order-engine.md`
- `SPEC/program/turn-resolution-phase-details.md`
- `SPEC/program/turn-resolution-phases.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/program/development-resolution.md`
- `SPEC/game/workers-and-population.md`
- `SPEC/game/military-armies.md`
- `SPEC/game/ships-and-naval.md`
- `SPEC/game/capital-and-connectivity.md`
- `SPEC/game/diplomacy.md`
- `SPEC/ui/diplomacy-panel.md`
- `SPEC/ui/diplomacy-detail-screen.md`
- `SPEC/ui/grant-or-subsidy-dialog.md`
- `SPEC/ui/civilian-units-panel.md`
- `SPEC/ui/military-units-panel.md`
- `SPEC/ui/military-units-army-management.md`
- `SPEC/ui/naval-units-panel.md`
- `SPEC/ui/move-army-dialog.md`
- `SPEC/ui/move-fleet-dialog.md`
- `SPEC/ui/naval-mission-fleet-picker-dialog.md`
- `SPEC/ui/transfer-to-home-fleet-dialog.md`
- `SPEC/ui/province-sea-zone-detail-overlay.md`
- `SPEC/ui/overlay-army-move-picker-dialog.md`
- `SPEC/ui/naval-units-fleet-management.md`
- `SPEC/ui/naval-mission-menu-dialog.md`
- `SPEC/ui/naval-mission-target-dialog.md`
- `SPEC/ui/map-widget.md`
- `SPEC/ui/tile-context-radial.md`
- `SPEC/ui/tile-more-actions-dialog.md`
- `SPEC/ui/components/tile-radial-catalog.md`
- `SPEC/ui/tech-tree-widget.md`
- `SPEC/ui/technology-panel.md`
- `SPEC/ui/production-panel.md`
- `SPEC/ui/train-civilians-dialog.md`
- `SPEC/ui/train-military-dialog.md`
- `SPEC/ui/train-naval-dialog.md`
- `SPEC/ui/trade-screen.md`
- `SPEC/ui/development-panel.md`
- `SPEC/ui/counsel-panel.md`
- `SPEC/ui/turn-news-dialog.md`
- `SPEC/ui/overture-dialogue-overlay.md`
- `SPEC/ui/call-to-arms-dialogue-overlay.md`
- `SPEC/ui/favored-trading-partner-dialogue-overlay.md`
- `SPEC/ui/screens/pending-intervention-overlay.md`
- `SPEC/ui/empire-buttons.md`
