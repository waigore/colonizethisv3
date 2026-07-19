# Map Theme Catalog and Startup Resolution

**SPEC/program** — Bundled map tileset/icon theme catalog, per-group Hive settings keys, and once-per-process startup resolution for Flame caches. UI surface: [`../ui/settings-dialog.md`](../ui/settings-dialog.md). Terrain inventory: [`../ui/wang-tileset-and-assets.md`](../ui/wang-tileset-and-assets.md). Decode lint: [`repo-lint.md`](repo-lint.md) § `check_app_asset_image_decode_dedup`. Theme selection is **app-global** (Hive `settings` box), not savegame data ([`save-load.md`](save-load.md)).

---

## Responsibility

- Declare theme groups and themes in bundled `assets/data/map_themes.json`.
- Persist per-group theme ids in Hive `settings` via `settingsProvider`.
- Resolve selections once after the settings box opens at app start into an immutable `ActiveMapTheme` consumed by Flame caches.
- Apply themes on **next app start** only (no mid-session cache invalidation).

---

## Theme groups

| Group id | Cache / config boundary |
|----------|-------------------------|
| `terrain` | `MapTerrainConfig` + `TerrainTilesetCache` / `TransportOverlayTilesetCache` (Wang + standalone + transport) |
| `civilian_icons` | `CivilianIconCache` |
| `town_icons` | `TownIconCache` |
| `resource_icons` | `ResourceIconCache` |
| `fleet_icons` | `FleetIconCache` |
| `province_label_icons` | `ProvinceLabelIconCache` (includes `map_presence_*`) |

There is **no** separate `map_presence_icons` group.

---

## Manifest schema

Root object: `{ "groups": { "<group_id>": { "themes": [ ... ] } } }`.

Every listed group id above **must** appear and contain at least one theme with `id: "default"`.

**Terrain theme entry:** `id`, `name_l10n_key`, `tileset_config` (asset path to tileset JSON), `standalone_tile_prefix` (directory+stem prefix before `<stem>.png`, identical filenames across themes).

**Icon-group theme entry:** `id`, `name_l10n_key`, `icon_prefix` (directory prefix before icon filename).

Filenames/stems are identical across themes within a group; only the prefix (and terrain tileset config path) changes.

Loader fail-fast validates schema (required keys/types). Asset-existence tests verify every declared theme’s assets are present in the bundle.

---

## Settings keys

| Group | Hive key | Default |
|-------|----------|---------|
| terrain | `mapTheme.terrain` | `default` |
| civilian_icons | `mapTheme.civilianIcons` | `default` |
| town_icons | `mapTheme.townIcons` | `default` |
| resource_icons | `mapTheme.resourceIcons` | `default` |
| fleet_icons | `mapTheme.fleetIcons` | `default` |
| province_label_icons | `mapTheme.provinceLabelIcons` | `default` |

Unknown or corrupt stored ids → resolve to `default` and log a warning (`app.map` / theme logger prefix); startup must not crash.

---

## Startup resolution

1. Open Hive `settings` box.
2. Load `MapThemeCatalog` from `assets/data/map_themes.json`.
3. Read stored ids; validate against catalog; build immutable `ActiveMapTheme`.
4. Install as process-wide current theme.
5. Call `MapTerrainConfig.ensureLoaded(assetPath: active.terrainTilesetConfigPath)`.

`MapTerrainConfig` memoization: once loaded for a process, later `ensureLoaded` calls are no-ops. A request for a **different** path after load must not silently replace the instance (log warning; keep first load). Tools/tests use `resetForTest()` before loading another path.

Flame icon caches build `assetPath` from `ActiveMapTheme` icon prefixes during `load()`. Unconfigured / test defaults use identity paths equal to today’s `assets/icons/64/` and `assets/images/terrain/tile_`.

---

## Acceptance criteria

- Given a fresh install with empty settings, when the System resolves themes at startup, then every group selects `default` and default asset paths match the pre-theme paths used by region-map goldens.
- Given a catalog manifest, when a schema/asset-existence test runs, then every group has a `default` theme and every declared theme’s required assets exist in the bundle.
- Given a stored theme id absent from the catalog, when the System resolves at startup, then that group falls back to `default`, a warning is logged, and startup completes.
- Given `ActiveMapTheme` installed with a non-default terrain `tileset_config`, when `TerrainTilesetCache.load()` runs, then `MapTerrainConfig` was loaded from that config path (verified by path/assert test).
- Given `ActiveMapTheme` installed with a non-default civilian `icon_prefix`, when `CivilianIconCache` builds paths for the six civilian slugs, then each path uses that prefix.
- Given icon caches load themed PNGs, when `tool/check_app_asset_image_decode_dedup.dart` runs, then every concrete `*IconCache` still extends `AssetImageCache` and decode routes through `decodeImageAsset`.
