library;

import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'dismiss_widget_tester_harness.dart';

void registerE2eDismissCtDialogShellIfPresentPerfGroup() {
  group('e2eDismissCtDialogShellIfPresent — perf wiring', () {
    testWidgets(
      'forwards the default phase label through e2ePumpUntil so wall-clock '
      'attribution sees the legacy phase step',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        final perf = E2ePerfLog('dismiss_shell_phase');
        await tester.pumpWidget(
          wrapDismissCentered(
            DismissCtDialogShellHost(
              builder: (context, close) =>
                  TextButton(onPressed: close, child: Text(l10n.common_cancel)),
            ),
          ),
        );

        final lines = <String>[];
        final original = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          lines.add(message ?? '');
        };
        try {
          await e2eDismissCtDialogShellIfPresent(tester, l10n, perf: perf);
        } finally {
          debugPrint = original;
        }

        expect(
          lines.any(
            (l) =>
                l.startsWith('E2E_TIMING') &&
                l.contains('phase=$kE2eDefaultCtDialogShellClosePhase'),
          ),
          isTrue,
          reason:
              'Default phase label must equal '
              'kE2eDefaultCtDialogShellClosePhase so existing log scrapers '
              'continue to attribute the wait under the legacy step name.',
        );
      },
    );
  });
}
