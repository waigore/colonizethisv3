# init_game Tool

## Responsibility

CLI entry point for game creation. Thin facade over the setup pipeline in [game-setup-pipeline.md](game-setup-pipeline.md).

## Data Model

- **InitGameOptions:** `cellSize` (int, default 24), `skipFillLakes` (bool, default false), `renderPng` (bool, default true). Implementation may extend options (e.g. `greatPowerColorOverride` for ctdev).
- CLI sets `renderPng` based on whether `--output-map` is provided.

## CLI Interface

**Command:** `melos run init_game -- [options]`

| Argument | Description |
|---|---|
| `--config <path>` | JSON config overriding GameSetupConfig. Optional. |
| `--output-map <path>` | Path for combined OW+NW map PNG. Optional. |
| `--output-markdown <path>` | Path for faction setup markdown. Optional. |
| `--output-game <path>` | Path for saving the game (colonizethis_save). Optional. Save is written when this is set unless `--no-save` is given. |
| `--no-save` | Do not save the game. Overrides `--output-game`. |
| `--seed <int>` | RNG seed; overrides config seed. Non-zero = reproducible; 0/absent = time-based. |
| `--great-powers id1,id2,...` | Comma-separated GP semantic ids. Overrides selectedGreatPowerIds. |
| `--great-power-count N` | First N default GP ids (backward compat; superseded by `--great-powers`). |
| `--prussia-leader ID` | When prussia is selected: leader variant (e.g. frederick_the_great \| frederick_william). |
| `--minor-nation-count N` | Override Minor Nation count. |
| `--tribe-count N` | Override Tribe count. |
| `--num-provinces-old-world N` | Override OW province count. |
| `--num-provinces-new-world N` | Override NW province count. |

**JSON config** (single source for CLI): supported keys are `selectedGreatPowerIds` (array), `greatPowerCount` (fallback), `leaderVariantByGpId` (map GP id → leader variant), `continentCount`, `minorNationCount`, `tribeCount`, `numProvincesOldWorld`, `numProvincesNewWorld`, `seed`. Keys not listed (e.g. `minProvincesPerMinor`) are not read. Paths (config and outputs) are relative to the **current working directory** unless absolute.

## Output Artifacts

| Artifact | Content |
|---|---|
| Savegame | Game state loadable by app and ctdev. Written when `--output-game` provided. |
| Map PNG | Combined OW+NW map with terrain, ownership overlay, capital markers, legend. Written when `--output-map` provided. |
| Markdown | Faction Setup table (faction, type, capital, provinces) and Starting State table (stockpile, workers, treasury, units). Written when `--output-markdown` provided. |

## Integration

- **Upstream:** [game-setup-pipeline.md](game-setup-pipeline.md) (`runInitGame` in colonizethis_logic). **current product:** CLI/JSON only overrides `GameSetupConfig` fields supported here; there is no ruleset JSON merge yet (see [game-setup.md](../game/game-setup.md) § Config, [ruleset-config.md](../game/ruleset-config.md)).
- **Owner:** `tool/init_game` (Dart CLI).

## Constraints

- **Error handling:** On validation or setup failure the CLI catches errors from `runInitGame` (and downstream), prints a short user-facing message to stderr, and exits with a non-zero code. No raw stack trace is shown to the user.
- **Output:** Operational and diagnostic output (progress, paths, game id, faction setup summary) uses the Dart `logger` package per [ctdev-logging.md](ctdev-logging.md). Usage/help (`--help`) is printed to stdout.
- Seed handling delegated to `runInitGame`; CLI passes through to GameSetupConfig.seed.
