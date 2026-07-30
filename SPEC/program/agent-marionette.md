# Agent Marionette (debug binding)

**Refs #4199 WS1.** Enables AI agents to attach to a **debug** desktop ColonizeThis session via Marionette MCP.

## Binding policy

| Condition | Binding |
|-----------|---------|
| `kDebugMode` and not `FLUTTER_TEST` and not `CT_E2E` | `MarionetteBinding.ensureInitialized()` |
| `flutter test`, `integration_test`, `CT_E2E=true`, or release/profile | `WidgetsFlutterBinding.ensureInitialized()` |

Implementation: `app/lib/config/marionette_app_binding.dart`; production `main()` calls `ensureColonizeThisAppBinding()`. `bootstrapForIntegrationTest` keeps a no-op `ensureBindingInitialized` because the test harness already installed `IntegrationTestWidgetsFlutterBinding`.

## MCP registration

- Cursor: `.cursor/mcp.json` — `marionette_mcp` command
- Grok: `.grok/config.toml` — `[mcp_servers.marionette]`
- OpenCode: user-global MCP (documented in `docs/agent-marionette-setup.md`)

## Out of scope (this slice)

- `export-player-manual` / `player-playthrough` skills (WS2–WS3)
- Full Flame map/tile Semantics catalog (follow-up under #4199 discoverability)

## Ct-* discoverability

`app/lib/config/colonizethis_marionette_configuration.dart` registers primary
editorial-monocle Ct-* controls (`CtNinePatchButton`, text/icon buttons,
`CtBackButton`, `CtToggleSwitch`, `CtSlider`, `CtDropdown`) with
`MarionetteConfiguration` so Marionette lists one element per control with
player-visible label text.

## Acceptance (WS1 subset)

- Given a macOS/Linux debug run without test bindings, when Marionette MCP connects with the VM service URI, then interactive-element listing and tap succeed on main-menu chrome.
- Given `flutter test` or `integration_test`, when suites run, then Marionette binding is not installed and suites do not fail on double-binding.
