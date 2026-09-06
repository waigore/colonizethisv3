// Smoke tests for the shared generic app-shell pump harness (Refs #3730).
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'app_shell_harness_test_widgets.dart';

final Provider<String> _labelProvider = Provider<String>((ref) => 'default');

void main() {
  suppressLogsForTests();

  testWidgets('pumpAppShell drives the editorial-monocle theme', (
    WidgetTester tester,
  ) async {
    late ThemeData observedTheme;
    await pumpAppShell(
      tester,
      child: Builder(
        builder: (context) {
          observedTheme = Theme.of(context);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(observedTheme.colorScheme, AppThemes.editorialMonocle.colorScheme);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pumpAppShell threads provider overrides into the scope', (
    WidgetTester tester,
  ) async {
    late String observedLabel;
    await pumpAppShell(
      tester,
      overrides: [_labelProvider.overrideWithValue('overridden')],
      child: Consumer(
        builder: (context, ref, _) {
          observedLabel = ref.watch(_labelProvider);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(observedLabel, 'overridden');
  });

  testWidgets('pumpAppShell forces the surface size when viewport is set', (
    WidgetTester tester,
  ) async {
    late Size observedSize;
    late double maxWidth;
    await pumpAppShell(
      tester,
      viewport: kAppShellHarnessTestViewport,
      child: LayoutBuilder(
        builder: (context, constraints) {
          observedSize = MediaQuery.sizeOf(context);
          maxWidth = constraints.maxWidth;
          return const SizedBox.shrink();
        },
      ),
    );
    expect(observedSize, kAppShellHarnessTestViewport);
    expect(maxWidth, kAppShellHarnessTestViewport.width);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pumpAppShell leaves the ambient size when viewport is null', (
    WidgetTester tester,
  ) async {
    late Size observedSize;
    await pumpAppShell(
      tester,
      child: Builder(
        builder: (context) {
          observedSize = MediaQuery.sizeOf(context);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(observedSize, const Size(800, 600));
  });

  testWidgets('pumpAppShell with settle drains pending animations', (
    WidgetTester tester,
  ) async {
    await pumpAppShell(
      tester,
      settle: true,
      child: const AppShellHarnessTestBrieflyAnimating(),
    );
    expect(find.text('done'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pumpAppShellWithContainer binds the caller-owned container under the '
    'editorial-monocle theme',
    (WidgetTester tester) async {
      final ProviderContainer container = ProviderContainer(
        overrides: [_labelProvider.overrideWithValue('from-container')],
      );
      addTearDown(container.dispose);
      late ThemeData observedTheme;
      late String observedLabel;
      await pumpAppShellWithContainer(
        tester,
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            observedTheme = Theme.of(context);
            observedLabel = ref.watch(_labelProvider);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(observedLabel, 'from-container');
      expect(container.read(_labelProvider), 'from-container');
      expect(
        observedTheme.colorScheme,
        AppThemes.editorialMonocle.colorScheme,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pumpAppShellWithContainer forces the surface size when viewport is set',
    (WidgetTester tester) async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      late Size observedSize;
      late double maxWidth;
      await pumpAppShellWithContainer(
        tester,
        container: container,
        viewport: kAppShellHarnessTestViewport,
        child: LayoutBuilder(
          builder: (context, constraints) {
            observedSize = MediaQuery.sizeOf(context);
            maxWidth = constraints.maxWidth;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(observedSize, kAppShellHarnessTestViewport);
      expect(maxWidth, kAppShellHarnessTestViewport.width);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'buildAppShell forwards onGenerateRoute so named routes resolve off the '
    'shared shell',
    (WidgetTester tester) async {
      await pumpAppShellNamedRouteHarness(tester);
      expect(find.text('go'), findsOneWidget);
      expect(find.text('details-route'), findsNothing);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('details-route'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'buildAppShell wraps the MaterialApp with shellWrapper when supplied',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShell(
          shellWrapper: (app) => AppShellHarnessTestShellMarker(child: app),
          child: const SizedBox.shrink(),
        ),
      );
      expect(
        find.ancestor(
          of: find.byType(MaterialApp),
          matching: find.byType(AppShellHarnessTestShellMarker),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'buildAppShell omits any wrapper when shellWrapper is null',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShell(child: const SizedBox.shrink()),
      );
      expect(find.byType(AppShellHarnessTestShellMarker), findsNothing);
      expect(find.byType(MaterialApp), findsOneWidget);
    },
  );

  testWidgets('buildAppShell named routes + MaterialApp chrome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildAppShell(
        child: const SizedBox.shrink(),
        initialRoute: '/game',
        routes: <String, WidgetBuilder>{
          '/game': (_) => const Text('game-route'),
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('game-route'), findsOneWidget);
    await tester.pumpWidget(
      buildAppShellMaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Text('shell-material'),
      ),
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp))
          .debugShowCheckedModeBanner,
      isFalse,
    );
  });
}
