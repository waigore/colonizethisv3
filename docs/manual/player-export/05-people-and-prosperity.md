# People and Prosperity

## Purpose

Labour and civilians are how you fill factories and work the map. If you let those go idle, rivals pull ahead. The **capital** is your home city. **Factories** are the Production jobs that need labour. **Workers** live in your capital and give **labour** — the work that runs those factories. They are not people you place on the map. The **labour pool** is how many of those workers you have in the capital. A **decree** is an action you choose on your turn. **Peasant**, **Apprentice**, **Journeyman**, and **Master** are the four worker ranks, from cheapest labour to most. A **luxury** is the extra good a trained worker must have, or they give no labour that turn. **Civilian units** are people you place on the map. An **Explorer** and a **Builder** are civilians of that kind (roles in the roster table below). Empty factories, workers who **strike** (give no labour that turn for lack of food or luxury), and rivals who train Explorers and Builders while you do not, leave you short of goods and behind on the land.

## How it is done

### Worker tiers (not map units)

1. On **Game screen**, tap the **Production** icon on the left of the map to open **Production screen**.
2. Use the worker grid and **Labour Controls** there.

Workers live only in the labour pool on **Production screen**. They never appear on the map. The four ranks, from cheapest labour to most, are **Peasant**, **Apprentice**, **Journeyman**, and **Master**.

| Tier | Labour / turn | Food | Luxury (trained workers) |
|------|---------------|------|--------------------------|
| Peasant | 1 | Grain or Meat | — |
| Apprentice | 4 | Grain + Meat | refined sugar |
| Journeyman | 6 | Grain + Meat | cigars |
| Master | 8 | Grain + Meat | fur hats |

Higher ranks eat more. Trained workers (Apprentice, Journeyman, Master) also need their luxury in full, or they give no labour that turn; they do not work “a little.” After you confirm **Next turn**, armies and fleets eat before workers do. Only workers who were fed (and, if trained, given their luxury) add labour that turn. Unfed workers, or trained workers who miss their luxury, **do not work** that turn (they stay in the pool). When food is short, Masters eat first and Peasants last. A trained worker who missed food does not take a luxury that turn.

On **Production screen**, **Labour this turn: N** is always visible under the worker grid. It shows how much labour you will have after everyone eats. It counts food and luxuries that arrive this turn, not only what you already have stored. When N is less than the labour those workers could give if all of them worked, a short shortage reason is already under that line (food, or a luxury). It is not something you tap to reveal. Tap **Labour details** for working vs not-working counts on each rank. Armies and fleets are a separate block of lines, hidden when you have no regiments and no ships. That block uses **somewhat weaker** / **much weaker** when forces are underfed. Tap **Forces food details** for the fed counts and the reminder that armies and fleets eat before workers.

The same **Labour this turn** forecast also appears on **Empire overview / map area** as a worker icon and a number pair like `8/12` (or `0/0` before you recruit a Peasant), after the crate icon on the **Old World** / **New World** row. **Old World** and **New World** are the two maps. The pair has no spaces. Tap that worker number to open a small panel. The panel shows **Labour this turn: N of C**, the same shortage reason (or **No workers trained yet** when the pool is empty — no shortage reason), army and navy fed lines when you have forces, and a reminder that armies and fleets eat before workers.

Neither the Production line nor the map panel buys food, changes **Allocation**, or disbands anyone.

### Recruit, train, and disband

On **Production screen**, use **Labour Controls** under that labour line. Each row shows the printed cost (peasant **Fabric ×2**; trained rows **£… + Paper ×N + 1 peasant**), how much labour that worker gives, and what food or luxury they eat. If **+** will not press, hold it to read why. The reason is one of the printed reject lines listed later in this section. New workers add labour on a **later** turn, not the turn you queue them.

1. Open **Labour Controls** under the worker grid. Tap **+** on **Peasant** to queue **Recruit**, or **+** on **Apprentice**, **Journeyman**, or **Master** to queue **Train**. Training always consumes **one peasant**; there is no direct promotion from apprentice to journeyman or journeyman to master. After you confirm **Next turn**, the game carries it out. Tap **−** to take back the last queued hire of that rank. When a rank has queued hires, the row shows **Queued: N**. Peasants cannot be disbanded.
2. Printed costs:

| Target | Cost |
|--------|------|
| Peasant (Recruit) | Fabric ×2 |
| Apprentice | £200 + Paper ×2 (consumes 1 peasant) |
| Journeyman | £500 + Paper ×5 (consumes 1 peasant) |
| Master | £1000 + Paper ×10 (consumes 1 peasant) |

3. Locked trained rows need both technologies: Apprentice needs **Apprentice Workers** and **Sugar Refining**; Journeyman needs **Trained Journeymen** and **Cigar Production**; Master needs **Master Artisans** and **Hat Production**. Locked rows print **Requires:** with those names until you research them.
4. Peasants already promised to queued worker training or to army/navy training are not free to spend again. Training a civilian (Explorer, Builder, and the rest) does **not** spend a peasant.
5. Tap **Disband** on a trained row. The confirm uses labelled **Effect** / **Cost** / **When** lines: the trained rank becomes a Peasant **now**; gold and paper spent to train them are not returned; the change is immediate (not after **Next turn**). Buttons are **Disband** and **Cancel**. Tap **Cancel** (or tap outside, or press Escape) to leave the pool unchanged. Tap **Disband** on the confirm to apply it at once: that rank −1, peasants +1. It is not queued for later. Peasant rows have no **Disband**.

If **+** will not press, hold it to read why. The printed reasons are **Insufficient workers**, **Insufficient materials**, **Insufficient treasury**, and **Required technology not unlocked**.

**Timing note:** New workers join the pool after this turn’s factories have already run, so they help **next** turn. They do not staff **this** turn’s factories. Plan one turn ahead.

### Civilian roster and training

Civilians are people you place on the map. They explore, improve land, and post **Spies**. A **Spy** is a civilian who holds foreign news or defends the realm at home (roles in the roster table). Workers decide how much you can make this turn; civilians are how you work the map. A **Great Power** is a playable nation. A **Minor Nation** is a smaller Old World court you do not play. A **Tribe** is a New World people you do not play.

1. On **Game screen**, tap the **Civilian Units** icon on the left of the map to open **Civilian units panel**.
2. Tap **Train** to open **Train civilians dialog**. The printed title is **Train Civilians**. You can also open that same dialog from the map: when a work shortcut is greyed out only because you own none of that civilian, **Train Explorer**, **Train Builder**, **Train Engineer**, **Train Merchant**, or **Train Rail Builder** appears on **Province sea-zone overlay**, **Tile context radial**, or **More tile actions**. A short line says the new civilian appears at your capital after **Next turn** and that the tap does not assign work on the selected tile. Spies have no Train shortcut on the map. Each row shows a short role line under the type name:

| Unit | Role line | Train cost | Unlock |
|------|-----------|------------|--------|
| Explorer | Explores provinces · Prospects minerals | £1,000 + 2 paper | Available from the start |
| Builder | Improves tiles · Upgrades towns | £1,000 + 2 paper | Available from the start |
| Engineer | Builds roads, ports, and forts | £1,000 + 2 paper | Available from the start |
| Spy | Holds foreign intel · Counter-espionage at home | £2,000 + 4 paper | Available from the start |
| Merchant | Purchases land in Minor Nation / Tribe provinces | £2,000 + 4 paper | **Requires: Merchant Companies** |
| Rail Builder | Upgrades roads to railroad | £2,000 + 4 paper | **Requires: Early Steam Engine** |

The top line is remaining against total, such as `£3,000 / £5,000` and `8 / 12`. It updates as you tap **+** or **−**. Below it, **Treasury low**, **Paper low**, or **Treasury low, Paper low** appears when a queued hire exceeds gold or paper. That line is hidden when there is no shortfall. Set the **+** counts, then close the dialog (tap outside, or go back). There is no **Confirm** button. Close applies. **Reset** (if shown) clears the counts. Locked rows show **Requires:** plus the technology name.

Each **tile** is one square of land or water. Training queues a civilian-unit hire. After you confirm **Next turn**, queued worker hires apply first, then the new civilian appears on your capital’s tile, then existing civilians do this turn’s building and work. New workers do not staff **this** turn’s factories (Production already ran earlier). Use the panel thereafter to select units, assign work (Chapters 4 and 6), or relocate Spies.

**Spies — station and relocate.** Tap a province to open **Province sea-zone overlay**. In the **Civilian** section, tap **Station spy** when it is enabled, then tap **Relocate** on a Spy whose status is **Reserve** or **Holding intel**. That queues the Spy to walk to the tile you already selected, without picking again on the map. The Spy arrives after you confirm **Next turn**. You can still open **Civilian units panel** and tap **Relocate** to pick any legal land tile. **Relocate** is hidden when the row already shows **Counter-espionage**.

**Station spy** is hidden when it is a sea zone, when Civilian shows `???`, when the game is not letting you issue decrees, or when your Spy is already on that tile and no other Spy can move there. It is visible but not usable when no Spy on **Reserve** / **Holding intel** can take the tile, or the tile cannot be occupied — hold the button to read which. It is enabled when at least one Spy on **Reserve** / **Holding intel** can occupy the selected tile. On **rival Great Power** land, a short line under **Station spy** (and under **Relocate** in the Spy shortcut panel) explains that presence there **may speed research** if that court already knows a technology you are studying — or that the court **already grants spy insight** if you already have a Spy there. Minor Nation and Tribe posts do not show that line.

**Assign** still offers **Counter-espionage** on owned provinces only. From an owned land province already under study, you can also tap **Counter-espionage** in the **Civilian** section of **Province sea-zone overlay**, then **Assign** on a Spy whose status is **Reserve** or **Holding intel** — that posts the work without picking a tile on the map. The button says this protects the **whole realm**, not only the province you are looking at; one Spy is enough. If a Spy is already posted, or no Spy on **Reserve** / **Holding intel** can take the work, the button stays visible but cannot be used — hold the button to read which. It stays hidden on a sea zone, on land you do not own, when Civilian shows `???`, or when the game is not letting you issue decrees. A Spy on foreign **Minor Nation** or **Tribe** land, with no mission, shows **Holding intel: {province}**. A Spy in a **rival Great Power** shows **Holding intel: {province} — may speed research**. A Spy on land you own, with no mission, shows **Reserve**. When a Spy is set to defend at home this turn, the row shows **Counter-espionage** and hides **Relocate**. Leaving when yours is the last Spy there warns that full intel will fog after the turn ends. **Next turn confirmation** does not list Spies on **Reserve** or **Holding intel** — stationing is a chosen post, not wasted capacity.

If at least one of your Spies still stands in a foreign province after **Next turn** finishes, that court’s last-turn news appears under **Spy reports** on **Intelligence Council** (printed title **Intelligence**), opened from **Intelligence** on **Diplomacy screen**. Each block is `Our spy in {name} reports:` plus last-turn diplomatic acts, battles that court fought, provinces it captured or lost, and technologies it completed. You do not see that court’s private goal. If no Spy of yours still stands in that court’s land after **Next turn** finishes, that court is silent next turn. When none apply, that heading shows **No spy reports. Station a Spy in a foreign province to hear that court's news.**

## Counsel

**Counsel.** Hark, my liege: peasants are coin and fabric made flesh — spend them on Masters only when food, luxuries, and paper already flow.

**Tip.** Disband before a lean turn if luxuries will fail; a Master who does not work that turn contributes no labour and still eats.

**Warning.** Military and naval training compete for the same promised peasants as labour training. A parade of regiments can leave **Labour Controls** short of peasants even when the **Workers** counts look full.

## The other courts

Rival courts assign factory labour as you do, and they follow the same peasant-sharing rule: soldiers and ships compete with trained workers for peasants. They scale peasant hires with how short they are of labour, and they skip peasant hires when they are saving fabric to raise soldiers. While they are still building up, they make fabric and send Builders to improve wool and cotton land. They try to keep at least some Explorers, Builders, and Engineers. Early on they lean toward Builders; while settling new lands they lean toward Explorers and Merchants; when improving the homeland they lean toward Engineers and Rail Builders.

## Consequences

- Under-recruiting peasants caps Production even with rich recipes unlocked.
- Over-training Masters without food and luxury chains leaves trained workers who do not work that turn, and wasted treasury.
- Ignoring civilian training leaves exploration and improvements to rivals who did not.
- Same-turn expectation that new recruits staff factories leads to empty Production surprises.
