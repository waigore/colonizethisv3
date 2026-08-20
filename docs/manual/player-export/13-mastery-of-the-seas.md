# Mastery of the Seas

## Purpose

A navy connects a realm that land armies cannot reach. The **Home Fleet** is the permanent fleet at your capital port (it supplies cargo capacity and cannot sail). Merchant hulls in that fleet carry **extraction** — goods brought home from overseas provinces — and trade cargo. Sea-going fleets reveal coasts, protect routes, threaten ports, and prepare invasions. A fleet at sea is also exposed to **interception**: a patrol or blockade may try to catch a moving fleet. Naval strength is both an opportunity and a commitment.

Ships are either **in port** at an owned province or **at sea** in a **sea zone** (a named stretch of water). Ports and sea zones connect only where the map shows they touch. You can sail from a port into a neighbouring sea, or from one sea into a neighbouring sea — not by skipping across the map. Fleets may never dock in an enemy or neutral province.

The **Old World** and the **New World** are the two maps. The New World is the overseas map. Rival **Great Powers** (playable nations) also raise fleets and send them to sea.

## How it is done

### Raise ships for the realm

1. On **Game screen**, tap **Naval Units** on the left of the map to open **Naval units panel**.
2. Tap **Train** to open **Train naval dialog** (header **Train Naval**).
3. Each ship requires treasury, its listed materials, and one available **Peasant** (one worker spent to build a ship). The **Peasants** chip shows how many remain free after peasants already promised to queued worker training or regiment builds; when some are promised, a short line under the chips names that promise. Tap the **Peasants** chip for a short family breakdown. **+** will not raise a count past the free peasant total. Each row also shows its **role** (**Merchant** or **Warship**) and a one-line summary — cargo holds for merchants, combat role for warships — so you can choose hulls before committing. The dialog subtracts pending choices from its resource bar, so queue only ships the realm can afford together.
4. A locked row names its required technology. Research it before queuing the hull; the **Carrack** is the sole starting merchant and needs no technology.
5. Close the dialog to queue the chosen ships. After you confirm **Next turn**, the game deducts the costs and the new hulls appear in the Home Fleet at the capital. You see them when that finishes — not when you close the dialog.

| Ship | Role (Train Naval) | Required technology |
|---|---|---|
| Carrack | Merchant | None |
| Fluyte | Merchant | Superior Hull Design |
| Sloop | Warship | Navigation |
| Trader | Merchant | Improved Sail Design |
| Galleon | Merchant | Convoying |
| Indiaman | Merchant | Large Hulls |
| Frigate | Warship | Advanced Hull Design |
| Raider | Warship | Paddlewheels |
| Ship of the Line | Warship | Ship of the Line |
| Clipper | Merchant | Clipper Ships |
| Merchant Steamship | Merchant | Merchant Steamships |
| Ironclad | Warship | Advanced Iron Working |

Merchant ships add cargo holds; warships add none. Every ship consumes two food each turn. Faster interceptors (Sloops, Frigates, Raiders) are best at catching or escaping fleets. Ships of the Line and Ironclads bring heavier firepower, armour, and hull strength.

### Read cargo on the map

On **Game screen**, the row with the **Old World** and **New World** tabs on **Empire overview / map area** shows a crate and `used/capacity` beside your treasury. Tap it for a plain-language breakdown: overseas extraction load, total Home Fleet holds, and how many holds remain open for trade bids. The numbers turn a warm accent when used is at least 80% of capacity but still below capacity, and red when used is at or over capacity — a quiet warning, not a popup.

### Read the Home Fleet, split, and combine

The **Naval units panel** lists every fleet by region and location. Your Home Fleet is pinned first in the capital’s region, even when empty. Expand it to inspect its ships, strength, and total cargo holds.

The Home Fleet remains docked at the capital. Its merchant cargo holds are the realm’s total overseas transport and trade capacity for the turn. Split ships from it when you need a sea-going squadron; the new fleet begins at the same port and can then receive movement and mission orders.

**Split from the panel** (does not open **Move fleet** by itself):

1. In **Naval units panel**, tap **Split** on a fleet row. The dialog title is **Split Fleet**.
2. Move the ship types you want into the new fleet.
3. Confirm **Confirm Split**. The new fleet stays at the same port (or the same sea, if you split a fleet already at sea).
4. Then tap **Move** on that new fleet if you want it to sail.

When you split the Home Fleet, a line under the transfer lists how many cargo holds will remain versus this turn’s overseas load. The numbers change as you move merchant hulls. A warm accent means no spare holds; red means remaining holds would fall short. The game still lets you confirm a legal split — leaving merchants home is a real trade-off, not a blocked tap.

**Combine** (happens at once, not after **Next turn**):

1. In **Naval units panel**, check two or more fleets that share the same port or the same sea.
2. Tap **Combine** at the top of the panel.
3. Those fleets merge immediately. If the Home Fleet is among the checked fleets, the other checked fleets join it. Empty non-Home fleets are removed.

### Send a squadron to sea from the map

This path is separate from panel **Split**. It detaches ships and then opens **Move fleet** for the new fleet.

1. Tap the **Home Fleet** marker at your capital harbor on **Empire overview / map area**, or tap **Detach and sail** on **Province sea-zone overlay** **Naval** when you have ships at home.
2. The dialog title is **Detach a squadron**. Choose which ship types leave.
3. Confirm **Detach and choose destination**.
4. On **Move fleet dialog** (title **Move fleet — Fleet \<id\>**), pick an adjacent sea and confirm. The Home Fleet stays in port.

If the Home Fleet has no ships, the harbor marker still opens **Naval units panel** so you can **Train**.

**Detach and sail** on your owned capital is hidden when you are only watching the game, on a foreign coast, or on a sea zone.

### Move a sea-going fleet

1. In **Naval units panel**, tap **Move** beside a sea-going fleet to open **Move fleet dialog** (title **Move fleet — Fleet \<id\>**).
2. Select one legal adjacent destination and confirm.
3. A fleet at sea may move sea to neighbouring sea, or dock at an adjacent **owned** port. A fleet in port may undock only into an adjacent sea.
4. Some adjacent seas are passages to the other map. Those rows add **links to** the other region (**Old World** or **New World**). Still one hop per order — no skipping across the map, and no port-to-port hops.
5. Docking at the capital merges the arriving fleet into the Home Fleet when you confirm **Next turn** and that turn finishes.

Entering a sea zone reveals its water and the coastal edge of adjacent provinces for your realm.

A move order replaces that fleet’s earlier move order and clears its pending mission for the turn. A fleet can move or perform one mission, never both.

You can also open the same **Move fleet** dialog from the map: tap an **in-port** sea-going fleet marker, or tap **Sail / Move** on **Naval mission menu dialog** when the fleet is already at sea.

### Assign a naval mission

Only a sea-going fleet **at sea** may patrol, blockade, establish a beachhead, or defend. The Home Fleet cannot receive those missions. Fleets **in port** must undock (move to an adjacent sea) before missions are offered.

**From a fleet marker on the map:**

1. Tap your fleet marker on **Empire overview / map area**.
2. If several fleets share the marker, pick one in **Naval mission fleet picker dialog** (title **Select fleet**). Each row shows that fleet’s ship mix, and a pending mission line when one is already staged.
3. If you picked the **Home Fleet with ships**, the next dialog is **Detach a squadron**, then **Move fleet dialog** for the new sea-going fleet. The Home Fleet itself cannot sail.
4. If you picked the **Home Fleet with no ships**, **Naval units panel** opens for that port so you can **Train**.
5. If you picked a **sea-going fleet in port**, **Move fleet dialog** opens so you can undock.
6. If you picked a **sea-going fleet at sea**, **Naval mission menu dialog** (title **Assign mission — Fleet \<id\>**) opens. Use **Sail / Move** on that menu to open **Move fleet dialog** without going back to the left-side **Naval Units** list.
7. On that mission menu, choose **Patrol**, **Defend**, **Blockade**, or **Beachhead**. Choose **Cancel pending mission** when a mission is already staged and you want to drop it.
8. **Blockade** and **Beachhead** open **Naval mission target dialog** (title **Select target**) so you choose an adjacent enemy province at war with you. Target rows keep the province name. Beachhead shows the same defender / unopposed / fort summary you see on invasion rows. Blockade shows whether the harbor has a port, is empty, or already has hostile fleets — or says the harbor is unknown when you cannot see it. You can confirm once a target is selected, even if some harbor details are unknown.

**From the Naval Units list:**

1. In **Naval units panel**, tap **Mission** on an eligible at-sea fleet.
2. Follow the same **Naval mission menu dialog** flow, including **Sail / Move**. The row shows a pending mission line after you confirm (for example `On mission: Patrol` or `Blockade → <province>`).

**Province shortcut:** On a foreign coastal province at war with you, **Province sea-zone overlay** **Naval** offers **Blockade** and **Beachhead**.

1. Tap **Blockade** or **Beachhead**.
2. One eligible at-sea fleet skips **Naval mission menu dialog** and opens **Naval mission target dialog** with that province already selected.
3. Several eligible fleets open **Naval mission fleet picker dialog** first.
4. If a fleet is at sea but not beside this coast, the controls stay visible and disabled until a fleet is at sea beside the coast — fleets in port cannot take missions. When the naval list shows `???`, these actions still appear if **Political** already names the owner.

When you assign **Blockade**, the text you see first names the warehouse cut, not only catching ships. If the chosen target is their capital port, one extra line says links that only go by sea — including overseas — are cut while land roads remain. Once the blockade is in place, open **Province sea-zone overlay** **Naval** on a port you own that is under blockade: it shows **Under blockade**. Opening **Tile details** on an owned tile that is not linked to the capital names the blockade as the cause.

Map-marker and panel **Mission** still open **Naval mission menu dialog** as usual.

- **Patrol:** Remain in the current sea zone and attempt to intercept hostile fleets moving through it, including hostile patrols and blockaders.
- **Blockade:** Remain in a sea zone next to the target enemy port. After **Next turn**, that port’s link to its capital is cut, so goods from that province do not reach their warehouses. If you blockade their capital port, links that only go by sea — including overseas — are cut; roads on land still reach inland. The mission also gives a stronger chance to intercept hostile fleets entering that sea, including ships leaving the blockaded port. The target list still shows whether the port is empty or has hostile fleets.
- **Beachhead:** Remain at sea beside a hostile coastal province to establish a landing site. On the following turn, eligible friendly land units may invade that province; the marker expires after that invasion resolves, or after that following turn if no invasion occurs. The target row helps you compare landing coasts; it does not mean the fleet captures the province this turn.
- **Defend:** Remain in place without actively seeking combat. Defending fleets can still be attacked or drawn into combat by hostile patrols or blockades.

A fleet may have a pending **move** or a pending **mission** for the turn, never both. Staging a mission clears any pending move for that fleet, and vice versa.

**Join Home Fleet** is not assigned through the mission menu. Dock a regular fleet at your capital (the merge happens after **Next turn**) or use the transfer controls below.

### Transfer selected ships home

**Naval units panel** shows **Transfer to Home Fleet** on a regular fleet row when a Home Fleet exists in that region (Old World or New World). Tapping it opens **Transfer to home fleet** (title **Transfer Ships to Home Fleet**).

1. Move one or more ship types from the source list to the Home Fleet list.
2. Read the line under the lists: remaining Home Fleet cargo holds after this transfer, this turn’s overseas load, and how many holds stay free for trade bids. Warships add no holds.
3. If the line turns a warm accent, no holds are spare. If it turns red, remaining holds would fall short. You can still tap **Transfer** — the line warns, it does not lock.
4. Confirm **Transfer**. The selected ships join the Home Fleet at once.
5. A regular fleet that gives up every ship is removed; the Home Fleet remains, even with no ships.

The screens do not all describe the same moment when a transfer is allowed. **Transfer to Home Fleet** is the button you can tap whenever a Home Fleet exists in that region. The transfer dialog itself is written for a source fleet already in port at the capital. **Combine** can also move selected ships into the Home Fleet when the source is in port at the capital, or at sea in a sea next to the capital. Docking at the capital on **Next turn** merges the whole arriving fleet into the Home Fleet. Use the control you can tap; if confirm does not complete, that fleet is not in a place the game will accept.

Use a selected-ship transfer to return only merchants to carry cargo while leaving a warship squadron assembled, or to place escorts with the ships that carry your overseas goods.

## Counsel

**Counsel.** Hark, my liege: cargo ships win no battle, yet a victorious navy without Home-Fleet holds cannot bring distant bounty to your warehouses. Keep enough merchants at the capital for the trade and transport upon which your plans depend.

**Counsel.** Train Naval lists the **Galleon** as **Merchant** because it has cargo holds. In a fight it still behaves with the heavier battle-ship hulls. Do not read that Train role as “this ship cannot fight.”

**Warning.** A port is shelter, not a battlefield. Fleets in port do not join naval combat, but must leave port into an adjacent sea before they can operate — and a blockader may intercept them there.

**Warning.** Cargo capacity is not always safe. Only Home Fleet merchants carry transport and trade cargo. Hostile fleets at war that patrol or blockade the relevant seas can cut delivered goods and endanger merchant hulls. Warships left in the Home Fleet reduce those losses. An enemy that holds **Privateering Companies** raids more strongly.

**Tip.** Return a fleet to the capital by docking it there when possible. That both ends its voyage and restores its hulls to the cargo fleet without a separate sea-going station.

## The other courts

Rival Great Powers also raise fleets and send them to sea. When they are pushing overseas, they favour New World seas, ports, landing sites, and carrying troops. When they are only beginning that push, they may explore and carry cargo there but do not stage invasions by sea.

Victoria and Henry lean toward ships and naval learning; Isabella leans toward exploration and ships; de Ruyter leans toward trade ships; Napoleon and Gustavus can keep a navy beside their land wars. A chosen **leader** changes how bold or cautious they are — not how you win.

## Consequences

- A ship built successfully joins the Home Fleet after **Next turn**, increasing cargo capacity only while it remains there.
- Moving a fleet into a sea zone can expose new coasts, but it also creates opportunities for patrols and blockades to intercept it.
- Naval combat occurs only between opposing fleets at sea in the same sea zone. An interception can create combat when a patrol or blockade catches a mover; combat also follows when hostile fleets finish movement together.
- Combat adds together ship firepower, range, armour, hull, and movement. Fleets may retreat only to an adjacent friendly or neutral sea zone free of hostile fleets; failure to retreat causes further losses.
- Blockades do more than catch ships. They stop that port’s goods from reaching warehouses. A capital-port blockade also cuts links that only go by sea, including overseas; roads on land still work.
- The Home Fleet cannot sail because it is the permanent capital-port fleet that supplies the realm’s transport and trade capacity. Ships must first be split into a separate sea-going fleet before they can move or take missions.
- Overseas cargo is not guaranteed. Hostile fleets at war that patrol or blockade the relevant seas can cut delivered goods and endanger merchant hulls. Warships left in the Home Fleet reduce those losses. **Privateering Companies** makes an enemy’s raids stronger when they hold that technology.
