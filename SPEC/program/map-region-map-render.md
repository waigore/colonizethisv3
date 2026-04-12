# Region map Flame render layout

**SPEC/program** — File structure for `CtRegionMapComponent` rendering (Flame). UI behavior of layers remains in `SPEC/ui/map-widget.md`.

## Library parts

`app/lib/features/game/flame/region_map_component.dart` is a single library; the class stays one type. Rendering is split into **`part` files**, each using a **named `extension … on CtRegionMapComponent`** so private members stay library-private (no mixins, no widened visibility).

| Part | Extension (name) | Primary responsibility |
|------|-------------------|-------------------------|
| `region_map_component_render_orchestrator.dart` | `_CtRegionMapRenderOrchestrator` | Visibility helpers, `_renderRegionMap` **call order** (stacking) |
| `region_map_component_render_core.dart` | `_CtRegionMapRenderCore` | Terrain / tile Wang passes, resource overlay, corner labels |
| `region_map_component_render_political.dart` | `_CtRegionMapRenderPolitical` | GP ownership tint, province/faction borders, province names, hovered-province glow |
| `region_map_component_render_markers.dart` | `_CtRegionMapRenderMarkers` | Capitals, towns, warp zones, civilians, fleets, hover selector, tile selection highlights |

Shared constants and small pure helpers used across layers: `region_map_component_shared.dart`. Pure warp-glow segment math (test without canvas): `warp_zone_edge_geometry.dart`.

## Paint order

`_renderRegionMap` invocation order is **normative** for stacking. Refactors must **not** reorder calls unless `SPEC/ui/map-widget.md` (or a superseding UI spec) is updated explicitly.

## Acceptance criteria

- Given a change to region map rendering, when the change is reviewed, then `_renderRegionMap` call order matches the prior documented sequence unless UI spec was updated for intentional layer changes.
