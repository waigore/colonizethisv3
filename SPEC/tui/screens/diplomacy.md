# Diplomacy Screen

**SPEC/tui/screens/diplomacy.md** — TUI-specific Diplomacy screen per SPEC/tui/ctterm.md.

**Screen ID:** 100013

## Overview

Diplomacy screen for managing relations with other Great Powers, Minor Nations, and Tribes. Allows issuing diplomatic orders (war, peace, alliances, overtures), viewing relation states, and responding to diplomatic events. Reference: [SPEC/game/diplomacy.md](../../game/diplomacy.md), [SPEC/program/diplomacy-resolution.md](../../program/diplomacy-resolution.md).

## UI/UX

- **Layout:** Split view - faction list on left, detail/relations panel on right (or stacked on narrow terminals).
- **Navigation:** Back to In-Game Shell via Escape key.
- **Faction display:** Show all factions (GPs, Minors, Tribes) with relation status.
- **Keyboard-first:** All actions via keyboard shortcuts.

## Functionality

### Faction List Display

- **Given** the user opens the Diplomacy screen
- **When** viewing the faction list
- **Then** display all factions showing:
  - Faction name and type (Great Power / Minor Nation / Tribe)
  - Relation state (AT_PEACE / AT_WAR) with the player
  - Relation level (Hostile / Neutral / Friendly / Allied)
  - Overture stage (for Minors/Tribes: none, Consulate, Embassy, NAP, Join Empire/Colony)

### Great Power Relations

- **Given** the user selects a Great Power
- **When** viewing the relation details
- **Then** show:
  - Current relation state and score (0-100)
  - Relation level derived from score
  - SinceTurn (when current state began)
  - LastInteractionTurn

### Declare War (GP)

- **Given** the user controls a Great Power at relation state AT_PEACE with a target Great Power
- **When** they issue a Declare War order
- **Then** the order is validated:
  - Must be at AT_PEACE
  - Check treasury if applicable
- **And** display validation result (accepted/rejected with reason)

### Offer Peace (GP)

- **Given** the user controls a Great Power at relation state AT_WAR with a target Great Power
- **When** they issue an Offer Peace order
- **Then** the order is validated:
  - Must be at AT_WAR
  - Both sides must agree
- **And** display validation result

### Alliance (GP)

- **Given** the user controls a Great Power at relation score ≥ 76 with a target Great Power
- **When** they propose or accept an Alliance
- **Then** the order is validated:
  - Both must be at AT_PEACE
  - Relation score must be ≥ 76 (Allied level)
- **And** display validation result

### Minor/Tribe Overtures

- **Given** the user selects a Minor Nation or Tribe
- **When** viewing overture options
- **Then** show available overture stages:
  - Trade Consulate (cost: £500)
  - Embassy (cost: £1000, requires Consulate)
  - Non-Aggression Pact (free, requires Embassy)
  - Join Empire/Colony (cost: £5000 + £2000 per province, requires NAP and Friendly+ relation)

### Establish Overture

- **Given** the user controls a Great Power with sufficient treasury and meets overture prerequisites
- **When** they issue an Establish Overture order (Consulate, Embassy, NAP)
- **Then** the order is validated:
  - Previous overture stage must be achieved
  - Treasury must cover cost (except NAP)
  - Must not be at AT_WAR with target
- **And** display validation result (accepted/rejected with reason)

### Join Empire / Colony

- **Given** the user controls a Great Power with Embassy, at NAP stage, relation score ≥ 51, and sufficient treasury
- **When** they issue a Join Empire order targeting a Minor or Colony order targeting a Tribe
- **Then** the order is validated:
  - Must have Embassy with target
  - Must be at NAP stage
  - Relation score must be ≥ 51 (Friendly or Allied)
  - Treasury must be ≥ base cost + (province count × per-province cost)
- **And** display validation result

### Grant Aid

- **Given** the user controls a Great Power with an Embassy in a Minor/Tribe
- **When** they issue a Grant Aid order
- **Then** the order is validated:
  - Embassy must exist with target
  - Treasury must cover aid amount
- **And** deduct treasury, improve relation score

### Set Subsidy

- **Given** the user controls a Great Power with Consulate or Embassy
- **When** they issue a Set Subsidy order
- **Then** the order is validated:
  - Consulate or Embassy must exist with target
  - Treasury must cover subsidy amount
- **And** apply subsidy (to GP: transfers treasury; to Minor/Tribe: improves relation)

### Intervention Choice (When Minor Attacked)

- **Given** the user controls a Great Power with an Embassy in a Minor Nation being attacked
- **When** the system presents an Intervention choice
- **Then** show options:
  - Intervene: enter war with attackers
  - Do Nothing: lose Embassy with Minor
  - Diplomatic Protest: apply relation penalty to attackers

## Acceptance Criteria

- [ ] Diplomacy screen displays title
- [ ] All factions are listed with type, name, relation state
- [ ] User can select a faction via keyboard
- [ ] Selected faction shows relation details (score, level, sinceTurn, overture)
- [ ] User can issue Declare War order to GP at AT_PEACE
- [ ] User can issue Offer Peace order to GP at AT_WAR
- [ ] User can propose/accept Alliance with GP at Allied level
- [ ] User can establish Consulate with Minor/Tribe (if treasury sufficient)
- [ ] User can establish Embassy with Minor/Tribe (if Consulate exists)
- [ ] User can establish NAP with Minor/Tribe (if Embassy exists, free)
- [ ] User can issue Join Empire/Colony (if NAP, Friendly+, treasury sufficient)
- [ ] User can issue Grant Aid (if Embassy exists)
- [ ] User can issue Set Subsidy (if Consulate/Embassy exists)
- [ ] User can respond to Intervention choices when Minor is attacked
- [ ] Order validation feedback is shown (accepted/rejected with reason)
- [ ] Escape key returns to In-Game Shell
- [ ] Works on narrow terminals (stacked layout fallback)

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Arrow keys / j/k | Navigate faction list |
| Enter / Space | Select faction |
| d | Declare War (when GP selected, at peace) |
| p | Offer Peace (when GP selected, at war) |
| l | Propose/Accept Alliance (when GP selected) |
| c | Establish Consulate (when Minor/Tribe selected) |
| e | Establish Embassy (when Minor/Tribe selected) |
| n | Establish NAP (when Minor/Tribe selected) |
| j | Join Empire / Colony (when Minor/Tribe selected) |
| g | Grant Aid (when Minor/Tribe selected) |
| s | Set Subsidy (when Minor/Tribe selected) |
| i | Intervene (when intervention presented) |
| o | Do Nothing (when intervention presented) |
| r | Diplomatic Protest (when intervention presented) |
| Escape | Back to In-Game Shell |
