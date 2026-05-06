// Turn-resolution bus guards (#2160). SPEC/program/app-event-bus.md.

import 'package:colonizethis_app/core/services/app_event_handler.dart';
import 'package:colonizethis_app/features/game/widgets/pause_menu_panel.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/providers/turn_resolution_blocking_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ForcedTurnResolutionBlocking extends TurnResolutionBlockingNotifier {
  @override
  bool build() => true;
}

void main() {
  suppressLogsForTests();

  group('Turn resolution AppEventHandler guards', () {
    late AppEventBus bus;
    late GlobalKey<NavigatorState> navKey;
    late AppEventHandler handler;

    setUp(() {
      AppEventBus.reset();
      bus = AppEventBus.create();
      navKey = GlobalKey<NavigatorState>();
      handler = AppEventHandler(bus: bus, navigatorKey: navKey);
    });

    tearDown(() {
      handler.unbind();
      AppEventBus.reset();
    });

    testWidgets(
      'given turnResolutionBlockingProvider is active, NavigateToRouteEvent does not navigate',
      (tester) async {
        handler.bind();
        final pushed = <RouteSettings?>[];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              turnResolutionBlockingProvider.overrideWith(
                _ForcedTurnResolutionBlocking.new,
              ),
            ],
            child: MaterialApp(
              navigatorKey: navKey,
              localizationsDelegates:
                  AppLocalizationsBinding.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              onGenerateRoute: (settings) {
                pushed.add(settings);
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const Text('target'),
                );
              },
              home: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () =>
                      bus.emit(const NavigateToRouteEvent('/target', {'x': 1})),
                  child: const Text('navigate'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('navigate'));
        await tester.pumpAndSettle();

        expect(pushed, isEmpty);
      },
    );

    testWidgets(
      'given turnResolutionBlockingProvider is active, OpenPauseMenuPanelEvent still opens pause UI',
      (tester) async {
        handler.bind();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              turnResolutionBlockingProvider.overrideWith(
                _ForcedTurnResolutionBlocking.new,
              ),
            ],
            child: MaterialApp(
              navigatorKey: navKey,
              localizationsDelegates:
                  AppLocalizationsBinding.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: SizedBox.shrink()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        bus.emit(const OpenPauseMenuPanelEvent());
        await tester.pumpAndSettle();

        expect(find.byType(PauseMenuPanel), findsOneWidget);
      },
    );

    testWidgets('given turnResolutionBlockingProvider is active, '
        'OpenCivilianUnitsPanelEvent does not push a modal route', (
      tester,
    ) async {
      handler.bind();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            turnResolutionBlockingProvider.overrideWith(
              _ForcedTurnResolutionBlocking.new,
            ),
          ],
          child: MaterialApp(
            navigatorKey: navKey,
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => bus.emit(const OpenCivilianUnitsPanelEvent()),
                child: const Text('open_civilian'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navCtx = tester.element(find.text('open_civilian'));
      expect(Navigator.of(navCtx).canPop(), isFalse);

      await tester.tap(find.text('open_civilian'));
      await tester.pumpAndSettle();

      expect(Navigator.of(navCtx).canPop(), isFalse);
    });
  });
}
