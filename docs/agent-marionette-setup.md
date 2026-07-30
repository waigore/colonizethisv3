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

v1 relies on Marionette defaults (Material recognizers). Primary chrome (left rail, Next turn, dialogs) may need `MarionetteConfiguration` in a follow-up slice if elements are not listed — see #4199 WS1 discoverability AC.

## Related

- Binding gate: `app/lib/config/marionette_app_binding.dart`
- SPEC: `SPEC/program/agent-marionette.md`
