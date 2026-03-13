# Tech Tree Widget

**SPEC/ui** — Full-screen tech tree graph for the Flutter app. Presents the entire tech catalog as a left-to-right DAG with player research state and a description dialog. Game rules: [tech-tree.md](../game/tech-tree.md), [research-state.md](../game/research-state.md).

## Purpose

- **Placement:** Shown as a **separate full-screen tab** within the Technology flow. The Technology entry (e.g. from the in-game shell) opens a full-screen view with at least two tabs: one for research slots (existing behaviour) and one for the **Tech Tree** (this widget). The Tree tab occupies the full screen and shows the graph.
- **Role:** Allow the player to see the whole tech tree at a glance, understand prerequisites from layout and explicit edges, and read a brief effect description per tech. Research assignment remains in the slots tab; this widget is read-only for assignment.

## Layout

- **Graph:** All techs from the global catalog in a single graph. **Left to right:** starting techs (no prerequisites) at the left; end-game techs at the right. Nodes are arranged in **topological layers** (by distance from roots); within a layer, nodes may be grouped or spaced to reduce edge crossings.
- **Edges:** **Explicit right‑angled lines** (orthogonal segments) from each prerequisite tech to the tech that requires it. Edges run horizontally out from the source node, then vertically, then horizontally into the target node, and are drawn **behind nodes** so they do not obscure node labels or node bodies.
- **Scroll:** The graph can be long; the content is inside a **scrollable** viewport (e.g. `SingleChildScrollView` with both axes, or scrollable region). No zoom or pan required for MVP.
- **Categories:** One graph shows **all** techs. Each node is **color-coded by category** (gathering, transport, labour, civilian, diplomacy, naval, military; new-world if present). Category colours are distinct and consistent (e.g. gathering = green, transport = blue, labour = amber, etc.; exact palette in theme or widget).

### Legend

- **Category legend:** The tree screen shows a compact legend explaining the colour for each tech category (e.g. gathering = green, transport = blue, etc.), using the same palette as the nodes.
- **State legend:** The legend also explains node state visuals for the current player (Researched, In progress, Available, Locked), matching the styles in the Node states section below.

## Node states (current player only)

For the **current (human) player**, each tech node has one of four visual states:

| State | Condition | Visual |
|-------|-----------|--------|
| **Researched** | Tech id in `player.techUnlocked` and value true | Filled/bright; e.g. solid fill, checkmark, or distinct style |
| **In progress** | Tech id in `player.researchProgressByTechId` (currently in a research slot) | Distinct from “available”; e.g. progress indicator or border |
| **Available** | All prerequisites in `techUnlocked`, tech not unlocked, not in progress | Can research next; e.g. outline/highlight or “ready” style |
| **Locked** | At least one prerequisite missing from `techUnlocked` | Greyed out or dimmed |

States are mutually exclusive; “in progress” takes precedence over “available” when both could apply.

## Description dialog

- **Trigger:** Tap/click on a tech node opens a **dialog** (or bottom sheet on narrow viewports) with a brief description.
- **Content (no prerequisite list):** Display name, era (I–IV), category label, RP cost, and **effect summary** (e.g. “Unlocks Halberdiers”, “Extraction cap +1 for Ore”, “Road level 2”, “Fourth research slot”). Prerequisites are **not** listed in the dialog; the tree layout and edges make them obvious.
- **Interaction:** Dialog is read-only. No “Assign to slot” from the dialog; assignment stays in the slots tab.

## Data

- **Catalog:** `techCatalog` from colonizethis_data (id, era, category, cost, prerequisiteIds, regimentUnlockIds, shipUnlockIds, etc.). Display name: humanized from id (e.g. `road_construction` → “Road Construction”) unless a display-name map is added.
- **Player:** `Player.techUnlocked`, `Player.researchProgressByTechId`, `Player.researchSlots`. **Researchable** set: derived as techs whose prerequisites are all in `techUnlocked`, tech not in `techUnlocked`, and not already in `researchProgressByTechId` (optional; “available” can mean “all prereqs met” only).

## Acceptance criteria

- **Given** the user is on the Technology full-screen and selects the **Tech Tree** tab, **when** the tab is shown, **then** the UI layer displays the full tech tree as a graph with nodes left-to-right (starting techs left, end-game right) and explicit prerequisite edges between nodes.

- **Given** the tech tree is visible, **when** the viewport is smaller than the graph content, **then** the user can scroll horizontally and vertically to see all nodes and edges.

- **Given** the current player has some techs researched, **when** the tech tree is displayed, **then** each tech node shows the correct state: researched (filled/bright), in progress (e.g. progress indicator), available (all prereqs met, not unlocked), or locked (prereqs missing), with distinct visuals for each.

- **Given** the tech tree is displayed, **when** the user taps or clicks a tech node, **then** a dialog (or bottom sheet on narrow) opens showing that tech’s display name, era, category, RP cost, and effect summary; the dialog does **not** list prerequisites.

- **Given** the tech tree is displayed, **when** the user views any node, **then** the node is color-coded by its category (gathering, transport, labour, civilian, diplomacy, naval, military, or new-world) with consistent colours across the tree.

- **Given** the description dialog is open, **when** the user dismisses it (e.g. tap outside or Close), **then** the dialog closes and the tree remains visible with no state change.

- **Given** the Technology flow is opened from the in-game shell, **when** the user selects the Tech Tree tab, **then** the tree tab is full-screen (or fills the Technology view) and does not offer research slot assignment; assignment is only in the slots tab.

## Integration

- **Source of truth:** [tech-tree.md](../game/tech-tree.md), [research-state.md](../game/research-state.md). Research resolution: [research-resolution.md](../program/research-resolution.md).
- **Widgetbook:** At least one story that simulates a **mid-game scenario**: roughly half of techs researched, half still to go, and optionally one or two techs in progress. This story uses a mock or real `Game` / `Player` with `techUnlocked` and `researchProgressByTechId` set accordingly.
- **App:** Technology entry opens full-screen with tabs (e.g. “Slots”, “Tree”). Tree tab hosts this widget. Register in widget catalog.

## Out of scope

- Assigning research from the tree (slots only).
- Zoom or pan of the graph (scroll only).
- Filtering by category (one graph, colour only).
- Prerequisite list in the description dialog.
