# Agent Marionette setup (ColonizeThis)

Debug-only wiring for AI agents to drive the desktop app via [Marionette MCP](https://pub.dev/packages/marionette_mcp). Refs #4199 WS1.

## Prerequisites

- macOS or Linux desktop debug build (primary target: macOS)
- Flutter SDK on `PATH` / `FLUTTER_ROOT` set for Grok Dart MCP
- Marionette MCP server installed globally:

```bash
dart pub global activate marionette_mcp
```

Ensure `~/.pub-cache/bin` (or your pub global bin) is on `PATH` so `marionette_mcp` resolves.

## Run the app

From repo root:

```bash
cd app && flutter run -d macos
```

(or `-d linux` on Linux). The app uses `MarionetteBinding` in **debug** when not under `flutter test`, `integration_test`, or `--dart-define=CT_E2E=true`.

Copy the VM service URI from the console (`ws://127.0.0.1:…/ws`) after `flutter run` starts.

## Agent MCP configuration

| Agent | Config location |
|-------|-----------------|
| **Cursor** | Project `.cursor/mcp.json` (`marionette` server) |
| **Grok** | Project `.grok/config.toml` (`[mcp_servers.marionette]`) |
| **OpenCode** | User-global MCP only — add the same `marionette_mcp` command to your user `opencode.json` |

Connect Marionette to the VM service URI from the running debug session, then use `get_interactive_elements`, `tap`, `enter_text`, and `take_screenshots`.

## Custom Ct* widgets

`colonizethisMarionetteConfiguration` (`app/lib/config/colonizethis_marionette_configuration.dart`) marks primary Ct-* chrome as Marionette interaction targets and extracts player-visible labels (button text, tooltips, dropdown selection). Extend that file when new Ct-* controls must be agent-tappable in modes A–B.

Full Flame map/tile Semantics may still need a follow-up slice if map clicks are required beyond panel/rail flows.

## Player handbook

Playtest agents read the derived export at `docs/manual/player-export/` (regenerate via `export-player-manual` / `python3 pytool/export_player_manual.py`), then run **`player-playthrough`** (modes A–E). Authoring manual with Sources remains at `docs/manual/`.

## Related

- Binding gate: `app/lib/config/marionette_app_binding.dart`
- Ct-* Marionette config: `app/lib/config/colonizethis_marionette_configuration.dart`
- SPEC: `SPEC/program/agent-marionette.md`
