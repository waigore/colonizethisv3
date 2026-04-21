# Desktop window startup

**SPEC/program** - Desktop startup policy for `app/` window state on macOS (required) and Linux (best effort), with Windows optional when a Windows runner exists in branch scope.

## 1. Scope

- Platforms: macOS required; Linux best effort; Windows best effort only if the implementation branch includes a Windows runner.
- Applies to the app's single desktop window.
- Does not change web or mobile startup behavior.

## 2. Startup policy

- The system persists desktop preference `desktop.startupMaximized` in the Hive `settings` box.
- Default preference is `true`.
- The system persists the last desktop window state at `desktop.lastWindowState` with:
  - `x` (double)
  - `y` (double)
  - `width` (double)
  - `height` (double)
  - `maximized` (bool)
- Restore data is considered invalid when required fields are missing, non-finite, non-numeric, wrong type, or width/height are below desktop minimum size.
- Startup decision order:
  1. Use valid restored window state.
  2. Otherwise, if `desktop.startupMaximized == true`, open maximized.
  3. Otherwise, open at default size.

## 3. Desktop window constraints

- Desktop minimum window size is `800x600`.
- Default desktop window size fallback is `1280x720`.
- Startup resize/flicker is acceptable.
- Multi-window behavior is out of scope.

## 4. Menu behavior

- Desktop app menu includes a user-facing toggle: `Open maximized on startup`.
- Toggle updates and persists `desktop.startupMaximized` immediately.

## 5. Acceptance criteria (Given-When-Then)

- Given desktop launch with no valid stored window state and `desktop.startupMaximized=true`, when startup policy runs, then the system opens the window maximized.
- Given desktop launch with valid stored non-maximized window bounds, when startup policy runs, then the system restores those bounds and does not force maximized startup.
- Given desktop launch with invalid stored window state data, when startup policy runs, then the system ignores restore data and applies the maximize/default fallback based on `desktop.startupMaximized`.
- Given desktop launch with no valid restore data and `desktop.startupMaximized=false`, when startup policy runs, then the system opens non-maximized with a minimum size of `800x600`.
- Given the user toggles `Open maximized on startup` from the desktop menu, when the action completes, then the system persists the updated boolean in the Hive `settings` box.
- Given web or mobile launch, when the app starts with this feature present, then startup behavior is unchanged from previous baseline.
