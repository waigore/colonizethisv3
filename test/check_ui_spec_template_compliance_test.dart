import 'package:test/test.dart';

import '../tool/check_ui_spec_template_compliance.dart';

void main() {
  group('scoreSpecFile', () {
    test('fully compliant spec scores 9/9 as Class C', () {
      final score = scoreSpecFile('SPEC/ui/example.md', _kCompliantSpec);
      expect(score.headerBlock, isTrue);
      expect(score.widgetContract, isTrue);
      expect(score.triggerConditions, isTrue);
      expect(score.layoutWireframe, isTrue);
      expect(score.behavior, isTrue);
      expect(score.behaviorComplete, isTrue);
      expect(score.statesAndVariants, isTrue);
      expect(score.components, isTrue);
      expect(score.widgetbook, isTrue);
      expect(score.acceptanceCriteria, isTrue);
      expect(score.sectionsPresent, 9);
      expect(score.classification, 'C');
    });

    test('Header block requires all three bold-prefixed lines', () {
      final missingWidgetbook = _kCompliantSpec.replaceFirst(
        '**Widgetbook:** `Example` → `app/lib/widgetbook/catalog.dart`',
        'Widgetbook plain text line.',
      );
      final score = scoreSpecFile('SPEC/ui/example.md', missingWidgetbook);
      expect(
        score.headerBlock,
        isFalse,
        reason: 'Missing **Widgetbook:** line invalidates the header block.',
      );
      expect(score.classification, 'B');
    });

    test('Behavior section without subsections counts as incomplete', () {
      final stripped = _kCompliantSpec
          .replaceFirst('### Incoming', '#### Not the right level')
          .replaceFirst(
            '### User actions → outcomes',
            '#### Not the right level',
          );
      final score = scoreSpecFile('SPEC/ui/example.md', stripped);
      expect(score.behavior, isTrue);
      expect(
        score.behaviorComplete,
        isFalse,
        reason: 'Both Incoming and User actions H3 must be present.',
      );
      expect(score.classification, 'B');
      expect(score.missingSummary, contains('Behavior(subs)'));
    });

    test('User actions arrow accepts ASCII -> as well as the unicode →', () {
      final ascii = _kCompliantSpec.replaceFirst(
        '### User actions → outcomes',
        '### User actions -> outcomes',
      );
      final score = scoreSpecFile('SPEC/ui/example.md', ascii);
      expect(score.behaviorComplete, isTrue);
      expect(score.classification, 'C');
    });

    test('Trigger conditions heading alternatives are accepted', () {
      for (final alt in [
        '## Triggers',
        '## Access',
        '## Panel placement and opening',
      ]) {
        final withAlt = _kCompliantSpec.replaceFirst(
          '## Trigger conditions',
          alt,
        );
        final score = scoreSpecFile('SPEC/ui/example.md', withAlt);
        expect(
          score.triggerConditions,
          isTrue,
          reason: 'Should accept "$alt" as Trigger conditions.',
        );
      }
    });

    test('Layout heading alternatives are accepted', () {
      for (final alt in [
        '## Layout',
        '## Wireframe',
        '## Wireframe (conceptual)',
      ]) {
        final withAlt = _kCompliantSpec.replaceFirst(
          '## Layout / wireframe',
          alt,
        );
        final score = scoreSpecFile('SPEC/ui/example.md', withAlt);
        expect(
          score.layoutWireframe,
          isTrue,
          reason: 'Should accept "$alt" as Layout / wireframe.',
        );
      }
    });

    test('Components heading accepts "Widget catalog" alias', () {
      final withAlias = _kCompliantSpec.replaceFirst(
        '## Components',
        '## Widget catalog',
      );
      final score = scoreSpecFile('SPEC/ui/example.md', withAlias);
      expect(score.components, isTrue);
    });

    test(
      'Acceptance criteria heading accepts the Given–When–Then subtitle form',
      () {
        final withSubtitle = _kCompliantSpec.replaceFirst(
          '## Acceptance criteria',
          '## Acceptance Criteria (Given–When–Then)',
        );
        final score = scoreSpecFile('SPEC/ui/example.md', withSubtitle);
        expect(score.acceptanceCriteria, isTrue);
      },
    );

    test('Class A — <=4 sections present', () {
      const spec = '''
# Bare Spec

**SPEC/ui** — Stub doc.

## Acceptance criteria

- Given …
''';
      final score = scoreSpecFile('SPEC/ui/bare.md', spec);
      expect(score.sectionsPresent, lessThanOrEqualTo(4));
      expect(score.classification, 'A');
    });

    test(
      'Class A — header absent and <=6/9 of the remaining sections present',
      () {
        // 6 non-header sections present, header missing -> still Class A.
        const spec = '''
# Spec without header lines

Intro prose with no recognised header markers at all — just narrative text describing what the screen does.

## Widget contract
…
## Trigger conditions
…
## Layout / wireframe
…
## States and variants
…
## Components
…
## Acceptance criteria
…
''';
        final score = scoreSpecFile('SPEC/ui/borderline.md', spec);
        expect(score.headerBlock, isFalse);
        expect(score.nonHeaderSectionsPresent, 6);
        expect(score.classification, 'A');
      },
    );

    test(
      'Class B — 5-8 sections present with header missing or Behavior incomplete',
      () {
        // 7 non-header sections + header missing = 7 total => Class B by the
        // 5–8 path with header absent.
        const spec = '''
# Mostly compliant spec

**Screen ID:** `EX10001`
**SPEC/ui** — Stub doc.

(no Widgetbook line, so header invalid)

## Widget contract
…
## Trigger conditions
…
## Layout / wireframe
…
## Behavior
### Incoming
…
### User actions → outcomes
…
## States and variants
…
## Acceptance criteria
…
## Widgetbook
…
''';
        final score = scoreSpecFile('SPEC/ui/almost.md', spec);
        expect(score.headerBlock, isFalse);
        expect(score.behaviorComplete, isTrue);
        expect(score.classification, 'B');
        expect(score.missingSummary, contains('Header'));
      },
    );
  });
}

const _kCompliantSpec = '''
# Example Spec

**Screen ID:** `EX10001` — stable; do not reassign.
**SPEC/ui** — Stub doc used for the compliance unit test.
**Widgetbook:** `Example` → `app/lib/widgetbook/catalog.dart`

---

## Widget contract

…

## Trigger conditions

…

## Layout / wireframe

…

## Behavior

### Incoming

…

### User actions → outcomes

…

## States and variants

…

## Components

…

## Widgetbook

…

## Acceptance criteria

…
''';
