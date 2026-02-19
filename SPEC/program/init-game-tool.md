# init_game Tool

## Responsibility

CLI entry point for game creation. Thin facade over the setup pipeline in [game-setup-pipeline.md](game-setup-pipeline.md).

## Data Model

- **InitGameOptions:** `cellSize` (int, default 24), `skipFillLakes` (bool, default false), `renderPng` (bool, default true).
- CLI sets `renderPng` based on whether `--output-map` is provided.

## CLI Interface

**Command:** `melos run init_game -- [options]`

| Argument | Description |
|---|---|
| `--config <path>` | JSON config overriding GameSetupConfig. Optional. |
| `--output-map <path>` | Path for combined OW+NW map PNG. Optional. |
| `--output-markdown <path>` | Path for faction setup markdown. Optional. |
| `--output-game <path>` | Path for saving the game (colonizethis_save). Optional. |
| `--no-save` | Skip saving the game. Overrides `--output-game`. |
| `--seed <int>` | RNG seed; overrides config seed. Non-zero = reproducible; 0/absent = time-based. |
| `--great-powers id1,id2,...` | Comma-separated GP semantic ids. Overrides selectedGreatPowerIds. |
| `--great-power-count N` | First N default GP ids (backward compat; superseded by `--great-powers`). |
| `--minor-nation-count N` | Override Minor Nation count. |
| `--tribe-count N` | Override Tribe count. |
| `--num-provinces-old-world N` | Override OW province count. |
| `--num-provinces-new-world N` | Override NW province count. |

JSON config supports `selectedGreatPowerIds` (array) and `greatPowerCount` (fallback). Paths relative to repo root.

## Output Artifacts

| Artifact | Content |
|---|---|
| Savegame | Game state loadable by app and ctdev. Written when `--output-game` provided. |
| Map PNG | Combined OW+NW map with terrain, ownership overlay, capital markers, legend. Written when `--output-map` provided. |
| Markdown | Faction Setup table (faction, type, capital, provinces) and Starting State table (stockpile, workers, treasury, units). Written when `--output-markdown` provided. |

## Integration

- **Upstream:** [game-setup-pipeline.md](game-setup-pipeline.md) (`runInitGame` in colonizethis_logic).
- **Owner:** `tool/init_game` (Dart CLI).

## Constraints

- Validation errors abort with clear messages.
- Seed handling delegated to `runInitGame`; CLI passes through to GameSetupConfig.seed.
