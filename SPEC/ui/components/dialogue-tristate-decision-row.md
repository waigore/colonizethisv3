# DialogueTristateDecisionRow (component)

**SPEC/ui/components** — Shared dual-toggle tristate decision row for diplomacy dialogue overlays. Implementation: [`app/lib/features/game/widgets/dialogue/dialogue_tristate_decision_row.dart`](../../../app/lib/features/game/widgets/dialogue/dialogue_tristate_decision_row.dart).

This composite is **not** a screen and has **no** stable screen ID.

---

## Purpose

Consolidates the Accept/Join vs Reject/Refuse labeled `CtToggleSwitch` pair previously duplicated between overture offer rows and call-to-arms call rows (issue [#4018](https://github.com/waigore/colonizethisv3/issues/4018)). Preserves #2867 R22 / R24 / R25 tristate semantics (`null` undecided).

---

## Widget contract

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `positiveToggleKey` | `Key` | yes | Key for the success-side `CtToggleSwitch` (Accept / Join). |
| `negativeToggleKey` | `Key` | yes | Key for the danger-side `CtToggleSwitch` (Reject / Refuse). |
| `positiveLabel` | `String` | yes | Label rendered in `--success` beside the positive toggle. |
| `negativeLabel` | `String` | yes | Label rendered in `--danger` beside the negative toggle. |
| `decision` | `bool?` | yes | `null` undecided / `true` positive / `false` negative. |
| `onDecisionChanged` | `ValueChanged<bool?>` | yes | Reports the next tristate value (including `null` on revert). |

Helper: `dialogueTristateAllDecided(Iterable<bool?>)` — `true` when every entry is non-null.

`DialogueLabeledToggle` — toggle + colored label composite used inside the row.

---

## Layout / wireframe

```text
Wrap(alignment: end, spacing: 12, runSpacing: 8)
  DialogueLabeledToggle(positive…)   -- success glow when on
  DialogueLabeledToggle(negative…)   -- danger glow when on
```

---

## Behavior

1. Tapping an off toggle commits that side and clears the other (`true` / `false`).
2. Tapping an on toggle reverts to `null` so Submit gating can re-engage.
3. Labels and glow colors use `EditorialMonoclePalette.success` / `.danger` only.

---

## Consumers

| Screen ID | Spec |
|-----------|------|
| `OVL30001` | [`overture-dialogue-overlay.md`](../overture-dialogue-overlay.md) |
| `OVL40001` | [`call-to-arms-dialogue-overlay.md`](../call-to-arms-dialogue-overlay.md) |

---

## Acceptance criteria

- **Given** `decision == null`, **When** the positive toggle is tapped on, **Then** `onDecisionChanged(true)` fires.
- **Given** `decision == true`, **When** the positive toggle is tapped off, **Then** `onDecisionChanged(null)` fires.
- **Given** decisions `[true, null]`, **When** `dialogueTristateAllDecided` is evaluated, **Then** the System returns `false`.

---

## Tests

- `app/test/app_wave5_shared_helpers_test.dart`
