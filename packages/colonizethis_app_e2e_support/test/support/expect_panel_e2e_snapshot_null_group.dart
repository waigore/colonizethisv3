// Null-snapshot reason-key pins for per-panel E2E matchers (#4598).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';

import 'expect_panel_e2e_snapshot_fixtures.dart';
import 'expect_panel_texts_harness.dart' as panel_host;

void registerExpectPanelE2eSnapshotNullGroup() {
  group('e2eExpectCivilianPanelMatchesE2eSnapshot — null snapshot fails with '
      'civilian-panel root key in reason', () {
    testWidgets('null civilian snapshot → reason names panel root key', (
      tester,
    ) async {
      resetPanelE2eSnapshots();
      await tester.pumpWidget(
        panel_host.wrap(kCtE2ECivilianPanelRootKey, const [Text('x')]),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      try {
        await e2eExpectCivilianPanelMatchesE2eSnapshot(tester, l10n);
        fail(
          'expected the helper to throw a TestFailure when the civilian '
          'snapshot global is null',
        );
      } on TestFailure catch (e) {
        expect(
          e.message,
          isNotNull,
          reason: 'TestFailure messages must be populated for diagnosis.',
        );
        expect(
          e.message!,
          contains(kCtE2ECivilianPanelRootKey.toString()),
          reason:
              'A regression that forwarded the wrong panel-root key into '
              '`e2eExpectPanelTextsMatchSnapshot` would surface a '
              'reason: line that names a different panel; pinning the '
              'civilian root key in the failure message catches that drift '
              'without depending on the slow CI lane.',
        );
      }
    });
  });

  group('e2eExpectNavalPanelMatchesE2eSnapshot — null snapshot fails with '
      'naval-panel root key in reason', () {
    testWidgets(
      'null naval snapshot (expanded: false) → reason names panel root key',
      (tester) async {
        resetPanelE2eSnapshots();
        await tester.pumpWidget(
          panel_host.wrap(kCtE2ENavalPanelRootKey, const [Text('x')]),
        );
        final l10n = lookupAppLocalizations(const Locale('en'));
        try {
          await e2eExpectNavalPanelMatchesE2eSnapshot(
            tester,
            l10n,
            expanded: false,
          );
          fail(
            'expected the helper to throw a TestFailure when the naval '
            'snapshot global is null',
          );
        } on TestFailure catch (e) {
          expect(
            e.message!,
            contains(kCtE2ENavalPanelRootKey.toString()),
            reason:
                'Forwarded panel-root key drift must be caught by the '
                'naval-panel pin.',
          );
        }
      },
    );

    testWidgets(
      'null naval snapshot (expanded: true) → reason still names panel '
      'root key (alternative fallback never reaches builder)',
      (tester) async {
        resetPanelE2eSnapshots();
        await tester.pumpWidget(
          panel_host.wrap(kCtE2ENavalPanelRootKey, const [Text('x')]),
        );
        final l10n = lookupAppLocalizations(const Locale('en'));
        try {
          await e2eExpectNavalPanelMatchesE2eSnapshot(
            tester,
            l10n,
            expanded: true,
          );
          fail(
            'expected the helper to throw a TestFailure when the naval '
            'snapshot global is null even with the alternative-expected '
            'fallback wired',
          );
        } on TestFailure catch (e) {
          expect(
            e.message!,
            contains(kCtE2ENavalPanelRootKey.toString()),
            reason:
                'The `buildAlternativeExpected` fallback must NOT short-'
                'circuit the null-snapshot guard — the guard runs before '
                'either builder is invoked, so dereferencing `snap!` in '
                'the alternative would never be safe.',
          );
        }
      },
    );
  });

  group('e2eExpectProductionPanelMatchesE2eSnapshot — null snapshot fails with '
      'production-panel root key in reason', () {
    testWidgets('null production snapshot → reason names panel root key', (
      tester,
    ) async {
      resetPanelE2eSnapshots();
      await tester.pumpWidget(
        panel_host.wrap(kCtE2EProductionPanelRootKey, const [Text('x')]),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      try {
        await e2eExpectProductionPanelMatchesE2eSnapshot(tester, l10n);
        fail(
          'expected the helper to throw a TestFailure when the production '
          'snapshot global is null',
        );
      } on TestFailure catch (e) {
        expect(
          e.message!,
          contains(kCtE2EProductionPanelRootKey.toString()),
          reason:
              'Forwarded panel-root key drift must be caught by the '
              'production-panel pin.',
        );
      }
    });
  });

  group('e2eExpectProvincePanelMatchesE2eSnapshot — null snapshot fails with '
      'province-panel root key in reason', () {
    testWidgets('null province snapshot → reason names panel root key', (
      tester,
    ) async {
      resetPanelE2eSnapshots();
      await tester.pumpWidget(
        panel_host.wrap(kCtE2EProvincePanelRootKey, const [Text('x')]),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      try {
        await e2eExpectProvincePanelMatchesE2eSnapshot(tester, l10n);
        fail(
          'expected the helper to throw a TestFailure when the province '
          'snapshot global is null',
        );
      } on TestFailure catch (e) {
        expect(
          e.message!,
          contains(kCtE2EProvincePanelRootKey.toString()),
          reason:
              'Forwarded panel-root key drift must be caught by the '
              'province-panel pin.',
        );
      }
    });
  });
}
