part of '../e2e_tap_region_tab_test.dart';

void registerTapRegionTabNwGroup() {
  group('e2eTapNewWorldRegionTabIfPresent', () {
    testWidgets(
      'no-op when the keyed New World subtree is absent (no exception)',
      (WidgetTester tester) async {
        await _pumpScaffold(tester, const SizedBox());
        await e2eTapNewWorldRegionTabIfPresent(tester);
        // Helper must keep the silent-absent contract so scenarios where the
        // map controls have not mounted yet (e.g. capital-panel paths) can
        // compose it unconditionally without paying a failure or pump cost.
      },
    );

    testWidgets(
      'no-op when the keyed subtree exists but is not hit-testable',
      (WidgetTester tester) async {
        // `IgnorePointer` makes the keyed subtree non-hit-testable while
        // keeping `find.byKey(...)` non-empty — the helper must rely on the
        // `.hitTestable()` filter, not raw presence.
        await _pumpScaffold(
          tester,
          const IgnorePointer(
            child: KeyedSubtree(
              key: kCtE2ERegionTabNewWorldKey,
              child: SizedBox(width: 40, height: 24),
            ),
          ),
        );
        await e2eTapNewWorldRegionTabIfPresent(tester);
        // No tap fires; helper returns cleanly. A regression that dropped
        // `.hitTestable()` would attempt to tap a non-hit-testable target and
        // surface a flaky `warnIfMissed` log on Linux CI.
      },
    );

    testWidgets(
      'taps the keyed subtree and short-circuits once the chip flips selected',
      (WidgetTester tester) async {
        await _pumpScaffold(tester, const _NewWorldRegionTabHost());
        final hostState = tester.state<_NewWorldRegionTabHostState>(
          find.byType(_NewWorldRegionTabHost),
        );
        expect(hostState.selected, isFalse);
        expect(hostState.taps, 0);

        final sw = Stopwatch()..start();
        await e2eTapNewWorldRegionTabIfPresent(tester);
        sw.stop();

        expect(
          hostState.taps,
          1,
          reason:
              'Helper must tap exactly once when the keyed subtree is '
              'hit-testable; a missed tap or double-tap would either stall the '
              'region-tab settle or thrash the chip back to its original state.',
        );
        expect(
          hostState.selected,
          isTrue,
          reason:
              'After the tap, the chip is selected and the adaptive post-tap '
              'settle must observe the flip via '
              'e2eNewWorldRegionChipAppearsSelected so the helper returns.',
        );
        expect(
          e2eNewWorldRegionChipAppearsSelected(),
          isTrue,
          reason:
              'The composed predicate must remain in sync with the chip state '
              'so downstream callers (fleet-reach turn loop) can re-check it '
              'without re-tapping.',
        );
        expect(
          sw.elapsed < const Duration(seconds: 2),
          isTrue,
          reason:
              'Helper must settle well within the bounded 500ms post-tap cap; '
              'a regression that ballooned the cap (or never short-circuited) '
              'would directly inflate the 35-turn fleet-reach wall clock '
              '(#2336 Bottleneck 4).',
        );
      },
    );

    testWidgets(
      'returns without throwing when the chip never flips selected',
      (WidgetTester tester) async {
        // CtChoiceChip + InkWell will record taps, but our host swaps
        // `onSelected` for a no-op so selection never flips — the helper
        // must hit the timeout without throwing (best-effort settle).
        await _pumpScaffold(
          tester,
          KeyedSubtree(
            key: kCtE2ERegionTabNewWorldKey,
            child: CtChoiceChip(
              label: const Text('New World'),
              selected: false,
              onSelected: (_) {},
            ),
          ),
        );

        Object? caught;
        try {
          await e2eTapNewWorldRegionTabIfPresent(tester);
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNull,
          reason:
              'Helper composes the best-effort '
              'e2ePumpUntilConditionOrIdle and MUST NOT throw on timeout — '
              'callers treat the wait as an optional post-tap settle '
              '(#2336 AC5).',
        );
        expect(
          e2eNewWorldRegionChipAppearsSelected(),
          isFalse,
          reason:
              'Sanity: with onSelected stubbed to no-op the chip stays '
              'unselected, exercising the timeout branch of the helper.',
        );
      },
    );

    testWidgets(
      'short-circuits without tapping when the chip is already selected',
      (WidgetTester tester) async {
        // Pre-select the chip so the already-selected branch fires before
        // the helper even looks for a hit-testable subtree. This is the
        // fleet-reach hot-path optimization: 34 of the 35 turn-loop
        // iterations call this helper with the NW chip already selected
        // from the first tap, so re-tapping would burn one frame + a
        // bounded settle per iteration for no semantic effect.
        await _pumpScaffold(
          tester,
          const _NewWorldRegionTabHost(initialSelected: true),
        );
        final hostState = tester.state<_NewWorldRegionTabHostState>(
          find.byType(_NewWorldRegionTabHost),
        );
        expect(hostState.selected, isTrue);
        expect(hostState.taps, 0);
        expect(
          e2eNewWorldRegionChipAppearsSelected(),
          isTrue,
          reason:
              'Sanity: the pre-selected host must surface as selected to '
              'the helper`s short-circuit predicate before the call.',
        );

        final sw = Stopwatch()..start();
        await e2eTapNewWorldRegionTabIfPresent(tester);
        sw.stop();

        expect(
          hostState.taps,
          0,
          reason:
              'Already-selected short-circuit must skip the tap entirely; a '
              'regression that re-tapped the chip would either thrash it to '
              'unselected (via CtChoiceChip onSelected toggle semantics) or '
              'burn an unnecessary frame + post-tap settle on every '
              'fleet-reach turn (#2336 Bottleneck 4 / AC5).',
        );
        expect(
          hostState.selected,
          isTrue,
          reason:
              'Chip remains selected because no tap fires; sanity check '
              'against a regression that calls onSelected unconditionally.',
        );
        expect(
          sw.elapsed < const Duration(milliseconds: 200),
          isTrue,
          reason:
              'Already-selected short-circuit must return well before the '
              '500ms post-tap settle cap — ideally inside one synchronous '
              'predicate read. A regression that fell through to the tap + '
              'settle path would directly inflate fleet-reach wall clock.',
        );
      },
    );

    testWidgets(
      'short-circuits even when the keyed subtree is non-hit-testable but '
      'the chip already appears selected',
      (WidgetTester tester) async {
        // Mounts a non-hit-testable but visually-selected New World chip:
        // before the short-circuit landed, the helper would have returned
        // via the `.hitTestable().evaluate().isEmpty` no-op branch; with
        // the short-circuit it returns via the already-selected branch
        // first. Either way no tap fires, but pinning the order keeps a
        // regression from accidentally tapping a non-hit-testable but
        // mounted chip during a panel push that selects the NW tab off-
        // screen.
        await _pumpScaffold(
          tester,
          IgnorePointer(
            child: KeyedSubtree(
              key: kCtE2ERegionTabNewWorldKey,
              child: CtChoiceChip(
                label: const Text('New World'),
                selected: true,
                onSelected: (_) {},
              ),
            ),
          ),
        );
        expect(
          e2eNewWorldRegionChipAppearsSelected(),
          isTrue,
          reason:
              'Sanity: the IgnorePointer wrapper does not strip the chip`s '
              '`selected` flag from the predicate.',
        );

        Object? caught;
        try {
          await e2eTapNewWorldRegionTabIfPresent(tester);
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNull,
          reason:
              'Already-selected + non-hit-testable subtree must remain a '
              'silent no-op so callers can compose the helper '
              'unconditionally without paying an exception or a tap.',
        );
      },
    );
  });

}
