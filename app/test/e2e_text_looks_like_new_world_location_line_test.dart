/// Pins the dash-glyph contract of [e2eTextLooksLikeNewWorldLocationLine]
/// (`app/integration_test/e2e_test_shared.dart`) — the predicate fleet-reach
/// E2E detection (`_navalPanelShowsNonHomeFleetInNewWorld` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart`) uses to
/// recognize a naval-panel location row like `"New World — Outer Sea"`.
///
/// `naval_tree_builder.dart` joins the region and the location with an
/// **em dash** (`—`), but earlier CI dumps and Material text scaling can
/// normalize the glyph to an **en dash** (`–`) or a plain **hyphen-minus**
/// (`-`). The helper must accept all three so the predicate is not coupled
/// to one specific Unicode glyph; a silent rename to e.g. a colon would
/// otherwise turn the fleet-reach detection into a fail-open and let the
/// loop time out at 35 turns × ~5 s instead of short-circuiting at the
/// fleet's first New World arrival (Refs GitHub #2336 Bottleneck 4 / H1–H4).
///
/// The integration suite cannot validate this directly (the
/// `app_e2e_linux` lane is a no-op per `SPEC/program/e2e-integration-tests.md`
/// § CI), so the widget-test layer carries the behavioural pin.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  suppressLogsForTests();

  group('e2eTextLooksLikeNewWorldLocationLine — accepted shapes', () {
    test('em dash matches the canonical naval_tree_builder glyph', () {
      expect(
        e2eTextLooksLikeNewWorldLocationLine('New World — Outer Sea'),
        isTrue,
        reason:
            'naval_tree_builder.dart joins region and location with U+2014 '
            '(em dash). A regression to a stricter glyph check would lose '
            'the canonical path and stall fleet-reach loops.',
      );
    });

    test('en dash is accepted as a CI / text-scaling normalization', () {
      expect(
        e2eTextLooksLikeNewWorldLocationLine('New World – Outer Sea'),
        isTrue,
        reason:
            'En dash (U+2013) is the historical glyph seen in earlier CI '
            'snapshot dumps; the predicate must continue to recognize it '
            'so loops never re-introduce a dash-glyph dependency.',
      );
    });

    test('hyphen-minus is accepted (ASCII fallback)', () {
      expect(
        e2eTextLooksLikeNewWorldLocationLine('New World - Outer Sea'),
        isTrue,
        reason:
            'Hyphen-minus (U+002D) is the ASCII fallback rendering some '
            'Material text scaling produces; treat the same as em/en dash '
            'so the predicate stays robust to glyph normalization.',
      );
    });

    test('no space between prefix and em dash still matches', () {
      expect(
        e2eTextLooksLikeNewWorldLocationLine('New World—Outer Sea'),
        isTrue,
        reason:
            'The contract trims whitespace after the prefix before looking '
            'for the dash, so a tight join (no spaces) must still match. '
            'A locale that drops the spaces around the dash should not '
            'break fleet-reach detection.',
      );
    });

    test('leading whitespace before "New World" is trimmed', () {
      expect(
        e2eTextLooksLikeNewWorldLocationLine('   New World — Outer Sea'),
        isTrue,
        reason:
            'The contract documents `trimLeft` on the input so accidental '
            'left padding from the naval-tree builder (e.g. indented row '
            'titles on narrow viewports) must not break detection.',
      );
    });
  });

  group('e2eTextLooksLikeNewWorldLocationLine — rejected shapes', () {
    test('null returns false (nothing to inspect)', () {
      expect(
        e2eTextLooksLikeNewWorldLocationLine(null),
        isFalse,
        reason:
            'Text widgets can have a null data field when only InlineSpans '
            'are present; the predicate must reject null instead of '
            'throwing or treating it as a match.',
      );
    });

    test('empty string returns false', () {
      expect(
        e2eTextLooksLikeNewWorldLocationLine(''),
        isFalse,
        reason:
            'An empty title would otherwise startWith every prefix; the '
            'predicate must reject zero-length content explicitly so the '
            'fleet-reach loop never short-circuits on a placeholder Text.',
      );
    });

    test('"New World" alone (no separator) returns false', () {
      expect(
        e2eTextLooksLikeNewWorldLocationLine('New World'),
        isFalse,
        reason:
            'The region chip itself renders as "New World" with no dash; '
            'the predicate must distinguish that from a real location row '
            'so a chip Text does not falsely satisfy fleet-reach.',
      );
    });

    test('"New World" followed by trailing whitespace only returns false', () {
      expect(
        e2eTextLooksLikeNewWorldLocationLine('New World   '),
        isFalse,
        reason:
            'After trimLeft the prefix substring is whitespace-only, which '
            'never starts with em / en / hyphen — the predicate must reject '
            'this so a stale Text with trailing padding does not match.',
      );
    });

    test('"New World:" with colon returns false (wrong separator)', () {
      expect(
        e2eTextLooksLikeNewWorldLocationLine('New World: Outer Sea'),
        isFalse,
        reason:
            'A future naval_tree_builder change that swapped the dash for '
            'a colon must fail this predicate so the regression surfaces '
            'in the test layer instead of as a silent fleet-reach timeout.',
      );
    });

    test('different prefix is rejected', () {
      expect(
        e2eTextLooksLikeNewWorldLocationLine('Old World — Coastal Sea'),
        isFalse,
        reason:
            '"Old World" rows must not satisfy the New World predicate or '
            'fleet-reach detection would fire on Old World fleets too, '
            'breaking the documented "non-home fleet in New World" '
            'contract (`SPEC/program/e2e-integration-tests.md`).',
      );
    });

    test('"New World" appearing mid-string is rejected', () {
      expect(
        e2eTextLooksLikeNewWorldLocationLine('Bound for New World — Outer Sea'),
        isFalse,
        reason:
            'The predicate locks on the trimmed prefix; substring matches '
            'mid-line (e.g. a sentence containing "New World") must not '
            'count so unrelated UI copy does not trigger false positives.',
      );
    });

    test('"New Worlds" (different prefix word) is rejected', () {
      expect(
        e2eTextLooksLikeNewWorldLocationLine('New Worlds — Outer Sea'),
        isFalse,
        reason:
            'The prefix is the literal string "New World" — a future copy '
            'change to a plural form must surface as a failed match here, '
            'not silently break fleet-reach detection.',
      );
    });
  });
}
