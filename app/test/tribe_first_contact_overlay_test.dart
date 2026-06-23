import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/features/game/dialogue/tribe_first_contact_overlay.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

// Mirrors the production `{$var}` interpolation syntax (issue #3463) so the
// widget test fails if Dart binds Yarn variables without the `$` prefix.
const _kTestYarn = '''
title: tribe_first_contact
---
Scouts return from the New World with word of a people hitherto unknown to thy crown. They name themselves {\$tribeName}, and hold their seat at {\$capitalName}.
-> Continue
===
''';

class _StringAssetBundle extends Fake implements AssetBundle {
  _StringAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final text = _assets[key];
    if (text == null) throw Exception('missing asset: $key');
    return text;
  }
}

class _ThrowingAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    throw Exception('missing asset');
  }
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TribeFirstContactOverlay — OVL80001', () {
    testWidgets(
      'AC-4: blocking herald names tribe and capital in dialogue shell',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TribeFirstContactOverlay(
              tribeName: 'Maya',
              capitalName: 'Chichen',
              assetBundle: _StringAssetBundle({
                kDialogueTribeFirstContactAsset: _kTestYarn,
              }),
              onDismissed: () {},
              child: const Text('underlay'),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.text('First Contact'), findsOneWidget);
        expect(find.textContaining('Scouts'), findsOneWidget);
        expect(find.textContaining('Maya'), findsOneWidget);
        expect(find.textContaining('Chichen'), findsOneWidget);
        expect(find.byType(CtNinePatchButton), findsOneWidget);
      },
    );

    testWidgets(
      'AC-10: single combined step — narrative + one Continue, one tap '
      'dismisses the herald (#3628)',
      (tester) async {
        var dismissed = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: TribeFirstContactOverlay(
              tribeName: 'Maya',
              capitalName: 'Chichen',
              assetBundle: _StringAssetBundle({
                kDialogueTribeFirstContactAsset: _kTestYarn,
              }),
              onDismissed: () => dismissed++,
              child: const Text('underlay'),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Combined step: the scout narrative (with interpolated names) renders
        // together with a single Continue button — no separate line step and
        // no option-only step. The herald message appears exactly once.
        expect(find.textContaining('Scouts'), findsOneWidget);
        expect(find.textContaining('Maya'), findsOneWidget);
        expect(find.textContaining('Chichen'), findsOneWidget);
        expect(find.byType(CtNinePatchButton), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);

        // One tap advances the line, selects the sole option, and dismisses.
        await tester.tap(find.byType(CtNinePatchButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(dismissed, 1);
        expect(find.byType(CtDialogShell), findsNothing);
        expect(find.text('underlay'), findsOneWidget);
      },
    );

    testWidgets('error path invokes onDismissed via Continue', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: TribeFirstContactOverlay(
            tribeName: 'Maya',
            capitalName: 'Chichen',
            assetBundle: _ThrowingAssetBundle(),
            onDismissed: () => dismissed = true,
            child: const Text('underlay'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // AC-6 diagnostics: the load-error copy is overlay-specific (OVL80001),
      // not the reused "intro dialogue" string from OVL10001 (#3463).
      expect(find.textContaining('first-contact dialogue'), findsOneWidget);
      expect(find.textContaining('intro dialogue'), findsNothing);

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(dismissed, isTrue);
    });
  });
}
