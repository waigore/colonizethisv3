# The Art of War

## Purpose

War changes the map more quickly than any workshop or treaty. A successful army move can seize a province, weaken a rival’s field forces, and open a route toward their capital. A failed assault may instead leave your border exposed and your trained regiments gone.

This chapter covers how an army attacks, how you choose between a swift resolution and a Quick Battle, and how forts turn an ordinary clash into a siege.

## How it is done

### Attacking a province

1. Open `UNIT20001` **Military units panel**, select a non-Home army, and choose **Move** to open `DLG20001` **Move army dialog**.
2. Select a legal destination. Your own provinces appear separately from invasion targets. An enemy province may require a declaration of war; confirm that declaration and the move together when the dialog asks.
3. End the turn. When the army finishes in an enemy-controlled province, every regiment in that army attacks together. Great Powers initiate these attacks; Minor Nations and Tribes defend.
4. An enemy province with no combat-capable defenders can be captured without a battle when your army arrives during a war. Otherwise, the combat phase creates a battle.

If several attackers reach the same province, they fight in initiative order. The surviving side carries its losses into the next engagement; it does not recover between them.

### Choosing the combat mode

1. When your coming battle needs a choice, `CMPT10001` **Combat mode choice dialog** names the contested province.
2. Choose **Auto-Resolve** for an immediate deterministic result, or **Quick Battle** to direct the current tactical encounter.
3. A capital siege permits only Quick Battle. The Auto-Resolve choice is not available in that case.

A province without a fort is a field battle. A province with a fort level of 1 or more is a siege, whether you choose Auto-Resolve or Quick Battle.

### Quick Battle

1. Choosing Quick Battle opens `CMPT20001` **Quick battle screen**. It shows the attacker first, then the defender, with the deployed groups, their unit counts, and cohesion.
2. In the current battlefield, both sides begin in the centre front with cohesion 3. The battle lasts at most three rounds.
3. In an interactive battle, spend the available Command Points to choose an action:
   - **Volley Fire** costs 1 CP and attacks the opposing front.
   - **Defend** costs 1 CP and improves a lane’s defence for the round.
   - **Maneuver** costs 1 CP and repositions a group.
   - **Fall Back** costs 2 CP and trades ground and cohesion to preserve troops.
   - **Assault** costs 2 CP for a forceful, risky attack.
4. Actions that cost more Command Points than remain are unavailable. The battle resolves after the selected action plan; unused tactical decisions default to Volley Fire.
5. In non-interactive battles, the game resolves with default actions.

The present Quick Battle battlefield uses open terrain and a simplified centre-front deployment. Province terrain can still affect the wider combat context, but hills, woods, towns, swamps, flanking lines, and full reserve manoeuvres are not yet tactical choices.

### Auto-Resolve

Auto-Resolve compares the two sides’ effective strength and applies the configured terrain, fort, leader, medal, and supply effects. It is deterministic: the same armies, orders, and ruleset produce the same result.

A stronger attacker can destroy the defenders and take the province. A defender can hold and destroy the attackers. Both sides may survive in a stalemate, or both may be eliminated in mutual annihilation. Casualties are applied before any change of ownership.

### Sieges and forts

A fort makes the battle a siege:

| Fort | Effect in a siege |
|------|-------------------|
| Wood, level 1 | Wall protection and 1 emplaced gun |
| Stone, level 2 | Stronger wall protection and 2 emplaced guns |
| Modern, level 3 | Strongest wall protection and 3 emplaced guns |

In Auto-Resolve, walls first absorb a fixed amount of attacking strength before the remaining force affects defender losses. The exact values are ruleset-configurable.

In Quick Battle, the defender receives virtual emplaced guns behind the fort. They are part of that battle only, not separate map regiments. If every emplaced gun is destroyed, the fort loses one level after the battle—even if the defender holds or both sides are exhausted. Auto-Resolve uses an aggregate fort-gun bonus instead and does not currently reduce a fort in this way.

### Reading the result

After Quick Battle, `CMPT50001` **Quick battle result dialog** reports one of three outcomes:

- **Attacker wins:** the defender is eliminated. A bold province-captured notice appears when ownership flips.
- **Defender holds:** the attackers are eliminated and the province remains theirs.
- **Mutual exhaustion:** neither side takes the province; the casualty rows still show the cost.

The dialog always lists casualties for attacker and defender, including zero when a side lost no regiments. Read those numbers with the map result: victory with severe losses may still leave a frontier too weak to hold.

## Counsel

**Counsel.** Hark, my liege: do not mistake an empty-looking frontier for a safe one. An army may take an undefended province at once, yet a fort or a second enemy army can turn the next advance into a costly siege.

**Warning.** Your Home Army cannot march. Raise and move field armies if you mean to invade.

**Tip.** Choose Quick Battle when the immediate tactical choice matters to you; choose Auto-Resolve when you accept the same ruleset-driven result without directing its actions. Neither path excuses an army from the consequences of poor strength, supply, or preparation.

**Counsel.** Before storming walls, count what shall remain to guard the new banner. A captured province is little comfort if the army that won it cannot meet the counterstroke.

## The other courts

Other Great Powers plan declarations of war before their invasion moves, so a rival may legally combine both in one turn. Their planners favour reachable, valid conquest targets and weigh military pressure against broader goals such as expansion, colonial acquisition, survival, and economic need.

AI-controlled Quick Battles use the non-interactive path and default actions. You will not negotiate their tactical choices during their turn, but their attacks and visible army movements remain evidence of their public conduct. An attack on a court allied to another power, or on a minor nation or tribe with which that court has ties, can provoke diplomatic reactions.

## Consequences

- An attacker victory eliminates the defending regiments, then transfers the province to the attacker. Connectivity and extraction effects are recalculated in later turn processing.
- A defender victory leaves ownership unchanged and eliminates the attacking regiments.
- A stalemate leaves surviving forces in place and keeps the current owner.
- In a final mutual annihilation, the original defender keeps the province but may be left without a garrison. If more attackers remain in the same battle chain, the defender instead receives a small recovered garrison before the next fight.
- A destroyed siege battery in Quick Battle lowers its fort by one level, making a later assault less protected.

## Acceptance criteria for this chapter

- [ ] Explains how a non-Home army attacks an enemy province, including declaration-of-war confirmation and unopposed capture.
- [ ] Documents `CMPT10001` combat-mode choice, including the capital-siege Quick-Battle-only restriction.
- [ ] Documents `CMPT20001` Quick Battle deployment, Command Points, the five current actions, default actions, and the result flow.
- [ ] Explains deterministic Auto-Resolve and attacker victory, defender victory, stalemate, and mutual annihilation.
- [ ] Explains field battles, siege triggers, fort levels, wall protection, emplaced artillery, and Quick-Battle fort downgrade.
- [ ] Documents `CMPT50001` outcome and casualty reading.
- [ ] Describes other Great Powers only through their documented military planning and observable diplomatic reactions.

## Sources

- `SPEC/game/combat.md`
- `SPEC/game/quick-battle.md`
- `SPEC/game/siege-mechanics.md`
- `SPEC/ui/move-army-dialog.md`
- `SPEC/ui/combat-mode-choice-dialog.md`
- `SPEC/ui/quick-battle-screen.md`
- `SPEC/ui/quick-battle-deployment-view.md`
- `SPEC/ui/quick-battle-action-selector.md`
- `SPEC/ui/quick-battle-result-dialog.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/ai-architecture.md`
- `SPEC/ai/dialogue-and-mood.md`
