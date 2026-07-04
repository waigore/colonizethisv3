# GP Nation-Color Pennant

**SPEC/ui/components** — Compact pennant indicator filled with a Great Power’s per-game map ownership RGB. Refs #3862.

## Purpose

Show which GPs have fully unlocked a tech on the Tech Tree and Choose-tech dialog. Pennants are geometric (no heraldic artwork); colors match map tinting via `factionOwnershipColorMapForOldWorld` + `greatPowerColorOverrideFromGame`.

## Widget contract

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `GpNationColorPennant` | `StatelessWidget` | yes | Renders staff + triangular fly fill |
| `color` | `Color` | yes | GP map ownership RGB |
| `highlighted` | `bool` | no | Accent border when context player |
| `size` | `Size` | no | Default `10×12` logical px (compact `8×10`) |

## Visual

- Pennant shape: narrow vertical staff + triangular fly (not square swatch).
- Fill: `color`.
- Border: 1 px — `EditorialMonoclePalette.accent` when `highlighted`, else `EditorialMonoclePalette.border`.

## Implementation

`app/lib/widgets/gp_nation_color_pennant.dart`

## Acceptance criteria

- **Given** a pennant with `highlighted: true`, **when** the widget builds, **then** the UI layer renders a 1 px accent border.
- **Given** a pennant with `highlighted: false`, **when** the widget builds, **then** the UI layer renders a 1 px standard border.
