# RelationMeter (component)

**SPEC/ui/components** — Reusable 10-step gradient relation meter shown on the diplomacy panel row and the diplomacy detail screen. Implementation: [`app/lib/widgets/relation_meter.dart`](../../../app/lib/widgets/relation_meter.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *Editorial-monocle palette*. Behavior model: [`SPEC/game/diplomacy.md`](../../game/diplomacy.md) § Player-facing relation display — 10-step relation meter (Refs #3753 R13).

Not a screen; no stable screen ID. Canonical meter referenced by the screen specs under [Consumers](#consumers).

---

## Purpose

Renders the hidden decimal relation score as a compact, player-facing **10-step gradient bar** with an indicator on the active step. The numeric score is never shown (Refs #3753 R13.1, R13.2). The bar replaces the legacy 4-band one-word color treatment; the host renders the one-word ladder label ([`relationScoreToDisplayLabel`](../../game/diplomacy.md)) beside the bar in the matching step color (R13.4).

---

## Widget contract

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `score` | `num` | yes | Hidden decimal relation score in `[0, 100]`. Mapped to a 1-based step via `relationScoreToMeterStep` (half-open `[low, high)` bands; final band `[90, 100]` closed). Values outside `[0, 100]` are clamped (step 1 / step 10). |

Constants: `kSegmentWidth = 7`, `kSegmentHeight = 6`, `kActiveSegmentHeight = 12`, `kSegmentGap = 1`, `kRelationMeterActiveStepKeyPrefix = 'relationMeterStep:'`.

Public helper: `relationMeterStepColor(int step)` — the per-step gradient color (see § Gradient).

---

## Layout / wireframe

```text
Semantics(label: "Relation: <ladder word>")  // ExcludeSemantics on the bar
  SizedBox(height: 12)
    Row(min, center)
      [ seg1 ][gap][ seg2 ][gap] … [ seg10 ]   // 10 cells, 7 dp wide each
                         ^ active step: 12 dp tall, 1 dp --fg border,
                           keyed ValueKey('relationMeterStep:<step>')
```

Inactive segments are `kSegmentHeight` (6 dp) tall; the active step is `kActiveSegmentHeight` (12 dp) tall with a 1 dp `EditorialMonoclePalette.fg` border so the indicated step reads at a glance. Each segment is filled with its own `relationMeterStepColor(step)`.

---

## Gradient

`relationMeterStepColor(step)` interpolates in OKLCH from the canonical `--danger` token (`L 0.62`, chroma 0.16, hue 22°) at step 1 to the canonical `--success` token (`L 0.62`, chroma 0.12, hue 150°) at step 10:

- `t = (clamp(step, 1, 10) - 1) / 9`
- `hue = 22 + t × (150 − 22)`, `chroma = 0.16 + t × (0.12 − 0.16)`, `lightness = 0.62` (held constant so the ladder is iso-luminant against `--bg`).

The two endpoints reproduce the relation-state warm-red / cool-green semantic exactly; intermediate steps pass through amber/yellow hues. No new fixed palette tokens are introduced (Refs #3753 R13.3).

---

## Behavior

1. **Step + label.** Each build computes `activeStep = relationScoreToMeterStep(score)` and `label = relationScoreToDisplayLabel(score)` (the 10-word ladder word for that step).
2. **Indicator.** The segment whose index equals `activeStep` is taller, outlined with `--fg`, and carries `ValueKey('relationMeterStep:<step>')`; all other segments are unkeyed.
3. **No score.** The numeric score is never rendered.
4. **Semantics.** The widget exposes a single `Semantics(label: 'Relation: <word>')` and excludes the decorative bar from the semantics tree.
5. **Stateless.** `RelationMeter` is a `StatelessWidget` with no animation or ticker.

---

## States and variants

| `score` | `activeStep` | Ladder word | Indicator color (hue) |
|---------|--------------|-------------|-----------------------|
| `0` | 1 | Hostile | red (22°) |
| `22.4` | 3 | Distrustful | warm amber |
| `50` | 6 | Neutral | yellow-green |
| `90` | 10 | Devoted | green (150°) |
| `100` | 10 | Devoted | green (150°) |

No theme variants; always paints through the editorial-monocle palette.

---

## Consumers

| Screen ID | Spec | Notes |
|-----------|------|-------|
| `GAME30001` | [`diplomacy-panel.md`](../diplomacy-panel.md) | Per-faction row relation line: meter between the WAR/PEACE badge and the one-word ladder label. |
| `GAME30002` | [`diplomacy-detail-screen.md`](../diplomacy-detail-screen.md) | `CURRENT RELATION` card: meter beside the one-word ladder label. |

---

## Widgetbook

Folder `Diplomacy / RelationMeter` → `app/lib/widgetbook/catalog_data_screens.dart`. Use cases: `Hostile (step 1)`, `Neutral (step 6)`, `Devoted (step 10)` — each pins a representative score so the indicator and gradient render at a low, mid, and high step.

---

## Acceptance criteria (Given–When–Then)

- **Given** a `RelationMeter` with `score = 22.4`, **When** it builds, **Then** exactly one segment carries `ValueKey('relationMeterStep:3')` and the host-visible ladder word is `Distrustful`.
- **Given** a `RelationMeter` with `score = 100`, **When** it builds, **Then** the keyed active segment is `relationMeterStep:10` (final closed band) and no numeric score text is rendered.
- **Given** a `RelationMeter` with `score = 9.9`, **When** it builds, **Then** the keyed active segment is `relationMeterStep:1` (half-open lower band).
- **Given** any `step` in `[1, 10]`, **When** `relationMeterStepColor(step)` is evaluated, **Then** step 1 equals `EditorialMonoclePalette.danger` and step 10 equals `EditorialMonoclePalette.success`.
- **Given** a `RelationMeter`, **When** the semantics tree is read, **Then** it exposes a single node labeled `Relation: <ladder word>` and the decorative bar is excluded from semantics.

---

## Tests

- `app/test/relation_meter_test.dart` — active-step key, ladder word, no-score, gradient endpoints, semantics label.
- `app/test/diplomacy_panel_mockup_fidelity_test.dart` — relation word color resolves to the meter-step gradient color.

---

## Related

- Behavior model: [`SPEC/game/diplomacy.md`](../../game/diplomacy.md) § Player-facing relation display.
- Consumers: [`diplomacy-panel.md`](../diplomacy-panel.md) § Relation meter, [`diplomacy-detail-screen.md`](../diplomacy-detail-screen.md) § Current relation. Tracking: [#3753](https://github.com/waigore/colonizethisv3/issues/3753) R13 / S12.
