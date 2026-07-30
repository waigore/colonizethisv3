part of '../e2e_tap_region_tab_test.dart';

void registerTapRegionTabOwGroup() {
  group('e2eTapOldWorldRegionTab', () {
    testWidgets(
      'no-op when no CtChoiceChip with the Old World label is mounted',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(tester, const SizedBox());
        await e2eTapOldWorldRegionTab(tester, l10n);
        // No chip → no tap fires; helper returns cleanly. Required so the
        // _tryNavalMoveSegment OW path can compose unconditionally without
        // paying a fail() on screens that have not mounted the OW tab.
      },
    );

    testWidgets(
      'no-op when matching chip exists but is not hit-testable',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(
          tester,
          IgnorePointer(
            child: CtChoiceChip(
              label: Text(l10n.region_oldWorld),
              selected: false,
              onSelected: (_) {},
            ),
          ),
        );
        await e2eTapOldWorldRegionTab(tester, l10n);
        // Helper must rely on the `.hitTestable()` filter — otherwise a
        // chip behind IgnorePointer (during a bottom-sheet route push, for
        // example) would absorb a no-op tap and trip warnIfMissed on CI.
      },
    );

    testWidgets(
      'taps the matching chip and short-circuits once selection flips',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(
          tester,
          _OldWorldRegionTabHost(label: l10n.region_oldWorld),
        );
        final hostState = tester.state<_OldWorldRegionTabHostState>(
          find.byType(_OldWorldRegionTabHost),
        );
        expect(hostState.selected, isFalse);
        expect(hostState.taps, 0);

        final sw = Stopwatch()..start();
        await e2eTapOldWorldRegionTab(tester, l10n);
        sw.stop();

        expect(
          hostState.taps,
          1,
          reason:
              'Helper must tap the matching chip exactly once; a missed tap '
              'would stall the OW region-tab settle on the fleet-reach OW '
              'split path.',
        );
        expect(
          hostState.selected,
          isTrue,
          reason:
              'After the tap, the OW chip is selected; the adaptive settle '
              'must observe it via e2eOldWorldRegionChipAppearsSelected so '
              'the helper returns promptly.',
        );
        expect(
          e2eOldWorldRegionChipAppearsSelected(l10n),
          isTrue,
          reason:
              'Composed predicate stays in sync with the chip state so the '
              'caller can re-check without re-tapping.',
        );
        expect(
          sw.elapsed < const Duration(seconds: 2),
          isTrue,
          reason:
              'Settle must short-circuit well within the bounded 500ms cap; '
              'a regression here would inflate the 35-turn fleet-reach wall '
              'clock alongside the NW-tab variant (#2336 Bottleneck 4).',
        );
      },
    );

    testWidgets(
      'taps only the first matching chip when multiple OW labels are mounted',
      (WidgetTester tester) async {
        // The helper uses `find.widgetWithText(CtChoiceChip, ...).hitTestable().first`.
        // A regression that switched to `last` or `at(n)` could tap a stale
        // chip during a rebuild (the fleet-loop region tab briefly hosts two
        // chip instances during a tab flip).
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(
          tester,
          Column(
            children: <Widget>[
              _OldWorldRegionTabHost(label: l10n.region_oldWorld),
              _OldWorldRegionTabHost(label: l10n.region_oldWorld),
            ],
          ),
        );

        final hostStates = tester
            .stateList<_OldWorldRegionTabHostState>(
              find.byType(_OldWorldRegionTabHost),
            )
            .toList();
        expect(hostStates, hasLength(2));

        await e2eTapOldWorldRegionTab(tester, l10n);

        expect(
          hostStates[0].taps,
          1,
          reason:
              'Helper must tap the FIRST matching chip so the post-tap '
              'predicate observes a deterministic chip flip; tapping a later '
              'chip would tie ordering to render order on Linux CI.',
        );
        expect(
          hostStates[1].taps,
          0,
          reason:
              'Only the first matching chip must receive the tap; tapping '
              'multiple chips would leak side effects into adjacent panels.',
        );
      },
    );

    testWidgets(
      'returns without throwing when the chip never flips selected',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(
          tester,
          CtChoiceChip(
            label: Text(l10n.region_oldWorld),
            selected: false,
            onSelected: (_) {},
          ),
        );

        Object? caught;
        try {
          await e2eTapOldWorldRegionTab(tester, l10n);
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
          e2eOldWorldRegionChipAppearsSelected(l10n),
          isFalse,
          reason:
              'Sanity: stubbed onSelected keeps the chip unselected so the '
              'timeout branch is exercised end-to-end.',
        );
      },
    );

    testWidgets(
      'short-circuits without tapping when the chip is already selected',
      (WidgetTester tester) async {
        // Pre-selected OW chip mirrors the steady state of fleet-reach OW
        // segments: the OW tab is the default map state, so the OW branch
        // of [e2eTryNavalMoveSegment] (called per fleet-reach iteration)
        // would otherwise re-tap the already-selected chip every time and
        // pay a redundant 500ms-bounded settle for no semantic effect.
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(
          tester,
          _OldWorldRegionTabHost(
            label: l10n.region_oldWorld,
            initialSelected: true,
          ),
        );
        final hostState = tester.state<_OldWorldRegionTabHostState>(
          find.byType(_OldWorldRegionTabHost),
        );
        expect(hostState.selected, isTrue);
        expect(hostState.taps, 0);
        expect(
          e2eOldWorldRegionChipAppearsSelected(l10n),
          isTrue,
          reason:
              'Sanity: the pre-selected OW host must surface as selected to '
              'the helper`s short-circuit predicate before the call.',
        );

        final sw = Stopwatch()..start();
        await e2eTapOldWorldRegionTab(tester, l10n);
        sw.stop();

        expect(
          hostState.taps,
          0,
          reason:
              'Already-selected OW short-circuit must skip the tap; a '
              'regression that re-tapped would either thrash the chip to '
              'unselected or burn a frame + post-tap settle on every OW '
              'segment iteration (#2336 Bottleneck 4 / AC5).',
        );
        expect(
          hostState.selected,
          isTrue,
          reason:
              'Chip remains selected because no tap fires; guards against a '
              'regression that calls onSelected unconditionally.',
        );
        expect(
          sw.elapsed < const Duration(milliseconds: 200),
          isTrue,
          reason:
              'Already-selected short-circuit must return well before the '
              '500ms settle cap; a regression that fell through to the tap '
              '+ settle path would directly inflate fleet-reach OW wall '
              'clock.',
        );
      },
    );

    testWidgets(
      'short-circuits even when the matching chip is non-hit-testable but '
      'already appears selected',
      (WidgetTester tester) async {
        // Mirrors the NW counterpart: a non-hit-testable but visually
        // selected OW chip (e.g. behind an IgnorePointer during a sheet
        // push) must short-circuit via the already-selected branch before
        // the helper even queries hit-testability. No tap fires, no
        // exception leaks.
        final l10n = lookupAppLocalizations(const Locale('en'));
        await _pumpScaffold(
          tester,
          IgnorePointer(
            child: CtChoiceChip(
              label: Text(l10n.region_oldWorld),
              selected: true,
              onSelected: (_) {},
            ),
          ),
        );
        expect(
          e2eOldWorldRegionChipAppearsSelected(l10n),
          isTrue,
          reason:
              'Sanity: IgnorePointer does not strip the chip`s `selected` '
              'flag from the OW predicate.',
        );

        Object? caught;
        try {
          await e2eTapOldWorldRegionTab(tester, l10n);
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNull,
          reason:
              'Already-selected + non-hit-testable OW chip must remain a '
              'silent no-op so callers can compose the helper '
              'unconditionally without paying an exception or a tap.',
        );
      },
    );
  });
}
