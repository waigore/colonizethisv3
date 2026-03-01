# Generating World Screen

**Spec:** SPEC/tui/ctterm.md  
**Source:** SPEC/program/game-setup-pipeline.md (adaptations in ctterm.md)  
**UXD:** 03b

## Overview

The Generating World screen is shown while the game world is being initialized. It displays progress feedback and allows the user to cancel (return to Main Menu).

## Layout

- Centered content
- Title: "Generating World"
- Status line(s): shows current generation phase
- Progress indicator (animated or static text)
- Cancel option: "Press [B] or [Escape] to cancel"

## Interaction

| Input | Action |
|-------|--------|
| B | Cancel generation, return to Main Menu |
| Escape | Cancel generation, return to Main Menu |

## Navigation

- **From:** Game Setup screen (when user confirms start game)
- **To:** In-game shell (on success) or Main Menu (on cancel/failure)

## Acceptance Criteria

### Happy path
- **Given** the user has completed Game Setup and presses Start
- **When** the app begins world generation
- **Then** the Generating World screen is displayed with status "Generating world..."
- **And** the user can wait for generation to complete
- **When** generation completes successfully
- **Then** the app navigates to the In-game shell

### Cancel path
- **Given** the Generating World screen is displayed
- **When** the user presses B or Escape
- **Then** generation is cancelled (if possible)
- **And** the app navigates to the Main Menu

### Error path
- **Given** the Generating World screen is displayed
- **When** generation fails with an error
- **Then** an error message is displayed
- **And** the user can press any key to return to Main Menu

## Technical notes

- This is a blocking screen - user waits while game is generated
- In MVP, the actual game initialization may be async; screen shows until complete
- For now, use a brief delay to simulate generation before navigating to in-game shell
- Full implementation will call the actual game initialization logic from colonizethis_logic
