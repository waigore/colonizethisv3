// Pins the boundary contract of `e2eExpansionTileIsExpanded`: the helper
// inspects the subtree rooted at the given [Element] for any `RotationTransition`
// whose `turns.value > 0.4` and returns true on the first match. The existing
// `e2e_expand_expansion_tile_test.dart` only pins the two ends of a real
// Material `ExpansionTile` (collapsed → false, `initiallyExpanded: true`
// → true), which never exercises the `> 0.4` threshold, the in-flight
// animation interval, the no-`RotationTransition` subtree, or the early-exit
// short-circuit on the first crossing transition.
//
// The threshold is load-bearing: Material's `ExpansionTile` animates its
// chevron from `turns = 0.0` (collapsed) to `turns = 0.5` (expanded), and
// `e2eExpandEachExpansionTileOnce` polls `e2eExpansionTileIsExpanded` to
// decide when the per-tile expand is done. If the threshold drifted upward
// past 0.5 the helper would never accept a finished animation; if it drifted
// downward toward 0.0 the helper could accept a mid-animation frame and
// resume tapping before children are laid out. Both regressions present as
// runtime cost rather than test failure (Refs GitHub #2336 H10 / Bottleneck 6
// — the icon-presence pre-fix already burned ~26 s per call without any test
// failing), so each boundary needs an explicit pin here.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Mounts a single child rooted under a stable `Center` so the test can
/// resolve a deterministic `Element` to hand to `e2eExpansionTileIsExpanded`.
Future<Element> _pumpAndResolveRoot(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
  final centerFinder = find.byType(Center);
  // `MaterialApp` and `Scaffold` mount their own `Center` descendants, so
  // anchor on the outermost user-supplied `Center` deterministically by
  // taking the first `Center` element found via pre-order traversal.
  return centerFinder.evaluate().first;
}

void main() {
  suppressLogsForTests();

  group('e2eExpansionTileIsExpanded threshold boundary', () {
    testWidgets(
      'returns false when no RotationTransition exists in the subtree',
      (WidgetTester tester) async {
        final root = await _pumpAndResolveRoot(
          tester,
          const Text('no-rotation-here'),
        );
        expect(
          e2eExpansionTileIsExpanded(root),
          isFalse,
          reason:
              'A subtree without any RotationTransition must read as not '
              'expanded so the helper does not falsely advance past a tile '
              'whose chevron is missing or replaced by a non-rotating icon.',
        );
      },
    );

    testWidgets('returns false at exactly the threshold (turns == 0.4)', (
      WidgetTester tester,
    ) async {
      final root = await _pumpAndResolveRoot(
        tester,
        RotationTransition(
          turns: const AlwaysStoppedAnimation<double>(0.4),
          child: const Icon(Icons.expand_more),
        ),
      );
      expect(
        e2eExpansionTileIsExpanded(root),
        isFalse,
        reason:
            'The threshold uses a strict greater-than (`> 0.4`); a tile '
            'whose chevron is parked exactly at the threshold must read as '
            'not yet expanded so the polling loop keeps waiting for the '
            'animation to complete past 0.4 → 0.5.',
      );
    });

    testWidgets('returns true just above the threshold (turns == 0.41)', (
      WidgetTester tester,
    ) async {
      final root = await _pumpAndResolveRoot(
        tester,
        RotationTransition(
          turns: const AlwaysStoppedAnimation<double>(0.41),
          child: const Icon(Icons.expand_more),
        ),
      );
      expect(
        e2eExpansionTileIsExpanded(root),
        isTrue,
        reason:
            'Any RotationTransition.turns strictly greater than 0.4 must '
            'count as expanded so the helper stops polling once the chevron '
            'is past the half-rotated midpoint — even before it parks at '
            'the canonical 0.5 endpoint.',
      );
    });

    testWidgets(
      'returns true at the canonical fully-expanded value (turns == 0.5)',
      (WidgetTester tester) async {
        final root = await _pumpAndResolveRoot(
          tester,
          RotationTransition(
            turns: const AlwaysStoppedAnimation<double>(0.5),
            child: const Icon(Icons.expand_more),
          ),
        );
        expect(
          e2eExpansionTileIsExpanded(root),
          isTrue,
          reason:
              'The canonical Material ExpansionTile expanded endpoint (0.5) '
              'must read as expanded; this is the value the real animation '
              'parks on once the tile is open (Refs `expansion_tile.dart`).',
        );
      },
    );

    testWidgets(
      'returns false at the canonical collapsed value (turns == 0.0)',
      (WidgetTester tester) async {
        final root = await _pumpAndResolveRoot(
          tester,
          RotationTransition(
            turns: const AlwaysStoppedAnimation<double>(0.0),
            child: const Icon(Icons.expand_more),
          ),
        );
        expect(
          e2eExpansionTileIsExpanded(root),
          isFalse,
          reason:
              'A chevron parked at the canonical collapsed endpoint (0.0) '
              'must read as not expanded so the outer helper still taps it.',
        );
      },
    );

    testWidgets(
      'returns false on a mid-animation value below the threshold (turns == 0.25)',
      (WidgetTester tester) async {
        final root = await _pumpAndResolveRoot(
          tester,
          RotationTransition(
            turns: const AlwaysStoppedAnimation<double>(0.25),
            child: const Icon(Icons.expand_more),
          ),
        );
        expect(
          e2eExpansionTileIsExpanded(root),
          isFalse,
          reason:
              'A mid-flight chevron rotation (between collapsed 0.0 and the '
              'threshold 0.4) must not be accepted as expanded — the polling '
              'loop must wait until the animation has crossed the threshold '
              'so the tile children are actually laid out before further '
              'interaction.',
        );
      },
    );
  });

  group('e2eExpansionTileIsExpanded subtree traversal', () {
    testWidgets(
      'returns true when at least one nested RotationTransition is past the '
      'threshold',
      (WidgetTester tester) async {
        final root = await _pumpAndResolveRoot(
          tester,
          Column(
            children: const [
              RotationTransition(
                turns: AlwaysStoppedAnimation<double>(0.0),
                child: Icon(Icons.chevron_left),
              ),
              RotationTransition(
                turns: AlwaysStoppedAnimation<double>(0.5),
                child: Icon(Icons.expand_more),
              ),
            ],
          ),
        );
        expect(
          e2eExpansionTileIsExpanded(root),
          isTrue,
          reason:
              'When the subtree contains multiple RotationTransitions, any '
              'one past the threshold must flip the result — the helper is '
              'an existential check, not a universal one.',
        );
      },
    );

    testWidgets(
      'returns false when every nested RotationTransition is below the threshold',
      (WidgetTester tester) async {
        final root = await _pumpAndResolveRoot(
          tester,
          Column(
            children: const [
              RotationTransition(
                turns: AlwaysStoppedAnimation<double>(0.0),
                child: Icon(Icons.chevron_left),
              ),
              RotationTransition(
                turns: AlwaysStoppedAnimation<double>(0.4),
                child: Icon(Icons.expand_more),
              ),
              RotationTransition(
                turns: AlwaysStoppedAnimation<double>(0.1),
                child: Icon(Icons.refresh),
              ),
            ],
          ),
        );
        expect(
          e2eExpansionTileIsExpanded(root),
          isFalse,
          reason:
              'With every RotationTransition at or below the threshold the '
              'helper must report not expanded; a regression that returned '
              'true here would let the outer loop accept tiles whose chevron '
              'has not yet crossed the expand midpoint.',
        );
      },
    );

    testWidgets(
      'reads `RotationTransition` descendants beneath unrelated wrappers',
      (WidgetTester tester) async {
        final root = await _pumpAndResolveRoot(
          tester,
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: 120,
              height: 120,
              child: Opacity(
                opacity: 1,
                child: RotationTransition(
                  turns: const AlwaysStoppedAnimation<double>(0.5),
                  child: const Icon(Icons.expand_more),
                ),
              ),
            ),
          ),
        );
        expect(
          e2eExpansionTileIsExpanded(root),
          isTrue,
          reason:
              'The depth-first subtree walk must reach a RotationTransition '
              'no matter how many non-transition wrappers (Padding, SizedBox, '
              'Opacity, …) sit between the input element and the chevron.',
        );
      },
    );
  });
}
