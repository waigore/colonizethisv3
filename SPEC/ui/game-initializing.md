# Game Initializing Screen

**SPEC/ui** — App screen shown after Game Setup when the user taps Start Game. Shows discrete generation progress; one-way until complete. Authority: app screen flow (post–Game Setup).

---

## Purpose

After the shell receives `onStartGame` from Game Setup, it runs the game setup pipeline (e.g. `runInitGame`). This screen is shown **during** that work. The user sees discrete steps and cannot cancel; on success the app navigates to Empire overview (in-game shell). On failure the app navigates to home (Main Menu).

---

## Flow

- **From:** Game Setup (user tapped Start Game; shell builds config and starts initialization).
- **To (success):** Empire overview (in-game shell).
- **To (failure):** Main Menu (crash to home — clear in-progress state, show Main Menu).
- **Cancel:** None. One-way until done.

---

## Widget contract (presentational)

The screen is presentational where possible. The shell owns: starting the pipeline, receiving progress/result, and navigation.

| Aspect | Specification |
|--------|---------------|
| **Progress** | Discrete steps. Each step shows a short label. Steps align with [game-setup-pipeline.md](../program/game-setup-pipeline.md) phases (e.g. "Generating Old World…", "Generating New World…", "Linking regions…", "Assigning nations…", "Building world…", "Finalizing…"). Exact labels and count are implementation-defined from pipeline phases. |
| **Display** | Current step label prominent; optional step index (e.g. "Step 2 of 6"). Optional progress indicator (e.g. bar or spinner). Title: e.g. "Generating World" or "Initializing Game". |
| **Interaction** | No cancel or back. User waits. |
| **On success** | Shell navigates to Empire overview. |
| **On failure** | Shell navigates to Main Menu; no retry on this screen. |

---

## Layout

- Centered content; title and current step visible.
- Works on desktop and mobile (see [mobile-adaptation.md](mobile-adaptation.md): SafeArea, readable text, no overflow).
- No pixel-art requirement for this screen unless UXD extends; standard Flutter/theme is fine.

---

## Acceptance criteria

- **Given** the user completed Game Setup and tapped Start Game, **when** the shell starts initialization, **then** the Game Initializing screen is shown with a title and the first discrete step label.
- **When** the pipeline advances to a new phase, **then** the displayed step label updates to the corresponding step.
- **When** initialization completes successfully, **then** the shell navigates to the Empire overview (in-game shell).
- **When** initialization fails, **then** the shell navigates to the Main Menu (crash to home); the user is not left on the initializing screen.
- **Given** the screen is visible, **then** there is no cancel or back control; the flow is one-way until done.

---

## Integration

- **Data:** Shell calls game setup pipeline (e.g. colonizethis_logic `runInitGame`). Pipeline may report progress via callback or stream; the screen consumes that to show the current step.
- **Spec alignment:** Pipeline phases: [game-setup-pipeline.md](../program/game-setup-pipeline.md). App screen flow: [game-setup.md](game-setup.md) § App flow after Start Game.
