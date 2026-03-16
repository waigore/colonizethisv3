# Pending Overtures Screen Specification

**SPEC/tui** — Screen shown when turn resolution blocks on the human player accepting or rejecting diplomatic overtures from other players. This screen is the **ctterm presentation** for dialogue points of kind **overture_target_response** per the unified [dialogue system](../../program/dialogue-system.md). Reference: [ctterm.md](../ctterm.md), [dialogue-presentation.md](../dialogue-presentation.md), [SPEC/program/turn-resolution-phases.md](../../program/turn-resolution-phases.md), [SPEC/game/diplomacy.md](../../game/diplomacy.md).

**Screen ID:** 100019

## Overview

When a player ends the turn and another Great Power has offered a diplomatic overture (Trade Consulate, Embassy, Non-Aggression Pact, or Join Empire) to the human-controlled Great Power, turn resolution suspends and the app shows the **Pending Overtures** screen. The human must accept or reject each offer; then resolution resumes and the turn completes (or suspends again if further overtures are pending). Content and behaviour align with [dialogue-management.md](../../ai/dialogue-management.md) and [dialogue-content-and-yarn.md](../../ai/dialogue-content-and-yarn.md) so that dialogue text can be driven by content keys and data assets.

## Content

- **Title:** "Diplomatic overtures" (or equivalent).
- **Explanation:** Short text that other players have offered agreements; the player must accept or reject each.
- **List of offers:** For each pending offer (offerer GP id, target faction id, overture stage):
  - **Offerer:** Display name of the offering Great Power (from `Game.players` where `id == offererGpId`).
  - **Stage:** Human-readable stage label (e.g. "Trade Consulate", "Embassy", "Non-Aggression Pact", "Join Empire").
  - **Current choice:** Accept or Reject (default Accept).

## Keyboard

- **Up / W / Down / S:** Move selection to previous/next offer.
- **A:** Set selected offer to **Accept**.
- **R:** Set selected offer to **Reject**.
- **Enter:** Submit all decisions and resume turn resolution. The app calls `resumeTurnResolutionWithOvertureDecisions` with the collected decisions; then either the turn completes and the player returns to the in-game shell, or resolution suspends again and the screen is updated with the new pending list.

No Escape/Back: the player must submit decisions to proceed.

## Acceptance Criteria

- **Given** turn resolution has returned `TurnResolutionPendingOvertures` with N offers
- **When** the app navigates to the Pending Overtures screen
- **Then** the screen shows the title, explanation, and a list of N offers with offerer name and stage; each offer has a current choice (default Accept).

- **Given** the Pending Overtures screen is shown
- **When** the user presses **A** (or **R**) with an offer selected
- **Then** that offer’s choice is set to Accept (or Reject).

- **Given** the Pending Overtures screen is shown
- **When** the user presses **Enter**
- **Then** the app calls `resumeTurnResolutionWithOvertureDecisions` with one `OvertureDecision` per offer (matching offerer, target, stage, and the user’s choice). If the result is `TurnResolutionComplete`, the app updates the game, clears pending state, navigates to the in-game shell, and invokes the turn-processed callback. If the result is `TurnResolutionPendingOvertures` again, the app updates the game and pending list and keeps the user on the Pending Overtures screen with the new list.
