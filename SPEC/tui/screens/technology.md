# Technology Screen — TUI Spec

**SPEC/tui/screens** — Technology research panel in ctterm. Full specification for TUI layout, navigation, and Given–When–Then acceptance criteria. Source of truth for technology screen behavior; adapts from SPEC/game/research-state.md, SPEC/game/tech-tree.md, and SPEC/program/research-resolution.md.

---

## Layout

```
┌─────────────────────────────────────────────────────────┐
│ Technology                              [Back: Escape]  │
├─────────────────────────────────────────────────────────┤
│ Research Slots (3/4)                                     │
│ ┌─────┬──────────────────────┬────────┬────────────────┐ │
│ │Slot │ Tech                │ Funding│ Progress      │ │
│ ├─────┼──────────────────────┼────────┼────────────────┤ │
│ │  1  │ [selected tech]     │ Medium │ ████░░ 60/100  │ │
│ │  2  │ — Empty —           │ —      │ —              │ │
│ │  3  │ — Empty —           │ —      │ —              │ │
│ └─────┴──────────────────────┴────────┴────────────────┘ │
├─────────────────────────────────────────────────────────┤
│ Available Techs (category filter: All)                  │
│ ┌──────┬─────────────────┬────────┬───────────────────┐│
│ │ Era  │ Tech            │ Cost   │ Prerequisites     ││
│ ├──────┼─────────────────┼────────┼───────────────────┤│
│ │  I   │ Agriculture     │ 100 RP │ —                 ││
│ │  I   │ Mapping         │ 150 RP │ —                 ││
│ │  II  │ Navigation      │ 200 RP │ Mapping            ││
│ │ ...  │ ...             │ ...    │ ...               ││
│ └──────┴─────────────────┴────────┴───────────────────┘│
├─────────────────────────────────────────────────────────┤
│ Unlocked Techs: 5/24                                     │
│ [F1-Select Slot 1] [F2-Select Slot 2] [F3-Select Slot 3]│
│ [Up/Down-Scroll] [Enter-Assign] [Del-Cancel] [Tab-Filter]│
└─────────────────────────────────────────────────────────┘
```

### Layout Details

- **Header:** Title "Technology", current turn, back hint
- **Research Slots:** 3-4 rows showing current research in each slot:
  - Slot number (1-4)
  - Tech name or "— Empty —"
  - Funding level (None/Low/Medium/High/Maximum)
  - Progress bar + RP fraction
- **Available Techs:** Scrollable list of researchable techs:
  - Era number (I-IV)
  - Tech display name
  - Total RP cost
  - Prerequisites list (or "—")
- **Unlocked Count:** Summary of total techs unlocked
- **Footer:** Keyboard shortcuts

### Responsive Behavior

- **Narrow terminal (<80 cols):** Single column layout; slots and available techs stack vertically; use abbreviations (e.g., "Agric." for "Agriculture")
- **Short terminal (<24 rows):** Paginate available techs; slots always visible; show "More..." prompt

---

## Navigation

| From → To | Trigger | Behavior |
| ---------- | ------- | -------- |
| Shell → Tech | `T` key (global hotkey) | Open Technology panel as overlay |
| Tech → Shell | `Escape` or `Q` | Close panel, return to map |
| Slot selection | `F1`-`F4` | Select research slot (4th slot visible only if University unlocked) |
| Assign tech | `Enter` on available tech | Assign selected tech to selected slot |
| Change funding | `1`-`5` keys | Set funding level (1=None, 2=Low, 3=Medium, 4=High, 5=Maximum) |
| Cancel research | `Delete` or `C` | Clear selected slot (with confirmation) |
| Scroll list | `Up`/`Down` or `W`/`S` | Navigate available techs |
| Filter by category | `Tab` cycles categories | Filter: All → Gathering → Transport → Labour → Diplomacy → Naval → Military → New World |

---

## Given–When–Then Acceptance Criteria

### Viewing Technology Panel

- **Given** the player is in the in-game shell with the map visible  
  **When** the player presses `T`  
  **Then** the Technology panel overlays the map, showing research slots and available techs

- **Given** the terminal is 80×24  
  **When** the Technology panel is opened  
  **Then** the panel uses the full layout described above with both slots and available techs visible

- **Given** the terminal is 60×20 (narrow/short)  
  **When** the Technology panel is opened  
  **Then** the panel shows slots and uses pagination for available techs with "More (↓)" prompt

### Research Slots Display

- **Given** the player has 3 research slots (default)  
  **When** the Technology panel is opened  
  **Then** exactly 3 slots are displayed with slot numbers 1-3

- **Given** the player has researched the "University" tech  
  **When** the Technology panel is opened  
  **Then** 4 slots are displayed (slot 4 visible only when University is unlocked)

- **Given** a slot has an active research tech  
  **When** viewing that slot  
  **Then** the tech name, funding level, and progress bar with RP fraction are shown

- **Given** a slot is empty  
  **When** viewing that slot  
  **Then** "— Empty —" is shown in the tech column, "—" in funding and progress

### Assigning Research

- **Given** a slot is selected and the available techs list is visible  
  **When** the player navigates to a tech and presses `Enter`  
  **Then** that tech is assigned to the selected slot with funding "Medium" (default)

- **Given** a tech requires prerequisites not yet unlocked  
  **When** the player tries to assign it  
  **Then** the assignment is rejected with message "Prerequisites not met: [list]"

- **Given** a tech is already being researched in another slot  
  **When** the player tries to assign it again  
  **Then** the assignment is rejected with message "Already researching [tech name]"

- **Given** a tech is already unlocked  
  **When** the player tries to assign it  
  **Then** the assignment is rejected with message "Already unlocked"

### Funding Levels

- **Given** a slot has a tech assigned  
  **When** the player presses `1`-`5`  
  **Then** the funding level changes: 1=None, 2=Low (50g/100RP), 3=Medium (150g/300RP), 4=High (400g/800RP), 5=Maximum (1000g/2500RP)

- **Given** the player sets funding to "None"  
  **When** the turn advances  
  **Then** no gold is deducted and no research progress is added for that slot

- **Given** the player treasury is insufficient for the selected funding level  
  **When** funding is set  
  **Then** funding is set but a warning "Insufficient funds" is displayed; turn resolution will use available gold

### Cancelling Research

- **Given** a slot has an active research tech with progress > 0  
  **When** the player presses `Delete` or `C`  
  **Then** a confirmation prompt "Cancel research? Progress will be lost. (Y/N)" is shown

- **Given** the confirmation is confirmed  
  **When** cancelling research  
  **Then** the slot is cleared, progress is lost, and the slot shows "— Empty —"

- **Given** the confirmation is rejected  
  **When** cancelling research  
  **Then** the slot remains unchanged

### Available Techs Filtering

- **Given** the available techs list has techs from multiple categories  
  **When** the player presses `Tab`  
  **Then** the category filter cycles: All → Gathering → Transport → Labour → Diplomacy → Naval → Military → New World → All

- **Given** a category filter is active  
  **When** viewing available techs  
  **Then** only techs from that category are shown

- **Given** a tech has prerequisites in another category  
  **When** that category is filtered out but prerequisites are visible  
  **Then** the prerequisite column still shows full info

### Unlocked Techs Display

- **Given** the player has unlocked some techs  
  **When** viewing the Technology panel  
  **Then** the footer shows "Unlocked Techs: X/Y" where X is unlocked count and Y is total catalog size

### Progress Display

- **Given** a tech has 60 RP progress out of 100 RP cost  
  **When** viewing that slot's progress  
  **Then** the progress bar shows "████░░░░" (60% filled) and text "60/100 RP"

- **Given** a tech reaches or exceeds its RP cost during research  
  **When** turn resolution completes  
  **Then** the tech is unlocked, a notification "Research complete: [Tech Name]" is shown, and the slot becomes empty

---

## Keyboard Shortcuts Summary

| Key | Action |
|-----|--------|
| `Escape` / `Q` | Back to shell |
| `F1`-`F4` | Select slot |
| `Enter` | Assign tech to slot |
| `1`-`5` | Set funding level |
| `Delete` / `C` | Cancel research |
| `Up` / `Down` / `W` / `S` | Navigate list |
| `Tab` | Cycle category filter |

---

## Integration Notes

- **Data source:** Player research state (`currentResearchTechId`, `techUnlocked`, `researchableTechIds`, per-slot progress, per-slot funding)
- **Catalog:** Tech tree from SPEC/game/tech-tree.md and category sub-docs
- **Turn resolution:** Research phase per SPEC/program/research-resolution.md
- **Notifications:** Research complete events shown in event feed; insufficient funds warning
- **State persistence:** Research progress and slot assignments saved per SPEC/program/save-load.md

---

## Out of Scope

- AI research orders (human player only)
- Goal slot (UI sorting only, no spending)
- Bulk assign or auto-fill
- Research queue or prioritization
- Tech details popup/information screen (future enhancement)
