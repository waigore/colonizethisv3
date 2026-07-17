# Titled dialogue chrome (component)

**SPEC/ui/components** — Shared title + brass divider + body chrome above [`CtFullScreenDialogueShell`](ct-full-screen-dialogue-shell.md). Implementation: [`app/lib/features/game/widgets/dialogue/titled_dialogue_chrome.dart`](../../../app/lib/features/game/widgets/dialogue/titled_dialogue_chrome.dart).

Not a screen; no stable screen ID.

---

## Purpose

Removes parallel private title widgets and chrome columns from game-start intro and tribe-first-contact overlay builds (issue [#4018](https://github.com/waigore/colonizethisv3/issues/4018)).

---

## Widget contract

| API | Description |
|-----|-------------|
| `TitledDialogueChromeTitle` | Centered title in `titleMedium`, `EditorialMonoclePalette.accent`, `letterSpacing: 0.05 * 16`, `FontWeight.w700`. |
| `buildTitledDialogueChrome` | `backdrop`, `title`, `body`, optional `padding` → `CtFullScreenDialogueShell` wrapping title → `CtSpacing.ml` → `CtBrassDivider` → 14 px gap → `body`. |

---

## Layout / wireframe

```text
CtFullScreenDialogueShell(backdrop, padding)
  Column(min, stretch)
    TitledDialogueChromeTitle(title)
    SizedBox(CtSpacing.ml)
    CtBrassDivider
    SizedBox(14)
    body
```

---

## Consumers

| Screen ID | Spec |
|-----------|------|
| `OVL10001` | game-start intro overlay |
| `OVL80001` | tribe-first-contact overlay |

---

## Acceptance criteria

- **Given** `buildTitledDialogueChrome(title: 'Intro', body: Text('x'))`, **When** settled, **Then** one `CtFullScreenDialogueShell` and one `TitledDialogueChromeTitle` mount, and the title color is `EditorialMonoclePalette.accent`.

---

## Tests

- `app/test/app_wave5_shared_helpers_test.dart`
