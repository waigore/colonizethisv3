# The Passage of Turns

## Purpose

A **Great Power** is a playable nation. A **decree** is an action you choose on your turn. A turn is the span in which you choose those decrees, the other Great Powers make their own plans, and the world answers both.

The **Old World** and the **New World** are the two maps. **Next turn** is the only way the calendar advances, and the only way the game checks **military victory** (holding 31 or more Old World provinces; Chapter 15). Once you confirm, you cannot take those decrees back. Ending the turn commits what you have already set; the result is a new political, military, and economic situation to read before you choose again.

The campaign calendar advances with the turn. By default, turn 1 is 1500; turns through 100 advance two years each, reaching 1700, and later turns advance one year at a time. The top bar and **Next turn** show the year and the turn number. `DLG50001` **Turn news dialog** uses the same calendar.

## How it is done

### Ending a turn

1. On `GAME10001` **Game screen**, finish the decrees you mean to give this turn.
2. Glance at the tab bar beside treasury and cargo: a **labour** readout (`effective/full capacity`) shows how much worker labour you will have this turn after everyone eats, using the same forecast as `GAME20001` **Production**. If you have not trained any workers yet, that readout still shows `0/0` so the place stays put. Tap it for the labour line, any shortage reason (or “no workers trained yet”), and whether your armies or fleets will be underfed. Warm accent means reduced labour; red means no labour or underfed forces. This is a quiet glance, not a block on **Next turn**.
3. Tap **Next turn** in the top bar.
4. `DLG60001` **Next turn confirmation** opens. The title is **End turn?** or **Proceed to next turn?** The body says **Turn {N} will end. Continue?**
5. If you already staged decrees this turn, the dialog shows **Staged this turn** with a short count by kind (army moves, trade, and so on). If you gave none, that list is simply absent — the court does not scold you for a quiet turn.
6. Tap **Review decrees** to read each staged line in ordinary words. A locate button beside each kind opens that panel or screen and closes the dialog **without** ending the turn, so you can still change your mind. **Yes** stays available while you read.
7. Five working civilians can do assigned tasks: Explorer, Builder, Engineer, Merchant, and Rail Builder. If any of yours have **no work order** for the next turn, the dialog may list them under **These civilians have no work order for the next turn:**. Each row shows type, location, **No work order**, and a go-to button.
8. Tap go-to on a listed civilian to leave without ending the turn. The map finds that person and opens `UNIT10001` **Civilian units panel**. A **Spy** is a civilian posted in a foreign court or at home; Spies are **not** listed here — foreign station, home counter-spy, and capital reserve are deliberate posts, not wasted capacity.
9. To stop seeing that no-work-order list, turn on **Don't show this warning again** and then tap **Yes**. Tapping **No** leaves the warning on. You can also change the same warning in `DLG90001` **Settings** with **Warn when civilians have no work order on end turn**; that switch applies on the next end-turn confirm, without restarting the app.
10. Empty research seats or funding set to **None** are **not** listed here: holding gold back from research is a normal choice. Review `GAME40001` **Technology screen** only when you mean to. A funded research assignment you already set can appear under **Staged this turn**; unused seats still do not.
11. Choose **Yes** to commit the displayed turn, or **No** to keep planning.
12. After **Yes**, a **Processing Turn** screen appears. You cannot close it, tap the map, or tap **Next turn** until the turn finishes. The three-line button still opens `GAME50001` **Game side menu**. **Game Paused** / `SHEL40001` **Pause menu panel** does not open until **Processing Turn** closes.
13. The turn may pause when diplomacy needs your answer. Give that answer on `OVL30001` **Overture dialogue**, `OVL50001` **Pending intervention overlay**, or `OVL40001` **Call to arms dialogue overlay** before the rest of the turn can continue.

### What happens after Next turn

After you confirm, the game carries out the turn in a fixed order. You see the combined results when that finishes — not while each step runs.

1. Your decrees and the other Great Powers’ plans are gathered and checked together.
2. Resource tiles add goods to your stores.
3. Riches become treasury.
4. Armies, workers, and ships eat food and luxuries.
5. Assigned recipes and unused labour then make finished goods. This is why a store, treasury, or labour forecast can differ after the turn.
6. Diplomacy then runs — agreements, wars, and ownership can change what follows. The game may pause here for your answer on the diplomacy screens listed above.
7. Spy work then takes effect, then research.
8. Armies and fleets move. Minor Nations keep their armies as strong as the strongest Great Power, so they are hard to conquer casually.
9. Patrols and blockades may try to catch moving fleets; sea fighting comes next, then land fighting. Expect losses, new positions, and captured provinces only after these stages have finished.
10. People then do assigned work: build, explore, prospect, improve, and the rest.
11. The **World Market** is the shared market on `GAME60001` **Trade screen**. It then settles the bids and offers you submitted. **Deal Book** is that screen’s tab of your bids and offers.
12. The game checks **military victory** and whether the campaign calendar has ended, updates what you can see, and advances the turn. Then you can choose actions again (or the campaign ends).

### Turn news

A completed turn’s main report appears in `DLG50001` **Turn news dialog**, unless victory takes precedence. The world gazette lists captures, wars, peace, overtures, and discoveries. When your own court had outcomes last turn — a refused decree, finished research, a battle you fought, market or realm accounts, or completed work — a **Your court** line names them in plain language even when the world report is empty. Tap **open Events** on that line to close turn news and show `OVL70001` **Player turn event feed** on the map; **Close** alone does not open the feed. If nothing major happened in the world and your court was quiet too, the dialog says **No major events last turn.** Close the report, inspect the map and your empire screens, and prepare the next turn.

When your Spies still stood in a foreign court after that turn, a line at the bottom of turn news says **Your spies report N items — open Intelligence**. Tap it to close the newspaper and open `GAME30003` **Intelligence Council** (the printed bar says **Intelligence**; you can also open it from **Intelligence** on `GAME30001` **Diplomacy screen**). Closing the newspaper does not forget those reports; Intelligence keeps last turn’s world briefing and spy lines until the next completed turn replaces them.

### Last-turn pulses on the map

After you close turn news — or, when `OVL20001` **Victory overlay** is up for a military win or **Campaign complete**, after you choose **View Final State** — `MAP10001` **Empire overview / map area** may briefly pulse a few places where last turn’s fights, captures, finished civilian work, or new sight landed.

The pulses wait until **Victory overlay** is gone; closing the newspaper while it is still up does not start them. Each pulse also switches the **Old World** / **New World** tab the same way a locate button does. The camera moves to each place in turn; a short caption names what happened. Tap the map or **Skip** to end the sequence early. Skip or a map tap does **not** open `MAP20001` **Province sea-zone overlay** or a unit panel. At most six places play this way; the full list stays in `OVL70001` **Player turn event feed**. Research, diplomacy, and market lines stay in news and the feed only.

### The newspaper feed

On `MAP10001` **Empire overview / map area**, the newspaper button sits on the map bar after treasury, cargo, the labour readout, and the Old World race chip. The feed starts **hidden**. A badge on the button shows how many lines it holds. Tap the button to show or hide `OVL70001` **Player turn event feed** without leaving `GAME10001` **Game screen**.

Use the feed with turn news: the dialog is the formal summary; the feed keeps relevant lines on the map while you inspect. It replaces its entries each completed turn.

Tap a line for the matching place or screen:

1. When a technology finishes researching, its feed line shows the tech by name. Tap it to open `GAME40001` **Technology screen** on the Slots tab and choose your next project.
2. Diplomacy and overture lines open the other nation’s `GAME30002` **Diplomacy detail screen**. Spy-caught and spy-defected rows also open that court’s `GAME30002` **Diplomacy detail screen**.
3. Spy report lines (the same **Our spy in {court} reports:** wording as Intelligence) open `GAME30003` **Intelligence Council** or that court’s `GAME30002` **Diplomacy detail screen**.
4. Completed work orders open `UNIT10001` **Civilian units panel** focused on the person who finished the task.
5. Land combat and province capture lines open `MAP20001` **Province sea-zone overlay**. Naval combat opens that same screen when the map can find the sea; otherwise that line is not tappable. Discovery pans the map to the new province or sea. Medal lines use the word **general**.
6. Rejected orders open the panel or screen that owns that order type (for example civilian work opens Civilian units, trade opens Trade).
7. When your own market bids or offers filled or carried forward last turn, a short **Market:** line summarizes bought and sold totals (and orders carried when any). Tap it to open `GAME60001` **Trade screen** on the **Deal Book** tab. Overseas-profit lines remain separate and use the same Trade / Deal Book tap.
8. When treasury or stores changed materially last turn, a **Realm:** line summarizes the net treasury and largest store movers. Tap it to open `GAME20001` **Production screen** for last turn’s real totals, not the **Available** forecast.

A rival’s research or a fight you were not in does **not** appear here unless a Spy of yours still stood in that court.

### Pausing, saving, and loading

1. Open `SHEL40001` **Pause menu panel** when **Processing Turn** is not on screen. The title is **Game Paused**. Choose **Resume**, **Save Game**, **Load Game**, **Settings**, or **Exit to Main Menu**.
2. Choose **Save Game** to open `DLG70001` **Save game name**. Its proposed name includes your nation, leader, and current turn. Enter a valid name and save it. A conflicting name asks before overwriting; invalid names remain unsaved. You may keep 20 named saves. A new name at that limit is refused. Overwriting a save that already exists still works.
3. Choose **Load Game** to open `DLG80001` **Load game list**. The auto-save, when available, is kept apart from the manual list; manual saves are shown newest first and are paged after ten entries. Select a save, confirm that you wish to discard the current session, and the chosen game replaces it. You may also delete a listed save after confirmation.
4. Choose **Settings** to open `DLG90001` **Settings**. The **Warn when civilians have no work order on end turn** switch applies on the next end-turn confirm, without restarting the app. Map-theme choices persist and apply after you restart the app. A theme group with only one choice is not shown.
5. Choose **Exit to Main Menu** only when you mean to leave the current game. The pause panel closes first and the game asks for confirmation before returning to the main menu.

`GAME50001` **Game side menu** is separate from the pause menu. It offers read-only Game Parameters (including whether you chose **Infinite mode** at new game) and the Debug log. It is not the place to save, load, or change settings.

## Counsel

**Counsel.** Hark, my liege: treat the final review before **Next turn** as a council meeting. Check food, treasury, vulnerable armies, and unfinished work before you commit the realm to events you cannot recall.

**Warning.** Do not mistake a decree for its result. A march, treaty, recipe, or market offer is settled in its appointed step and may meet another court’s decree before you can choose actions again.

**Tip.** Name manual saves for a decision you may wish to revisit—before a war, great purchase, or expedition—rather than trusting memory alone.

**Tip.** Idle civilians may be named at end-turn so you can assign them; research seats will not. If you paused funding to spare gold, that silence is intentional—not an oversight by the dialog.

## The other courts

Every other Great Power plans while you plan. It only uses what it can see. A chosen **leader** makes that court bolder or more cautious. It may build, seek an alliance, research, move, or make war before you tap **Next turn**.

Their choices are not passive. A rival may strengthen its industry, seek an alliance, pursue research, move into a contested frontier, or make war while your own decrees still await **Next turn**.

## Consequences

- A completed turn can change your stores, treasury, labour, relations, research, unit locations, province ownership, and market holdings before you act again.
- News is a summary, not a substitute for inspection. Read `DLG50001` **Turn news dialog**, then check the affected province, fleet, diplomacy, production, and technology views.
- Saving preserves a named point in your campaign; loading from pause deliberately discards the active session in favour of the selected save.
- The fixed calendar keeps moving with each completed turn: early decades pass quickly, while the years after 1700 become more granular.
- **Military victory** is holding 31 or more Old World provinces (see Chapter 15). After the last full turn of year **1800** finishes with no military victory, `OVL20001` **Victory overlay** announces **Campaign complete** and further **Next turn** actions stay blocked. **Infinite mode** (chosen at new game; shown read-only on `GAME50001` **Game side menu** Game Parameters) does not halt the calendar that way. Choosing **View Final State** to look at the map does not turn **Next turn** back on.

## Acceptance criteria for this chapter

- [ ] Explains the map tab-bar labour readout (`effective/full capacity`) before **Next turn**, including empty-pool `0/0`, colour tiers, and popover detail without blocking end turn.
- [ ] Explains ending a turn via operable `DLG60001` **Next turn confirmation**, including both titles, the turn-number body, **Staged this turn**, **Review decrees**, go-to without ending the turn, **No work order** rows, and **Processing Turn**.
- [ ] States that `DLG60001` may warn about idle Explorer, Builder, Engineer, Merchant, and Rail Builder civilians (not Spies) but does **not** warn about empty or unfunded research seats.
- [ ] Summarizes what happens after **Next turn** in the game’s fixed order, including recipes and unused labour, and states that results appear after that work, including possible diplomacy answers on `OVL30001`, `OVL50001`, and `OVL40001`.
- [ ] Documents `DLG50001` **Turn news dialog**, **No major events last turn.**, victory precedence, and the spy-report **open Intelligence** line to `GAME30003` **Intelligence Council**; documents operable `OVL70001` **Player turn event feed** (newspaper button after treasury and cargo; hidden default; badge), including spy-court, combat, discovery, and medal taps.
- [ ] Documents last-turn pulses on `MAP10001` **Empire overview / map area** after turn news (or after **View Final State** on military victory or **Campaign complete**), Old/New World tab switch, Skip/tap without opening panels, the six-place cap, and that the feed keeps the full list.
- [ ] Documents `SHEL40001` pause actions plus `DLG70001` saving (20-save cap), `DLG80001` loading, and `DLG90001` settings (no-work-order switch immediate; map themes on restart).
- [ ] Distinguishes `GAME50001` **Game side menu** from the pause menu, including read-only Infinite mode.
- [ ] States default calendar pacing, military victory vs **Campaign complete**, Infinite mode, and rival Great Powers’ per-turn planning in everyday words.

## Sources

- `SPEC/game/turn-time-mapping.md`
- `SPEC/game/victory.md`
- `SPEC/program/turn-resolution-phases.md`
- `SPEC/ui/next-turn-confirmation.md`
- `SPEC/ui/components/staged-decree-review.md`
- `SPEC/ui/ux-design-decisions.md`
- `SPEC/ui/turn-news-dialog.md`
- `SPEC/ui/player-turn-event-feed.md`
- `SPEC/ui/map-widget.md`
- `SPEC/ui/empire-overview.md`
- `SPEC/ui/victory-overlay.md`
- `SPEC/ui/intelligence-council.md`
- `SPEC/program/intelligence-digest.md`
- `SPEC/ui/save-game-name-dialog.md`
- `SPEC/ui/load-game-list-dialog.md`
- `SPEC/ui/pause-menu-panel.md`
- `SPEC/ui/settings-dialog.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ui/game-side-menu.md`
- `SPEC/ui/overture-dialogue-overlay.md`
- `SPEC/ui/screens/pending-intervention-overlay.md`
- `SPEC/ui/call-to-arms-dialogue-overlay.md`
- `SPEC/ui/province-sea-zone-detail-overlay.md`
- `SPEC/ui/production-panel.md`
- `SPEC/ui/trade-screen.md`
- `SPEC/ai/ai-architecture.md`
