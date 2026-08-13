# Mastery of the Seas

## Purpose

A navy connects a realm that land armies cannot reach. Merchant hulls in your **Home Fleet** carry overseas extraction and trade cargo; sea-going fleets reveal coasts, protect routes, threaten ports, and prepare invasions. A fleet at sea is also exposed to hostile interception, so naval strength is both an opportunity and a commitment.

Ships are either **in port** at an owned province or **at sea** in a sea zone. Ports and sea zones connect only where the map’s naval topology provides an edge. Fleets may never dock in an enemy or neutral province.

## How it is done

### Raise ships for the realm

1. From **Naval units panel**, select **Train** to open **Train naval dialog**.
2. Each ship requires treasury, its listed materials, and one available Peasant. Each row also shows its **role** (Merchant or Warship) and a one-line capability gist — cargo holds for merchants, combat role for warships — so you can choose hulls before committing. The dialog subtracts pending choices from its resource bar, so queue only ships the realm can afford together.
3. A locked row names its required technology. Research it before queuing the hull; the **Carrack** is the sole starting merchant and needs no technology.
4. Close the dialog to commit the chosen build orders. During turn resolution, successful builds deduct their costs and place their new hulls in the Home Fleet at the capital.

| Ship | Role | Required technology |
|---|---|---|
| Carrack | Merchant | None |
| Fluyte | Merchant | Superior Hull Design |
| Sloop | Warship / fast interceptor | Navigation |
| Trader | Merchant | Improved Sail Design |
| Galleon | Merchant / battle ship | Convoying |
| Indiaman | Merchant | Large Hulls |
| Frigate | Warship / fast interceptor | Advanced Hull Design |
| Raider | Warship / fast interceptor | Paddlewheels |
| Ship of the Line | Warship / battle ship | Ship of the Line |
| Clipper | Merchant | Clipper Ships |
| Merchant Steamship | Merchant | Merchant Steamships |
| Ironclad | Warship / battle ship | Advanced Iron Working |

Merchant ships add cargo holds; warships add none. Every ship consumes two food each turn. Faster interceptors are best at catching or escaping fleets, while battle ships bring heavier firepower, armour, and hull strength.

### Read the Home Fleet and make a squadron

The **Naval units panel** lists every fleet by region and location. Your Home Fleet is pinned first in the capital’s region, even when empty. Expand it to inspect its ships, strength, and total cargo holds.

The Home Fleet remains docked at the capital. Its merchant cargo holds are the realm’s total overseas transport and trade capacity for the turn. Split ships from it when you need a sea-going squadron; the new fleet begins at the same location and can then receive movement and mission orders.

On the in-game map shell (**Game screen**), the tab bar shows a compact **cargo** readout (`used/capacity`) beside your treasury. Tap it for a plain-language breakdown: overseas extraction load, total Home Fleet holds, and how many holds remain open for trade bids. The numbers turn a warm accent when holds are tight and red when full — a quiet warning, not a popup.

### Move a sea-going fleet

1. In **Naval units panel**, select **Move** beside a sea-going fleet to open **Move fleet dialog**. You can also open the same dialog from the map: tap an **in-port** sea-going fleet marker, or tap **Sail / Move** on **Naval mission menu dialog** when the fleet is already at sea.
2. Select one legal adjacent destination and confirm. A fleet at sea may move sea zone to sea zone, or dock at an adjacent **owned** port. A fleet in port may undock only into an adjacent sea zone.
3. Port-to-port moves and multi-hop moves are not available. Docking at the capital merges the arriving fleet into the Home Fleet when the turn resolves.
4. Entering a sea zone reveals its water and the coastal edge of adjacent provinces for your realm.

A move order replaces that fleet’s earlier move order and clears its pending mission for the turn. A fleet can move or perform one mission, never both.

### Assign a naval mission

Only a sea-going fleet **at sea** may patrol, blockade, establish a beachhead, or defend. The Home Fleet cannot receive those missions. Fleets **in port** must undock (move to an adjacent sea zone) before missions are offered.

**Map shortcut (primary):** Tap your **fleet marker** on the map (**Empire overview / map area**). When multiple fleets share the marker, choose which fleet in **Naval mission fleet picker dialog**. What opens next depends on that fleet:

- **Home Fleet** — opens **Naval units panel** Naval Units scoped to that port so you can Split or Train without a dead-end tap.
- **Sea-going fleet in port** — opens **Move fleet dialog** so you can undock immediately.
- **Sea-going fleet at sea** — opens **Naval mission menu dialog** (Patrol / Defend / Blockade / Beachhead, plus **Cancel pending mission** when a mission is staged). Use **Sail / Move** on that menu to open **Move fleet dialog** without returning to the rail panel. Blockade and Beachhead open **Naval mission target dialog** so you choose an adjacent enemy province at war with you.

**Panel parity:** In **Naval units panel**, tap **Mission** on an eligible at-sea fleet row for the same **Naval mission menu dialog** flow (including **Sail / Move**). The row shows a pending mission line after you confirm (for example `On mission: Patrol` or `Blockade → <province>`).

- **Patrol:** Remain in the current sea zone and attempt to intercept hostile fleets moving through it, including hostile patrols and blockaders.
- **Blockade:** Remain in a sea zone adjacent to the target enemy province’s port. The blockader has a stronger interception chance against hostile fleets entering that sea zone, including fleets leaving the blockaded port.
- **Beachhead:** Remain at sea beside a hostile coastal province to establish a landing site. On the following turn, eligible friendly land units may invade that province; the marker expires after that invasion resolves, or after that following turn if no invasion occurs.
- **Defend:** Remain in place without actively seeking combat. Defending fleets can still be attacked or drawn into combat by hostile patrols or blockades.

A fleet may have a pending **move** or a pending **mission** for the turn, never both. Staging a mission clears any pending move for that fleet, and vice versa.

**Join Home Fleet** is not assigned through the mission menu. Dock a regular fleet at your capital (merging into the Home Fleet) or use **Transfer to Home Fleet** (**Transfer to home fleet**) from **Naval units panel** when already in port at the capital.

### Transfer selected ships home

For a regular fleet at the capital port, choose **Transfer to Home Fleet** in **Naval units panel** to open **Transfer to home fleet**.

1. Move one or more ship types from the source list to the Home Fleet list.
2. Confirm **Transfer**. The selected hulls retain their identity and join the Home Fleet immediately.
3. A regular fleet that gives up every ship is removed; the Home Fleet remains, even with no ships.

Use this for returning only merchants to carry cargo while leaving a warship squadron assembled, or for placing escorts with the ships that carry your overseas goods.

## Counsel

**Counsel.** Hark, my liege: cargo ships win no battle, yet a victorious navy without Home-Fleet holds cannot bring distant bounty to your warehouses. Keep enough merchants at the capital for the trade and transport upon which your plans depend.

**Warning.** A port is shelter, not a battlefield. Fleets in port do not join naval combat, but must leave port into an adjacent sea zone before they can operate — and a blockader may intercept them there.

**Tip.** Return a fleet to the capital by docking it there when possible. That both ends its voyage and restores its hulls to the cargo fleet without a separate sea-going station.

## The other courts

Other Great Powers plan naval activity as part of their strategic phase. In colonial phases, their naval planners prioritise New World sea zones, ports, beachheads, and invasion-transport targets; priority provinces receive stronger preference. In the more cautious colonial-lite phase, they can pursue New World exploration and cargo activity, but not invasion transport.

Their leaders also shape the danger. Victoria and Henry favour naval research and ships; Isabella favours exploration vessels; de Ruyter favours trade ships; Napoleon and Gustavus can support fleets alongside military ambitions. A rival’s chosen personality and hidden agenda influence its wider willingness to fight, trade, or pursue hostile policy.

## Consequences

- A ship built successfully joins the Home Fleet, increasing cargo capacity only while it remains there.
- Moving a fleet into a sea zone can expose new coasts, but it also creates opportunities for patrols and blockades to intercept it.
- Naval combat occurs only between opposing fleets at sea in the same sea zone. An interception can create combat when a patrol or blockade catches a mover; combat also follows when hostile fleets finish movement together.
- Combat aggregates ship firepower, range, armour, hull, and movement. Fleets may retreat only to an adjacent friendly or neutral sea zone free of hostile fleets; failure to retreat causes further losses.
- Blockades are particularly dangerous to a port’s outbound fleet: ships safely docked do not fight, but become interceptable when they undock into the blockader’s sea zone.
- The Home Fleet cannot sail because it is the permanent capital-port fleet that supplies the realm’s transport and trade capacity. Ships must first be split into a separate sea-going fleet before they can move or take missions.
