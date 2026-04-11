# Dependency injection (Riverpod in packages)

**SPEC/program** — how shared packages expose injectable dependencies for tests and Flutter composition roots.

---

## Goals

- Keep **game rules and map generation** free of Flutter; use the Dart **`riverpod`** package (not `flutter_riverpod`) inside `colonizethis_logic`, `colonizethis_map`, and `colonizethis_ai`.
- Expose **canonical `Provider`s** for cross-cutting seams (order suggestions, game events, tile-map generation).
- Preserve **backward compatibility**: leaf APIs accept **optional** parameters; when `null`, behavior matches the previous hard-coded default (CLI tools and tests that do not import DI).

---

## Canonical providers

| Provider | Package | Default |
|----------|---------|---------|
| `orderSuggestionApiProvider` | `colonizethis_logic` | `DefaultOrderSuggestionAPI` |
| `gameEventBusProvider` | `colonizethis_logic` | `DefaultGameEventBus` |
| `tileMapRegionGeneratorProvider` | `colonizethis_map` | `defaultTileMapRegionGenerator` |

Import DI from secondary libraries (avoid pulling Riverpod into consumers that do not need it):

- `package:colonizethis_logic/di.dart`
- `package:colonizethis_map/di.dart`
- `package:colonizethis_ai/di.dart` (re-exports logic providers used by AI tests)

The main package barrels (`colonizethis_logic.dart`, `colonizethis_map.dart`) do **not** export these providers.

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
