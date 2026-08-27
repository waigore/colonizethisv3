# Extraction and Improvements

## Overview

Per-tile resource extraction using improvements, constrained by tech level and transport infrastructure. Civilian work orders build improvements, roads, ports, and railroads. Province and tile identity (e.g. owned provinces, tile keys, town and port lookup) follow [world-model-identity.md](world-model-identity.md): extraction and connectivity use **tile keys** (format `regionId|localId|x|y`) and **province ids** (prefixed `regionId|localId`); province lookup must be region-scoped.

---

## Rules

### Province and tile identity

Extraction and connectivity use **tile keys** (format `regionId|localId|x|y`) and **province ids** (prefixed `regionId|localId`). Province lookup must be region-scoped; see [world-model-identity.md](world-model-identity.md).

### Extraction Formula

Each land tile in an owned province may have one extraction improvement (mine, farm, ranch, plantation, fur post, etc.) with an improvement level (0–4) and at most one resource (terrain-constrained per [resource-terrain-region-rules.md](resource-terrain-region-rules.md)), **except** tiles that are a **capital** or a province **town** (`townTileKey`): those tiles **never** hold