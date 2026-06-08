# Dependency injection (Riverpod in packages)

**SPEC/program** — how shared packages expose injectable dependencies for tests and Flutter composition roots.

---

## Goals

- Keep **game rules and map generation** free of Flutter; use the Dart **`riverpod`** package (not `flutter_riverpod`) inside `colonizethis_logic`, `colonizethis_map`, and `colonizethis_ai`.
- Expose **canonical `Provider`s** for cross-cutting seams (order suggestions, game events, tile-map generation).
- Preserve **backward compatibility**: leaf APIs accept **optional** parameters; when `null`, behavior matches the previous hard-coded default (CLI tools and tests that do not import DI).

---

## Canonical providers

| Provider | Declared in | Default | Default impl source |
|----------|-------------|---------|---------------------|
| `orderSuggestionApiProvider` | `colonizethis_logic` | `DefaultOrderSuggestionAPI` | `colonizethis_orders` |
| `gameEventBusProvider` | `colonizethis_logic` | `DefaultGameEventBus` | `colonizethis_world` (event bus) |
| `tileMapRegionGeneratorProvider` | `colonizethis_map` | `defaultTileMapRegionGenerator` | `colonizethis_map` |

Import DI from secondary libraries (avoid pulling Riverpod into consumers that do not need it):

- `package:colonizethis_logic/di.dart`
- `package:colonizethis_map/di.dart`
- `package:colonizethis_ai/di.dart` (re-exports logic providers used by AI tests)

The main package barrels (`colonizethis_logic.dart`, `colonizethis_map.dart`) do **not** export these providers.

---

## Post-split provider aggregation (Refs #3290)

After the `colonizethis_logic` domain split, `colonizethis_logic` is a thin core whose `src/di/logic_providers.dart` acts as the **cross-package provider aggregator**: the provider declarations stay in `colonizethis_logic`, but their concrete defaults are imported from the split domain packages.

- `orderSuggestionApiProvider` → `DefaultOrderSuggestionAPI` from `colonizethis_orders`.
- `gameEventBusProvider` → `DefaultGameEventBus` from `colonizethis_world` (the `event_bus/` domain is folded into `colonizethis_world`; there is no standalone `colonizethis_event_bus` package).

Consumer import paths are unchanged by the split (F6): `app/`, `colonizethis_ai`, and tooling continue to read these providers via `package:colonizethis_logic/di.dart`. The thin core remains the single aggregation point, so providers spanning the split packages are **not** distributed into the individual domain packages.

---

## Composition roots

- **Flutter app** (`app/`): Under `ProviderScope`, use `ref.read(orderSuggestionApiProvider)` (and optionally `gameEventBusProvider`) when calling APIs that accept an injected `OrderSuggestionAPI` or when passing an event bus into `resolveTurnForGame`.
- **Tests**: Use `ProviderContainer(overrides: [...])` then `container.read(...)`; dispose the container in `tearDown`.
- **ctdev / tools**: May ignore DI libraries entirely; pass `null` for optional generation or suggestion parameters so built-in defaults apply.

---

## Optional parameters (logic)

- `generateOrdersForPlayerFullAI` / `generateOrdersForGameFullAI`: optional `OrderSuggestionAPI? orderSuggestionApi`; default is `const DefaultOrderSuggestionAPI()`.
- `runInitGame`: optional `TileMapRegionGenerator? generateRegion`; default is `defaultTileMapRegionGenerator` from `colonizethis_map`.

---

## Given–When–Then

- Given a test `ProviderContainer` with `orderSuggestionApiProvider` overridden by a fake implementation, when the test calls full-AI entry points passing `container.read(orderSuggestionApiProvider)`, then the fake is used for suggestions (observable via spy or custom return values).
- Given `runInitGame` is invoked with a custom `TileMapRegionGenerator` that records invocations, when init completes successfully, then the generator was called for each region generation step (e.g. Old World and New World).

---

## Related

- [repo-and-packages.md](repo-and-packages.md) — repo layout; Flutter shell uses Riverpod for UI state.
- [game-events.md](game-events.md) — `GameEventBus` vs `onGameEvent` callback.
