library;

import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'tap_region_tab_harness.dart';

void registerTapRegionTabOwIgnorePointerGroup() {
  group('e2eTapOldWorldRegionTab ignore-pointer selected', () {
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
        await pumpScaffold(
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
