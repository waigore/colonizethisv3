# The Road to Victory

## Purpose

A Great Power wins a campaign by controlling **31 or more Old World provinces**, including provinces formerly held by Minor Nations. New World provinces, including those of Tribes, do not count toward this threshold.

The campaign may also reach its calendar end without a province-count winner. In that case, the realm with the strongest overall position may be declared the winner of the completed campaign summary—but that is separate from winning by province count.

## How it is done

1. On the map (`MAP10001` **Empire overview / map area**), read how many Old World provinces you hold out of 31 on the same row as the treasury and cargo. If another Great Power is ahead, that court’s name and count appear beside yours. Tap that count to open **Victory** (`GAME70001`). You can also open Victory from the last of the left-side icons (after Technology) at any time during a campaign. On wide screens (600 dp or wider) with map data loaded, standings and the political minimap appear side-by-side so you can read both without scrolling. On narrower screens they stack vertically. The panel states plainly that you win by controlling **31 or more Old World provinces**, with calendar-end and infinite-mode notes when relevant. Each Great Power row shows **how many Old World provinces they hold out of 31** with a progress bar toward that threshold. Tap a row to highlight that power's lands on the minimap; tap a province on the minimap to select its owning Great Power when applicable. A short helper under the standings header reminds you that colours match the map. Expand a row to see overall-strength totals used only if the campaign runs to the calendar end without a province-count winner. When map data is loaded, a political Old World minimap shows who holds each province with province names, capital-province borders, and town markers; hover or tap a province to see whether it is still its founding power's or was captured.
2. If you turn on the optional players list on that same map row, each Great Power shows its Old World count out of 31. Rest on a name (or press and hold on a touch screen) to read calendar-end overall strength — that total matters only if the campaign reaches the calendar end with no province-count winner.
3. Build and protect an Old World position, then take or absorb enough Old World territory to own **at least 31 provinces**. The condition is checked after all turn phases have resolved. If more than one Great Power reaches 31 in the same turn, the Great Power with the alphabetically earliest player identity wins.
4. Do not confuse conquest with colonial growth. Minor Nation provinces in the Old World count once they are yours; Tribe provinces in the New World do not.
5. In a standard campaign, the final full turn begins in **1800**—turn **201** under the default calendar. If no one has won by province count by its end, no further turns may be resolved.
6. At that calendar end, a declared winner is the Great Power with the strongest overall realm: owned provinces in both worlds, regiment strength, and ships all contribute. A tie produces no declared winner.
7. Choose **infinite mode** when creating a new campaign if you want to continue beyond the calendar cap. The calendar then advances normally after 1800, and only reaching the province win or leaving the game ends the campaign.
8. When military victory is recorded, `OVL20001` **Victory overlay** appears over the game. It names the winner, identifies the military victory, and states the winning turn. Choose **Return to Main Menu** to leave the campaign, or **View Final State** to dismiss the overlay and inspect the finished map. Viewing the final state never re-enables orders or further turns.

## Counsel

**Counsel.** Hark, my liege: thirty provinces invite ambition; the thirty-first invites every neighbour to measure the cost of letting thee keep it.

**Warning.** A far-flung empire can meet the count yet fail to hold it. Keep armies, fleets, treasury, and capital connections sufficient for the provinces already won before opening another war.

**Tip.** If the calendar is near its end, compare your whole realm—not merely your Old World conquests. The declared-winner totals value provinces, land strength, and ships across both worlds, while winning by province count values only Old World province ownership.

## The other courts

Rival Great Powers assess war and diplomacy through their own personalities, priorities, relations, and relative strength. Militaristic leaders may seek opportunity; traders and navigators may prefer diplomacy, trade, or alliances; defenders and tacticians may answer a threatening neighbour with force.

As your realm grows, other courts have more reason to regard you as a powerful or dangerous rival. Their war planning compares relative power, relations, existing wars, invasion capacity, resources, and the risk that other Great Powers may intervene for a Minor Nation or Tribe. Formal alliances can also turn one declaration into a wider conflict.

The AI does not receive a separate secret victory rule, but a realm approaching the Old World threshold is visibly stronger and more exposed. Expect wary diplomacy, hostile coalitions, and opportunistic attacks if your expansion leaves weak borders or isolated possessions.

## Consequences

- Reaching 31 Old World provinces ends the campaign immediately after that turn’s resolution; no further orders or turn advancement are available.
- A province-count win takes precedence over the calendar cap if both would be reached on the same turn.
- A calendar halt leaves the province-count win unset. It may declare an overall-strength winner for the campaign summary, or declare no one if the leading total is tied.
- Infinite mode removes the calendar halt, not the danger of overextension. Rival courts continue to develop, fight, trade, ally, and react while you pursue the province win.
- A final-state view is for reflection and inspection only. It preserves the completed map but cannot resume the campaign.

## Acceptance criteria for this chapter

- [ ] States that winning by province count requires a Great Power to control 31 or more Old World provinces, including Minor Nation provinces.
- [ ] Documents the `GAME70001` Victory panel (map-row Old World count entry and left-side icon, OW standings with progress bars and map-linked selection, expandable calendar-end totals, political OW minimap with origin inspect when available, conditions including infinite mode) in plain province-count language.
- [ ] States that New World and Tribe provinces do not count toward the military threshold.
- [ ] Explains the default 1800 calendar cap, its turn-201 default mapping, and the declared-winner power-score outcome, including ties.
- [ ] Explains infinite mode as a new-campaign choice that bypasses the calendar halt while retaining the province-count win.
- [ ] Documents active `OVL20001` Victory overlay behavior and both options: Return to Main Menu and View Final State.
- [ ] Gives endgame counsel on coalition risk, AI reactions to relative power, and overextension.
- [ ] Distinguishes a province-count win from a calendar-ended campaign summary.

## Sources

- `SPEC/game/victory.md`
- `SPEC/game/turn-time-mapping.md`
- `SPEC/game/diplomacy.md`
- `SPEC/ui/victory-panel.md`
- `SPEC/ui/components/old-world-race-chip.md`
- `SPEC/ui/empire-overview.md`
- `SPEC/ui/victory-overlay.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/growth-stage-planner.md`
- `SPEC/ai/ai-personalities.md`
