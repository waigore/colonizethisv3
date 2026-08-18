# The Art of War

## Purpose

War changes the map more quickly than any workshop or treaty. A successful march can seize a province, weaken a rival’s field forces, and open a route toward their capital. A failed assault may instead leave your border exposed and your trained regiments gone.

A **Great Power** is a playable nation. **Minor Nations** and **Tribes** are the non-playable courts that can defend when you attack. A **regiment** is one land fighting unit. The **Home Army** stays at the capital and cannot march; a **field army** is a group of regiments you can send away from home.

This chapter covers how a field army attacks, how you choose between **Auto-Resolve** (the game decides the fight at once) and **Quick Battle** (you give orders in the fight), and how forts turn an ordinary clash into a **siege** — a fight against a province that has a fort.

## How it is done

### Attacking a province

1. Open `UNIT20001` **Military units panel** and select a non-Home field army — or open `MAP20001` **Province sea-zone overlay** on the foreign province you mean to study, or tap a field-army stack marker on `MAP10001` **Empire overview / map area**. The Home Army is never listed on the map stack path.
2. Choose **Move** on an owned province that already holds a field army, or **Invade** on a foreign province.
3. If more than one field army can act, `DLG20002` **Overlay army move picker** opens (title **Select army**). Pick the army and tap **Confirm**. Each row shows that army’s regiment mix.
4. If only the non-empty Home Army can start the campaign, the **Detach a field army** dialog opens first (confirm **Detach and choose destination**). That creates a new field army before the move continues.
5. `DLG20001` **Move army dialog** opens (title **Move army — Army &lt;id&gt;**). Invasion rows show **Defenders: N regiments**, **Unopposed capture**, or **Defenders unknown**, plus **Open field**, **Wood fort siege**, **Stone fort siege**, or **Modern fort siege** when you can see them. When **Invade** started the flow, that province is preselected.
6. Select a legal destination. Your own provinces appear separately from invasion targets. An invasion destination may show **Invasions this turn: N · Generals: G** (a muted warning if you have more invasions than generals — **Confirm** stays enabled) and a muted rations warning if your land forces are short on food this turn. Owned-province destinations show neither line.
7. Tap **Confirm**. If the row requires war, confirm **Declare war?** with **Declare war and move**. That confirm shows the same Effect lines as declaring war from Diplomacy, naming other courts that may be called to defend or asked to intervene.
8. Tap **Next turn**. After you confirm **Next turn**, the game carries out the march. You see the fight or the unopposed capture when that finishes — not when you tap **Confirm**.
9. If a battle needs a choice, `CMPT10001` **Combat mode choice dialog** opens then (title **Combat at &lt;province&gt;**).
10. An empty enemy province — no owner troops and no third-court troops — transfers at the start of fighting, before a battle is created, and only while you are already at war. Otherwise, when your army finishes in an enemy-controlled province, every regiment in that army attacks together. Great Powers initiate these attacks; Minor Nations and Tribes defend.

### Military Counsel (`GAME90001` Counsel screen)

1. Open `UNIT20001` **Military units panel** and tap **Counsel**, or open **Counsel** from Production, Trade, or Development and select the **Military** tab on `GAME90001` **Counsel screen**.
2. At most three ranked cards suggest affordable train builds (land or ship — type, count, costs) and invasion targets (army, province, owner, **Defenders: N regiments** or **Defenders unknown** when shown). The Home Army is never suggested to march.
3. **Agree** on a train card queues that many build orders when still valid. **Agree** on an invade card stages the move; declare-war confirmation matches `DLG20001` when required. If **Agree** is no longer valid, a short on-screen message explains why nothing was staged.

If several attacking armies reach the same province, they fight one after another. The side that is still standing keeps its losses and fights the next army; it does not get fresh troops between those fights (except the recovered garrison in the mutual-annihilation case below).

### Choosing the combat mode

1. When a coming battle needs a choice, `CMPT10001` **Combat mode choice dialog** names the province (**Combat at &lt;province&gt;**). It also shows how many of your regiments are already there, **Defenders: N regiments** or **Attackers: N** (or **Defenders unknown** if you cannot see the garrison), and whether the ground is **Open field** or a **Wood fort siege**, **Stone fort siege**, or **Modern fort siege**. If you are defending, the enemy line is labeled **Attackers**. Tap **Details** for regiment types. If your armies are short on rations this turn, a muted italic warning says they will fight weaker; **Auto-Resolve** and **Quick Battle** stay available.
2. **Auto-Resolve** decides the battle at once. **Quick Battle** lets you give orders in the fight. The dialog does not tell you who will win.
3. A capital siege permits only Quick Battle. Auto-Resolve is not offered then. (The game SPECs do not yet state this restriction; the screen behaviour above is what you see.)
4. A province without a fort is a field battle. A province with a fort level of 1 or more is a siege, whether you choose Auto-Resolve or Quick Battle.

### Quick Battle

1. Choosing Quick Battle opens `CMPT20001` **Quick battle screen**. It shows the attacker first, then the defender, with the deployed groups, their unit counts, and cohesion.
2. In the current battlefield, both sides begin at **Center Front** with **Cohesion 3**.
3. The current screen lets you pick one action from the five available:
   - **Volley Fire** costs 1 Command Point and attacks the opposing front.
   - **Defend** costs 1 Command Point and improves that group’s defence for the round.
   - **Maneuver** costs 1 Command Point and repositions a group.
   - **Fall Back** costs 2 Command Points and trades ground and cohesion to preserve troops.
   - **Assault** costs 2 Command Points for a forceful, risky attack.
   Actions that cost more Command Points than you have are unavailable. After you choose, the rest of the fight uses **Volley Fire**. (The full three-round orders desk described in the game rules is not yet operable on screen.)
4. In rival Quick Battles, the game resolves with default actions; you do not pick their fight orders.

The present Quick Battle battlefield uses open terrain and a simplified **Center Front** deployment. Province terrain can still affect the wider combat context, but hills, woods, towns, swamps, flanking lines, and full reserve manoeuvres are not yet tactical choices.

### Auto-Resolve

Auto-Resolve compares the two sides’ effective strength and applies terrain, fort, leader, medal, and rations. The same armies and the same situation always produce the same Auto-Resolve result.

Four outcomes are possible: **attacker victory** (defender eliminated, province may flip), **defender victory** (attackers eliminated, no change), **stalemate** (both sides may survive with no flip), and **mutual annihilation** (both wiped). A stronger attacker does not always take the land: when morale is low and the strength ratio is middling, an attacker victory can be blunted into a stalemate instead. Equal or greater defender strength with defenders still standing is a defender victory that wipes the attackers. Casualties are applied before any change of ownership.

### Sieges and forts

A fort makes the battle a siege:

| Fort | Auto-Resolve wall soak | Quick Battle damage reduction | Emplaced guns |
|------|------------------------|-------------------------------|---------------|
| Wood, level 1 | 10 (configurable) | 25% | 1 gun |
| Stone, level 2 | 20 (configurable) | 45% | 2 guns |
| Modern, level 3 | 30 (configurable) | 60% | 3 guns |

In Auto-Resolve, walls first absorb their soak amount of attacking strength before the remaining force affects defender losses. Exact soak numbers can change with the game’s combat settings.

In Quick Battle, the defender receives extra fortress guns for this fight only (they are not extra map regiments). **Defend** improves that group’s defence for the round. If every one of those guns is destroyed, the fort drops one level after the fight — even if the defender holds or both sides are exhausted. Auto-Resolve instead adds a single fortress-gun bonus and does not currently lower the fort this way.

### Reading the result

After Quick Battle, `CMPT20001` **Quick battle screen** shows the result first (**Continue**). The three printed outcomes are **Attacker wins**, **Defender holds**, and **Mutual exhaustion** — without assuming every regiment on a side is gone unless the casualties show it. A bold province-captured notice appears when ownership flips.

Then `CMPT50001` **Quick battle result dialog** opens (**OK**), repeating the outcome and listing casualties for attacker and defender, including zero when a side lost no regiments. Read those numbers with the map result: victory with severe losses may still leave a frontier too weak to hold.

## Counsel

**Counsel.** Hark, my liege: do not mistake an empty-looking frontier for a safe one. An army may take an undefended province at once, yet a fort or a second enemy army can turn the next advance into a costly siege.

**Warning.** Your Home Army cannot march. Raise and move field armies if you mean to invade.

**Tip.** Choose Quick Battle when the immediate tactical choice matters to you; choose Auto-Resolve when you accept the same computed result without directing the fight’s actions. Neither path excuses an army from the consequences of poor strength, supply, or preparation.

**Counsel.** Before storming walls, count what shall remain to guard the new banner. A captured province is little comfort if the army that won it cannot meet the counterstroke.

## The other courts

Other Great Powers declare war before they march, so a rival may legally combine both in one turn. They look for neighbouring foreign provinces they can legally enter. Their Quick Battles use the automatic path and default actions; you do not pick their fight orders. You still see their marches and attacks.

An attack on a Great Power that holds a formal alliance with another court can provoke that court. An attack on a Minor Nation or Tribe can provoke a court that has an embassy or close friendship there.

## Consequences

- An attacker victory eliminates the defending regiments, then transfers the province to the attacker. After ownership changes, whether the land still links to a capital and whether tiles still extract is checked on the next turn.
- A defender victory leaves ownership unchanged and eliminates the attacking regiments.
- A stalemate leaves surviving forces in place and keeps the current owner.
- In a final mutual annihilation, the original defender keeps the province but may be left without a garrison. If another attacking army is still waiting to fight in that province, the defender instead receives a recovered garrison equal to one-fifth of its initial regiment count in that fight, rounded up (minimum one regiment). Every recovered regiment is the defender’s most advanced infantry type for its era.
- A destroyed siege battery in Quick Battle lowers its fort by one level, making a later assault less protected.

## Acceptance criteria for this chapter

- [ ] Explains how a non-Home army attacks an enemy province, including declaration-of-war confirmation and unopposed capture.
- [ ] Documents `MAP20001` Military **Invade** / **Move** and `MAP10001` field-army stack taps as alternate paths into `DLG20001` (with optional `DLG20002` showing each army’s regiment mix, or Home Army detach then Move army).
- [ ] Documents `CMPT10001` combat-mode choice, including the capital-siege Quick-Battle-only restriction the screen shows.
- [ ] Documents `CMPT20001` Quick Battle deployment, one chosen action followed by default **Volley Fire**, and the result flow through `CMPT50001`.
- [ ] Explains Auto-Resolve and attacker victory, defender victory, stalemate, mutual annihilation, and the blunted-to-stalemate case.
- [ ] Explains field battles, siege triggers, fort levels, wall soak, Quick Battle damage reduction, emplaced guns, and Quick-Battle fort downgrade.
- [ ] Documents `GAME90001` Military Counsel invasion/train **Agree**, at most three cards, and declare-war confirm matching the Move army dialog.
- [ ] Documents `CMPT50001` outcome and casualty reading after the on-screen Quick Battle result.
- [ ] Describes other Great Powers only through their documented military planning and observable diplomatic reactions.

## Sources

- `SPEC/game/combat.md`
- `SPEC/game/quick-battle.md`
- `SPEC/game/siege-mechanics.md`
- `SPEC/game/military-armies.md`
- `SPEC/ui/move-army-dialog.md`
- `SPEC/ui/province-sea-zone-detail-overlay.md`
- `SPEC/ui/overlay-army-move-picker-dialog.md`
- `SPEC/ui/empire-overview.md`
- `SPEC/ui/military-units-panel.md`
- `SPEC/ui/military-units-army-management.md`
- `SPEC/ui/counsel-panel.md`
- `SPEC/program/military-counsel-ranking.md`
- `SPEC/ui/combat-mode-choice-dialog.md`
- `SPEC/ui/components/combat-mode-choice-intel.md`
- `SPEC/ui/quick-battle-screen.md`
- `SPEC/ui/quick-battle-deployment-view.md`
- `SPEC/ui/quick-battle-action-selector.md`
- `SPEC/ui/quick-battle-result-dialog.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/ai-architecture.md`
- `SPEC/ai/dialogue-and-mood.md`
