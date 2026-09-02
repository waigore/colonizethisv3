# Staged decree review

Reusable `DLG60001` body section. No screen ID. Implementation: `app/lib/features/game/flame/overlays/staged_decree_review_section.dart`. Built from `buildStagedDecreeReview` (`staged_decree_review_builder.dart`).

**Consumed by:** `DLG60001` Next turn confirmation ([next-turn-confirmation.md](../next-turn-confirmation.md)).

## Purpose

Show a compact, player-language review of **already staged** human decrees before Yes/No. Families with count 0 are omitted. Empty draft omits the section (no “no decrees” nag). Does **not** list empty/unfunded research seats or idle Spies ([ux-design-decisions.md](../ux-design-decisions.md) UXD-001 / UXD-002).

## Widget contract

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `review` | `StagedDecreeReview` | yes | Precomputed families; empty → widget returns `SizedBox.shrink`. |
| `bodyStyle` / `mutedStyle` | `TextStyle` | yes | `--fg` body and `--muted` secondary. |
| `onGoToFamily` | `void Function(StagedDecreeFamily)?` | no | Per-family go-to; when set, locate `CtIconAction` is enabled. |

## Layout / wireframe

```
staged_section
  CtSectionLabel "Staged this turn"
  compact_summary   // "Army moves (2) · Trade (1)" — families with count > 0 only
  CtActionTextButton Review decrees | Hide decrees
  expanded_list     // only when Review is on
    family_header   // family label + count + CtIconAction locate
    row_label…      // one plain-language line per staged decree
```

Catalog: `CtSectionLabel`, `CtActionTextButton`, `CtIconAction`. No Material `ExpansionTile` / `Checkbox`.

## Behavior

| Control | When enabled | Emits / calls | Side effects |
|---------|--------------|---------------|--------------|
| Review decrees | `review` non-empty | local setState expand | Lists rows; Yes stays enabled. |
| Hide decrees | expanded | local setState collapse | Rows hidden; summary remains. |
| Locate (per family) | `onGoToFamily != null` | `onGoToFamily(family)` | Dialog pops **unconfirmed** (parity with idle-civilian go-to). Routing: civilian work / spy relocate → `UNIT10001`; army moves → military panel; fleet → `UNIT30001`; train/recruit → `GAME20001`; trade → `GAME60001`; research → `GAME40001`; diplomacy → `GAME30001` (requires topology). |

Family order (fixed): civilian work, spy relocate, army moves, fleet moves/missions, training/builds, labour recruit, diplomacy, trade, research.

**Open-path (Refs #4715):** `buildStagedDecreeReview` supplies compact family counts only. Per-decree row labels are built when the player expands **Review decrees** via `expandStagedDecreeReview` (same-turn re-open may reuse `StagedDecreeReviewSessionCache`).

Research rows include only orders with non-empty tech id **and** funding ≠ None.

Copy uses display names (work target, army/fleet labels, tech, commodity, diplomacy action, worker tier). Never raw order class or enum names (`ArmyMoveOrder`, `declareWar`).

## Acceptance criteria

- Given the human draft has at least one staged decree, when the section builds, then the UI layer shows **Staged this turn** and a compact summary that names only families with count > 0 in player language.
- Given the human draft is empty of staged decrees, when the section builds, then the UI layer mounts no staged header and no “no decrees” warning.
- Given a multi-family draft, when the player activates **Review decrees**, then each staged row is listed in plain language and a go-to control is offered per family.
- Given locate is activated on a family, when the callback runs, then confirmation closes without ending the turn.
- Given empty research seats, unfunded research, or idle Spies, when the section builds, then those absences are not listed.
- Given staged rows are visible, when Yes is inspected, then Yes remains enabled (host dialog).

## Tests

- `app/test/staged_decree_review_builder_test.dart`
- `app/test/next_turn_confirmation_staged_decrees_test.dart`
- `app/test/next_turn_confirmation_goldens_test.dart`
- `app/test/spec_components_staged_decree_review_test.dart`

## Related

- [next-turn-confirmation.md](../next-turn-confirmation.md)
- [player-turn-event-feed.md](../player-turn-event-feed.md) (owning-surface go-to parity)
