# Appendix: The Royal Decrees

## Purpose

A **decree** is an action you choose on your turn. Use this ledger to check each decree’s price and limits, and to know **when you will see the result after you confirm Next turn**. A **Great Power** is a playable nation. A **Minor Nation** is an Old World neighbour you do not play. A **Tribe** is a New World people. The **Home Army** and **Home Fleet** stay at the capital. A **Consulate** and an **Embassy** are relationship stages with another court. **Riches** are gold, silver, gems, diamonds, and spices; they do not go on the Trade screen.

## How it is done

### Orders issued for the next turn

| Decree | Entry point and control | Cost / chief refusal | Result appears | See |
|---|---|---|---|---|
| Move a civilian | **Spy:** `MAP20001` **Province sea-zone overlay** Civilian **Station spy**, then `UNIT10001` **Civilian units panel** **Relocate** (that shortcut uses the tile already selected; you do not pick a second tile), or `UNIT10001` idle Spy **Relocate** then pick a land destination. If this is your last Spy leaving that foreign land, the game asks you to confirm: full intel there will fog after the turn ends. Dismissing the ask leaves the decree unchanged. Other civilians only travel as part of the work you assign them (Chs. 4, 6). | The civilian must be yours. The destination must be land your unit may stand on, and you must be able to see it. You cannot also assign work to that same civilian this turn. | After you confirm **Next turn**, during movement. | Chs. 4–5 |
| Move army / invade | **Map:** tap your army stack marker on `MAP10001` **Empire overview / map area** (town-tile bottom-right) → `DLG20001` **Move army dialog** (or `DLG20002` **Overlay army move picker** when several field armies share the tile — rows show each army’s regiment mix). A non-empty Home Army in that stack with no marching field army opens Split Army, then `DLG20001` for the new army. An empty Home-Army-only marker opens `UNIT20001` **Military units panel**. **Province panel:** `MAP20001` **Province sea-zone overlay** Military **Move** / **Invade** (optional `DLG20002`, or the same detach path; Invade preselects the viewed province). **Panel:** `UNIT20001` **Military units panel** → **Move** on a non-Home Army → `DLG20001`. Invasion confirmation may add Declare War. | Free. The Home Army cannot leave the capital. Destinations must be yours or adjacent valid foreign land. War must already exist, or you must declare it on this turn, before you tap **Next turn**. | After you confirm **Next turn**, diplomacy first, then movement; a battle follows if the land is contested. | Chs. 11–12 |
| Assign civilian work | `UNIT10001` **Civilian units panel** → idle unit **Assign** → choose the work → highlighted valid map tile. `MAP20001` **Province sea-zone overlay** shortcuts may open the civilian panel showing only the matching workers. Right-click a tile (or press and hold on a phone) to open `MAP30001`, a small ring of nearby actions (**Explore**, **Prospect**, **Build improvement**, **More**). **More** (`MAP30002` **More tile actions**) **Province details** opens `MAP20001`. | One pending work per unit. The destination must be a land tile that unit may stand on. Another of your Builders, Engineers, or Merchants must not already be working that tile. Terrain, ownership, technology, and materials must allow the work. | Travel with the assignment: after **Next turn**, during movement. The work itself finishes later in that same turn. | Chs. 4, 6 |
| Recruit / train worker | `GAME20001` **Production screen** → **Labour Controls** → tier **+**. Each labour row shows the printed cost and food/labour upkeep. Locked tiers print **Requires:** technology names. Rest on a disabled **+** (or use the button’s accessibility text) to read the shortage. **−** takes back a queued recruit or train. Peasant rows have no **Disband**. Peasants already set aside for other training or for building regiments and ships are not free to spend again. | Peasant: fabric ×2. Higher tiers consume one peasant, need paper/treasury and the required technologies. | After you confirm **Next turn**, while work finishes. | Ch. 5 |
| Research | `GAME40001` **Technology screen** → **Slots** → choose technology and funding, **or** **Tree** → open a ready node → **Research this** (or replace a full seat). **Cancel** on **Slots** with no progress clears the seat at once. If the technology already has progress, the game asks you to confirm; dismiss keeps the seat. Confirming **Cancel** (or replacing a seat on the Tree with the same warning) forfeits that progress when the turn is carried out, not at the tap. | Funding is paid from treasury. The technology must be researchable, not already unlocked, and fit an available seat. | After you confirm **Next turn**, when research applies. | Ch. 9 |
| Build civilian | `UNIT10001` **Civilian units panel** → **Train** → `UNIT40001` **Train civilians dialog**. Each row shows a short line under the type name that says what that civilian does. | Treasury + paper. Merchant and Rail Builder need their unlocks. Training happens at the capital. | After you confirm **Next turn**, while work finishes; the unit appears at the capital. | Ch. 5 |
| Build regiment | `UNIT20001` **Military units panel** → **Train** → `UNIT50001` **Train Military**. Each row shows the regiment’s category, a short combat-role line, food upkeep per turn, and build costs. | Treasury, materials, one reserved peasant, and the regiment’s technology. | After you confirm **Next turn**, while work finishes; the regiment joins the Home Army. | Ch. 11 |
| Build ship | `UNIT30001` **Naval units panel** → **Train** → `UNIT60001` **Train Naval**. | Treasury, materials, one reserved peasant, and the ship’s technology where required. | After you confirm **Next turn**, while work finishes; the ship joins the Home Fleet. | Ch. 13 |
| Move fleet | **Map:** tap an in-port sea-going fleet marker on `MAP10001` **Empire overview / map area** → `DLG30001` **Move fleet dialog**, or an at-sea marker → `DLG31001` **Naval mission menu dialog** **Sail / Move** → `DLG30001`. **Home Fleet with ships:** harbor marker or `MAP20001` **Province sea-zone overlay** **Detach and sail** → **Detach a squadron** → `DLG30001` for the new fleet. **Panel:** `UNIT30001` **Naval units panel** → **Move** on a sea-going fleet → `DLG30001` → legal destination. | Free. The Home Fleet cannot move. Only one adjacent sea or port step. Ports must be yours. This replaces that fleet’s pending mission. | After you confirm **Next turn**, during movement. | Ch. 13 |
| Fleet mission | **Map:** tap an at-sea human fleet marker on `MAP10001` → `DLG31003` **Naval mission fleet picker dialog** (if needed; rows show ship mix and any pending mission) → `DLG31001` **Assign mission** → `DLG31002` **Naval mission target dialog** for Blockade/Beachhead. Blockade rows show a harbor line (port or empty harbor, or harbor unknown when you lack intel) and a caption that names the warehouse link to the capital is cut, plus an extra line when the target is a capital port. Home Fleet with ships detaches then sails (see Move fleet); an empty Home Fleet marker opens `UNIT30001` **Naval units panel**; an in-port sea-going marker opens Move. **Province panel:** `MAP20001` Naval **Blockade** / **Beachhead** (skip `DLG31001`; `DLG31003` when several fleets qualify; the target dialog preselects the viewed province). Owned blockaded ports show **Under blockade** on **Naval**; **Tile details** names blockade when an owned tile is not linked to the capital. **Panel:** `UNIT30001` → **Mission** on an at-sea sea-going fleet. **Cancel pending mission** clears a staged mission. | Free. Patrol, Blockade, Beachhead, and Defend need a sea-going fleet at sea. Blockade and Beachhead need an adjacent at-war province. A fleet moves or takes one mission, never both. Join Home Fleet: dock at the capital, or `DLG40001` **Transfer to home fleet** — not the mission menu. | After you confirm **Next turn**, during movement; fighting at sea happens while naval work finishes. Blockade also cuts that port’s link to its capital. | Ch. 13 |
| Trade bid / offer | The **Trade** icon on the left of the map opens `GAME60001` **Trade screen** → **Market** (bid / offer / none + quantity; last-turn price move beside the price) or **Deal Book** (last-turn fills / carry-forwards). | Bid and offer cannot both sit on the same good. Quantity, cargo space, treasury, stockpile, and the bid-type limit apply. Riches cannot trade. | After you confirm **Next turn**, when the world market clears. | Ch. 8 |

### Work targets

| Target and unit | Cost / key refusal | Result |
|---|---|---|
| Explore — Explorer | Free. The province must be partly revealed. On Minor or Tribe land with no Consulate or higher, `MAP20001` **Province sea-zone overlay** shows **Explore with explorer** visible but disabled, with **Establish a consulate before exploring or prospecting**; use the Political **Establish Consulate** shortcut (see Diplomacy). `MAP30001` **Explore** opens the same Explorer shortcut as `MAP20001`. | Takes up to three turns, then reveals the province. |
| Prospect — Explorer | Free. Swamp, hills, mountain, or desert tiles that are visible and not yet prospected. The same Consulate requirement as Explore applies on Minor or Tribe land. `MAP20001` prints **Prospect with explorer**; `MAP30001` **Prospect** opens the same shortcut. | Completes in one turn and marks the tile prospected. |
| Build improvement — Builder | Lumber + cast iron. The tile must have a resource. Minerals must already be prospected. The next level must still be allowed by terrain and your technologies. `MAP20001` **Build improvement**; `MAP30001` **Build improvement** opens the same Builder shortcut. | Raises the improvement level. |
| Upgrade town — Builder | **National Bureaucracy**, materials, and a province **town** tile. Cap 4. Owned towns, **or** Minor or Tribe town tiles when at **peace** with an **Embassy**. Completing foreign work does **not** change ownership. `MAP20001` **Upgrade town** on the Political Town development row is for a human-owned town only; Embassy foreign towns use **Assign**. | Raises town development. |
| Build road — Engineer | Lumber + metal; terrain and road technology limits. `MAP20001` **Build road** on the Road / railroad row opens Engineer-only assignment for the selected tile when eligible (same shortcut pattern as Build port). | Raises transport level. |
| Build port — Engineer | Lumber + metal. Coastal **town** or river tile that can take that province’s seaboard port (human-owned land next to a sea zone whose seaboard has no port yet). `MAP20001` **Build port** on the Road / transport row opens Engineer-only assignment for the selected coastal tile when eligible. Port status (**None** / **Present**) is under **Tile details**. `GAME80001` **Development screen** → header **Counsel** → `GAME90001` **Counsel screen** **Development** tab → **Agree** (when the courts would dig a port this turn). | Creates a port and sets transport level 4. |
| Build fort — Engineer | Materials, a town tile, and fort technology where required. `MAP20001` **Build fort** on the Military fort row opens Engineer-only assignment for the selected town tile when eligible. | Raises fort level. |
| Build railroad — Rail Builder | Steel ×2 + lumber ×2; road level 1–2, known terrain, matching rail technology. `MAP20001` **Build railroad** on the Road / railroad row opens Rail-Builder-only assignment for the selected tile when eligible (not on transport 0 or 4). | Sets railroad transport level 4. |
| Counter-espionage — Spy | Free; owned province. Assign from `UNIT10001` **Civilian units panel** **Assign**. | One Spy on this work anywhere gives your whole realm **+5%** chance to catch enemy Spies, and a **10%** chance each turn that an enemy Spy switches sides, after diplomacy and before research. |
| Purchase land — Merchant | Embassy, peace, and a resource tile in a **Minor or Tribe** province (not Great Power land, not your own). If the resource is a mineral, the tile must already be prospected. Treasury ≥ 15× base price. No Great Power may already have bought that tile. `MAP20001` **Purchase land** on the Tile Resource row opens Merchant-only assignment when eligible. | Completes in one turn; then treasury is charged and the purchase is recorded. |

### Diplomacy

Most decrees begin at `GAME30001` **Diplomacy screen**. Tap a court to open `GAME30002` **Diplomacy detail screen**, then choose a printed action and confirm. List-row actions also exist on `GAME30001`. Grant Aid and Set Subsidy use `DIPL20001` **Grant or subsidy dialog** **Submit** with no second confirm. Results appear after you confirm **Next turn**, during diplomacy. The first Consulate stage also has a focused entry at `MAP20001` **Province sea-zone overlay** Political when that missing relationship blocks Explore or Prospect. **Offer Peace** is also available on `MAP20001` Political when the province owner is at war with you.

| Decree | Cost / key refusal | Result |
|---|---|---|
| Declare War | Must be at peace; may accompany an invasion. Confirm names other courts that may be called to defend or asked to intervene. | War before movement. |
| Offer Peace | Must be at war; the target must accept. `GAME30001` row, or `MAP20001` Political when that province’s owner is at war with you. | Peace if accepted; borders unchanged. |
| Alliance | Great Power only; peace; no existing formal alliance. | Treaty if accepted. |
| Break Alliance | Formal alliance required. `GAME30001` **Break Alliance** confirmation is immediate for the human player. Until next turn, alliance, overture, **Establish FTP**, aid, and subsidy toward that same court are blocked. **Declare War** and **Offer Peace** remain allowed. | Treaty ends immediately. |
| Establish Overture | `GAME30001` / `GAME30002`, or `MAP20001` Political **Establish Consulate** for a Minor or Tribe province that still needs a Consulate. One stage at a time (Consulate → Embassy → Non-Aggression Pact → **Join Empire**). Relation, treasury, target, and technology requirements apply. | The target accepts or rejects during diplomacy; a pending Consulate may be cancelled from the same map control. |
| Join Empire | Last Establish Overture stage. Great Power target: **Empire Building** and a nearly defeated court (it no longer holds its original capital). Minor Nation: Friendly or Allied standing and the Join Empire gold cost; acceptance absorbs that court. Tribe: the same last stage creates a **colony** (provinces stay with the Tribe). | After you confirm **Next turn**, during diplomacy. |
| Grant Aid | Embassy; positive £1,000 steps; sufficient treasury. `DIPL20001` **Grant or subsidy dialog** — **Submit** stages the pending transfer (Cost / Effect shown there; no second confirmation). | Transfer and relation effect during diplomacy. |
| Set Subsidy | Embassy; Minor/Tribe only; 5–20% in steps of 5. `DIPL20001` **Submit** stages the pending subsidy (no second confirmation). | No treasury charge; active market/relation effect. |
| Boycott | Great Power target; own at least one colony; peace; no existing boycott. | Colonial trade embargo. |
| Revoke Boycott | Active boycott required. | Ends embargo. |

Declare War, Offer Peace, Alliance, Break Alliance, or Establish Overture toward a court blocks further ordinary diplomacy toward that same court this turn. Grant Aid and Set Subsidy may still sit together, once each. Boycott and Revoke Boycott are separate.

### Immediate court actions

| Action | Entry point | Cost / limits |
|---|---|---|
| Disband trained worker | `GAME20001` **Production screen** → **Labour Controls** → trained-tier **Disband**. | Immediate when you tap: that tier −1, peasant +1; no refund. |
| Cancel pending or in-progress work | `UNIT10001` **Civilian units panel** → civilian **Cancel** → confirmation. | Pending work is removed. In-progress work clears and the unit returns to where it started; no material refund. |
| Split / combine armies | `UNIT20001` **Military units panel** → **Split Army**, or select same-province armies → **Combine**. Map or `MAP20001` detaching then moving also opens Split Army (**Detach a field army**) before `DLG20001` **Move army dialog**. | Immediate; split needs a non-empty regiment subset; combine requires the same province. |
| Split / combine fleets | `UNIT30001` **Naval units panel** → **Split**, or select fleets sharing one port or sea zone → **Combine**. Map **Detach and sail** also opens Home Fleet split (**Detach a squadron**) before `DLG30001` **Move fleet dialog**. Home Fleet split shows remaining cargo holds versus this turn’s overseas load. | Immediate; a split that is not the Home Fleet keeps one ship; the Home Fleet can stay empty. |
| Transfer to Home Fleet | `UNIT30001` **Naval units panel** → eligible fleet **Transfer to Home Fleet** → `DLG40001` **Transfer to home fleet** → **Transfer**. | Immediate; selected ships move home. The fleet must be in a port that meets the capital-port rules for transfer. |

## Counsel

**Counsel.** Hark, my liege: issue related decrees together—war before invasion, prospect before mining, and workers before the banners that consume them.

**Warning.** The game checks decrees in the order you issued them. The first one it refuses, and every decree after it, does nothing; read the stated reason before you tap **Next turn**.

**Tip.** `GAME30001` **Diplomacy screen** offers **Establish FTP** on Great Power rows. This appendix does not give that action its own decree row, because the screen and the written decree list disagree on the type. Both facts are recorded here; neither is treated as the winner.

## The other courts

Other Great Powers issue comparable decrees under the same checks and the same order of results after **Next turn**. Rival diplomacy may pause the turn until you answer through `OVL30001` **Overture dialogue**, `OVL40001` **Call to arms dialogue overlay**, or `OVL50001` **Pending intervention overlay**.

## Consequences

- After the turn finishes, staged decrees are gone; issue them again next turn if you still want them.
- Diplomacy is carried out before research and movement; movement is carried out before civilian work finishes; the world market clears after that work.
- `DLG50001` **Turn news dialog** reports major outcomes after a completed turn. Inspect affected panels; news is a summary, not a complete ledger.

## Acceptance criteria for this chapter

- [x] Lists every current player decree, every civilian work target, and every diplomacy action, including **Join Empire**.
- [x] Gives each action an entry point, control, cost summary, refusal highlights, when the result appears after **Next turn**, and a chapter cross-link.
- [x] Distinguishes queued decrees from immediate disband, cancellation, army/fleet organization, and Home-Fleet transfer.
- [x] Documents `GAME60001` **Trade screen** as an operable left-side icon / route entry for the trade bid and offer decree.
- [x] Uses only active player-manual screen IDs (debug/observe surfaces remain omitted).

## Sources

- `SPEC/program/orders.md`
- `SPEC/program/order-engine.md`
- `SPEC/program/turn-resolution-phase-details.md`
- `SPEC/program/turn-resolution-phases.md`
- `SPEC/program/development-resolution.md`
- `SPEC/game/workers-and-population.md`
- `SPEC/game/military-armies.md`
- `SPEC/game/ships-and-naval.md`
- `SPEC/game/diplomacy.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ui/empire-buttons.md`
- `SPEC/ui/diplomacy-panel.md`
- `SPEC/ui/diplomacy-detail-screen.md`
- `SPEC/ui/grant-or-subsidy-dialog.md`
- `SPEC/ui/civilian-units-panel.md`
- `SPEC/ui/military-units-panel.md`
- `SPEC/ui/military-units-army-management.md`
- `SPEC/ui/naval-units-panel.md`
- `SPEC/ui/naval-units-fleet-management.md`
- `SPEC/ui/move-army-dialog.md`
- `SPEC/ui/move-fleet-dialog.md`
- `SPEC/ui/overlay-army-move-picker-dialog.md`
- `SPEC/ui/naval-mission-menu-dialog.md`
- `SPEC/ui/naval-mission-target-dialog.md`
- `SPEC/ui/naval-mission-fleet-picker-dialog.md`
- `SPEC/ui/transfer-to-home-fleet-dialog.md`
- `SPEC/ui/province-sea-zone-detail-overlay.md`
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
- `SPEC/ui/screens/pending-intervention-overlay.md`
