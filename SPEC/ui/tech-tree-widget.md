# Tech Tree Widget

**SPEC/ui** — Full-screen tech tree graph for the Flutter app. Presents the entire tech catalog as a left-to-right DAG with player research state and a description dialog. Game rules: [tech-tree.md](../game/tech-tree.md), [research-state.md](../game/research-state.md).

## Purpose

- **Placement:** Shown as a **separate full-screen tab** within the Technology flow. The Technology entry (e.g. from the in-game shell) opens a full-screen view with at least two tabs: one for research slots (existing behaviour) and one for the **Tech Tree** (this widget). The Tree tab occupies the full screen and shows the graph.
- **Role:** Allow the player to see the whole tech tree at a glance, understand prerequisites from layout and explicit edges, and read a brief effect description per tech. Research assignment remains in the slots tab; this widget is read-only for assignment.

## Layout

- **Graph:** All techs from the global catalog in a single graph. **Left to right:** starting techs (no prerequisites) at the left; end-game techs at the right. Nodes are arranged in **topological layers** (by distance from roots); within a layer, nodes may be grouped or spaced to reduce edge crossings.
- **Column rule:** If tech A has a prerequisite tech B, then A must be in a column strictly to the right of B. Thus when there is both a chain (A→B→C) and a direct edge (A→C), there is necessarily a gap between A and C, because B occupies the column in between.
- **Edges:** **Right-angled connectors** from each prerequisite tech to the tech that requires it. Each edge is drawn as three segments: horizontal from the source node’s right edge into the inter-column gap; vertical at that X to the target row; horizontal to the target node’s left edge. The bend X is placed just to the right of the source column (e.g. source right + half the layer gap minus node width) so the vertical segment never passes through other columns’ nodes. Edges are drawn **behind nodes** so they do not obscure node labels or node bodies. For edges that span multiple columns, the layout reserves a row slot in each intermediate column for the connector (as if a tech occupied that slot); other techs in those columns are shifted down so connectors never pass through nodes.
- **Scroll:** The graph can be long; the content is inside a **scrollable** viewport (e.g. `SingleChildScrollView` with both axes, or scrollable region). No zoom or pan required for current product.
- **Categories:** One graph shows **all** techs. Each node is **color-coded by category** (gathering, transport, labour, civilian, diplomacy, naval, military; new-world if present). Category colours are distinct and consistent (e.g. gathering = green, transport = blue, labour = amber, etc.; exact palette in theme or widget).

## Icons (one per category)

Each tech node displays a **category icon** to the left of its label. Icons are assigned by category—every tech inherits the icon of its category:

| Category | Icon filename | Icon description |
|----------|---------------|------------------|
| gathering | `ui_icon_tech_gathering.png` | Shovel/pickaxe for resource extraction |
| new-world | `ui_icon_tech_new_world.png` | Compass or globe for New World discoveries |
| transport | `ui_icon_tech_transport.png` | Road/wagon icon |
| labour | `ui_icon_tech_labour.png` | Quill/pen for trade and commerce |
| civilian | `ui_icon_tech_civilian.png` | Town hall/building icon |
| diplomacy | `ui_icon_tech_diplomacy.png` | Dove with olive branch |
| naval | `ui_icon_tech_naval.png` | Ship/anchor icon |
| military | `ui_icon_tech_military.png` | Crossed swords or shield |

**File naming:** `ui_icon_tech_<category>.png` in `app/assets/icons/` (same directory as other `ui_icon_*.png` files; see [game-toolbar-icons.md](game-toolbar-icons.md)).

**Size:** 32×32, matching toolbar icons per [game-toolbar-icons.md](game-toolbar-icons.md).

**Style:** Colonial 16th/17th century pixel art, matching existing UI icons (single color outline, medium shading).

### Implementation

The widget reads `tech.category` and looks up the icon path via a static map (`kAppIconAssetPrefix` is `assets/icons/32/` from `lib/config/app_constants.dart`, re-exported via `lib/config/app_assets.dart`). Render with `StrictAssetIcon` so a missing or invalid file throws `FlutterError` (no silent placeholder).

```dart
static const Map<String, String> _categoryIcons = {
  'gathering': '${kAppIconAssetPrefix}ui_icon_tech_gathering.png',
  'new-world': '${kAppIconAssetPrefix}ui_icon_tech_new_world.png',
  'transport': '${kAppIconAssetPrefix}ui_icon_tech_transport.png',
  'labour': '${kAppIconAssetPrefix}ui_icon_tech_labour.png',
  'civilian': '${kAppIconAssetPrefix}ui_icon_tech_civilian.png',
  'diplomacy': '${kAppIconAssetPrefix}ui_icon_tech_diplomacy.png',
  'naval': '${kAppIconAssetPrefix}ui_icon_tech_naval.png',
  'military': '${kAppIconAssetPrefix}ui_icon_tech_military.png',
};
```

Each tech category in the catalog must have a mapped icon asset. Missing or invalid icon assets are contract violations and must fail during development/test rendering.

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

- **Trigger:** Tap/click on any tech node (including locked) opens a **dialog** (or bottom sheet on narrow viewports) with a brief description, so players can see benefits and effects for locked techs too.
- **Content:** Display name, era (I–IV), category label, RP cost, **prerequisites** (list of prerequisite tech display names), and **effect summary** (e.g. “Unlocks Halberdiers”, “Extraction cap +1 for Ore”, “Road level 2”, “Fourth research slot”). Prerequisites are listed clearly in the dialog.
- **Interaction:** Dialog is read-only. No “Assign to slot” from the dialog; assignment stays in the slots tab.

## Data

- **Catalog:** `techCatalog` from colonizethis_data (id, era, category, cost, prerequisiteIds, regimentUnlockIds, shipUnlockIds, etc.). Display name: humanized from id (e.g. `road_construction` → “Road Construction”) unless a display-name map is added.
- **Effect summary (dialog):** Authored per-tech lines live in `packages/colonizethis_data/lib/src/data/tech_effect_summary.yaml` (embedded at runtime via `tech_effect_summary_embed.dart`). Each line has a stable id (`techEffectSummary_<techId>_<index>`) and English template text. The Flutter app resolves those ids through **`AppLocalizations`** (keys merged into `app/lib/l10n/arb/app_en.arb` by `tool/generate_tech_effect_l10n.dart`). Regiment/ship unlock bullets and category fallback strings are separate ARB messages. Do not add large per-tech `switch`es in the widget for this copy.
- **Player:** `Player.techUnlocked`, `Player.researchProgressByTechId`, `Player.researchSlots`. **Researchable** set is required: techs whose prerequisites are all in `techUnlocked`, tech not in `techUnlocked`, and not already in `researchProgressByTechId`.

## Acceptance criteria

- **Given** the user is on the Technology full-screen and selects the **Tech Tree** tab, **when** the tab is shown, **then** the UI layer displays the full tech tree as a graph with nodes left-to-right (starting techs left, end-game right) and explicit prerequisite edges between nodes.

- **Given** the tech tree is visible, **when** the viewport is smaller than the graph content, **then** the user can scroll horizontally and vertically to see all nodes and edges.

- **Given** the current player has some techs researched, **when** the tech tree is displayed, **then** each tech node shows the correct state: researched (filled/bright), in progress (e.g. progress indicator), available (all prereqs met, not unlocked), or locked (prereqs missing), with distinct visuals for each.

- **Given** the tech tree is displayed, **when** the user taps or clicks a tech node (including a locked one), **then** a dialog opens showing that tech’s display name, era, category, RP cost, prerequisites list (when any), and effect summary.

- **Given** the tech tree is displayed, **when** the user views any node, **then** the node is color-coded by its category (gathering, transport, labour, civilian, diplomacy, naval, military, or new-world) with consistent colours across the tree.

- **Given** the description dialog is open, **when** the user dismisses it (e.g. tap outside or Close), **then** the dialog closes and the tree remains visible with no state change.

- **Given** the Technology flow is opened from the in-game shell, **when** the user selects the Tech Tree tab, **then** the tree tab is full-screen (or fills the Technology view) and does not offer research slot assignment; assignment is only in the slots tab.

- **Given** the tech tree contains a chain A→B→C and a direct edge A→C (e.g. Apprentice Workers→University→Master Artisans with Master Artisans also requiring Apprentice Workers), **when** the tech tree is displayed, **then** A is in a column to the left of B, and B is in a column to the left of C, so that there is a gap between A and C with B occupying the column in between.

## Integration

- **Source of truth:** [tech-tree.md](../game/tech-tree.md), [research-state.md](../game/research-state.md). Research resolution: [research-resolution.md](../program/research-resolution.md).
- **Widgetbook:** At least one story that simulates a **mid-game scenario**: roughly half of techs researched, half still to go, and one or two techs in progress. This story uses a mock or real `Game` / `Player` with `techUnlocked` and `researchProgressByTechId` set accordingly.
- **App:** Technology entry opens full-screen with tabs (e.g. “Slots”, “Tree”). Tree tab hosts this widget. Register in widget catalog.

## Out of scope

- Assigning research from the tree (slots only).
- Zoom or pan of the graph (scroll only).
- Filtering by category (one graph, colour only).
