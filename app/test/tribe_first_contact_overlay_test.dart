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
    testWidgets('AC-4: blocking herald names tribe and capital in dialogue shell', (
      tester,
    ) async {
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
    });

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

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(dismissed, isTrue);
    });
  });
}
