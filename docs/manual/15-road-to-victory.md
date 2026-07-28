# The Road to Victory

## Purpose

A Great Power wins a military campaign by controlling **31 or more Old World provinces**, including provinces formerly held by Minor Nations. New World provinces, including those of Tribes, do not count toward this threshold.

The campaign may also reach its calendar end without a military victor. In that case, the realm with the highest power score may be declared the winner of the completed campaign—but this is not a military victory.

## How it is done

1. Open **Victory** (`GAME70001`) from the left empire rail (last button, after Technology) at any time during a campaign to read victory conditions and Great Power standings. On wide viewports (600 dp or wider) with map data loaded, standings and the political minimap appear side-by-side so you can read both without scrolling. On narrower screens they stack vertically. The panel shows each Great Power's Old World province count toward the military threshold of **31**, with power-score breakdown available on expand for calendar-end comparison only. When map data is loaded, a political Old World minimap shows who holds each province with province names, capital-province borders, and town markers; hover or tap a province to see whether it is still its founding owner's or was captured.
2. Build and protect an Old World position, then take or absorb enough Old World territory to own **at least 31 provinces**. The condition is checked after all turn phases have resolved. If more than one Great Power reaches 31 in the same turn, the Great Power with the alphabetically earliest player identity wins.
2. Do not confuse conquest with colonial growth. Minor Nation provinces in the Old World count once they are yours; Tribe provinces in the New World do not.
3. In a standard campaign, the final full turn begins in **1800**—turn **201** under the default calendar. If no military victory has occurred by its end, no further turns may be resolved.
4. At that calendar end, a declared winner is the Great Power with the strictly highest power score: owned provinces in both worlds, regiment strength, and ships all contribute. A tie produces no declared winner.
5. Choose **infinite mode** when creating a new campaign if you want to continue beyond the calendar cap. The calendar then advances normally after 1800, and only military victory or leaving the game ends the campaign.
6. When military victory is recorded, `OVL20001` **Victory overlay** appears over the game. It names the winner, identifies the military victory, and states the winning turn. Choose **Return to Main Menu** to leave the campaign, or **View Final State** to dismiss the overlay and inspect the finished map. Viewing the final state never re-enables orders or further turns.

## Counsel

**Counsel.** Hark, my liege: thirty provinces invite ambition; the thirty-first invites every neighbour to measure the cost of letting thee keep it.

**Warning.** A far-flung empire can meet the count yet fail to hold it. Keep armies, fleets, treasury, and capital connections sufficient for the provinces already won before opening another war.

**Tip.** If the calendar is near its end, compare your whole realm—not merely your Old World conquests. The declared-winner score values provinces, land strength, and ships, while military victory values only Old World province ownership.

## The other courts

Rival Great Powers assess war and diplomacy through their own personalities, priorities, relations, and relative strength. Militaristic leaders may seek opportunity; traders and navigators may prefer diplomacy, trade, or alliances; defenders and tacticians may answer a threatening neighbour with force.

As your realm grows, other courts have more reason to regard you as a powerful or dangerous rival. Their war planning compares relative power, relations, existing wars, invasion capacity, resources, and the risk that other Great Powers may intervene for a Minor Nation or Tribe. Formal alliances can also turn one declaration into a wider conflict.

The AI does not receive a separate secret victory rule, but a realm approaching the Old World threshold is visibly stronger and more exposed. Expect wary diplomacy, hostile coalitions, and opportunistic attacks if your expansion leaves weak borders or isolated possessions.

## Consequences

- Reaching 31 Old World provinces ends the campaign immediately after that turn’s resolution; no further orders or turn advancement are available.
- Military victory takes precedence over the calendar cap if both would be reached on the same turn.
- A calendar halt leaves military victory unset. It may declare a power-score winner for the campaign summary, or declare no one if the leading score is tied.
- Infinite mode removes the calendar halt, not the danger of overextension. Rival courts continue to develop, fight, trade, ally, and react while you pursue military victory.
- A final-state view is for reflection and inspection only. It preserves the completed map but cannot resume the campaign.

## Acceptance criteria for this chapter

- [ ] States that military victory requires a Great Power to control 31 or more Old World provinces, including Minor Nation provinces.
- [ ] Documents the `GAME70001` Victory panel (left-rail entry, OW standings, expandable power-score breakdown, political OW minimap with origin inspect when available, conditions including infinite mode).
- [ ] States that New World and Tribe provinces do not count toward the military threshold.
- [ ] Explains the default 1800 calendar cap, its turn-201 default mapping, and the declared-winner power-score outcome, including ties.
- [ ] Explains infinite mode as a new-campaign choice that bypasses the calendar halt while retaining military victory.
- [ ] Documents active `OVL20001` Victory overlay behavior and both options: Return to Main Menu and View Final State.
- [ ] Gives endgame counsel on coalition risk, AI reactions to relative power, and overextension.
- [ ] Distinguishes a military victory from a calendar-ended campaign.

## Sources

- `SPEC/game/victory.md`
- `SPEC/game/turn-time-mapping.md`
- `SPEC/game/diplomacy.md`
- `SPEC/ui/victory-panel.md`
- `SPEC/ui/victory-overlay.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/growth-stage-planner.md`
- `SPEC/ai/ai-personalities.md`
