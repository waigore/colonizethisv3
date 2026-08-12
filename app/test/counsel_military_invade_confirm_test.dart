// Military Counsel invade declare-war confirmation dialog (Refs #4307).

import 'package:colonizethis_app/features/game/screens/counsel/counsel_military_invade_confirm.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  Widget hostApp({
    required GlobalKey<NavigatorState> navigatorKey,
    required Future<void> Function(BuildContext) onOpen,
  }) {
    return buildAppShell(
      navigatorKey: navigatorKey,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      child: Scaffold(
        body: Builder(
          builder: (BuildContext context) => Center(
            child: ElevatedButton(
              key: const Key('open-dialog'),
              onPressed: () => onOpen(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showDialogUnderTest(WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      hostApp(
        navigatorKey: navigatorKey,
        onOpen: (context) => showMilitaryCounselDeclareWarConfirmDialog(
          context,
          lookupAppLocalizations(const Locale('en')),
          'Rival Empire',
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
  }

  testWidgets('shows declare-war title and owner label (Refs #4307)', (
    WidgetTester tester,
  ) async {
    await showDialogUnderTest(tester);

    expect(find.text('Declare war?'), findsOneWidget);
    expect(find.textContaining('Rival Empire'), findsOneWidget);
    expect(find.byType(CtNinePatchButton), findsNWidgets(2));
  });

  testWidgets('Cancel returns false without staging orders (Refs #4307)', (
    WidgetTester tester,
  ) async {
    bool? result;
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      hostApp(
        navigatorKey: navigatorKey,
        onOpen: (context) async {
          result = await showMilitaryCounselDeclareWarConfirmDialog(
            context,
            lookupAppLocalizations(const Locale('en')),
            'Rival Empire',
          );
        },
      ),
    );
    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('Declare war and move returns true (Refs #4307)', (
    WidgetTester tester,
  ) async {
    bool? result;
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      hostApp(
        navigatorKey: navigatorKey,
        onOpen: (context) async {
          result = await showMilitaryCounselDeclareWarConfirmDialog(
            context,
            lookupAppLocalizations(const Locale('en')),
            'Rival Empire',
          );
        },
      ),
    );
    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Declare war and move'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
