// Smoke tests for the shared generic app-shell pump harness (Refs #3730).
//
// These pin the contract the migrated `_pump*` widget tests rely on:
//
//  * the editorial-monocle theme drives the shell;
//  * provider overrides are threaded into the wrapping `ProviderScope`;
//  * a non-null `viewport` forces the binding surface size (and a tear-down
//    restores it) and is observable via `MediaQuery.sizeOf`;
//  * a null `viewport` leaves the ambient surface size untouched (no forced
//    `MediaQuery`);
//  * `settle: true` drains pending animations;
//  * `pumpAppShellWithContainer` binds an externally-owned `ProviderContainer`
//    (via `UncontrolledProviderScope`) so the same container reads back state
//    the UI mutated, under the same theme + forced-viewport contract;
//  * `onGenerateRoute` is forwarded so route-host tests can `pushNamed` named
//    routes off the shared shell while `child` stays the `'/'` home;
//  * `shellWrapper` composes an app-level wrapper outside the `MaterialApp`
//    (the seam used to keep `AppEventHandlerScope` above routing), and is
//    absent from the tree when not supplied.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

const Size _kViewport = Size(800, 900);

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
      viewport: _kViewport,
      child: LayoutBuilder(
        builder: (context, constraints) {
          observedSize = MediaQuery.sizeOf(context);
          maxWidth = constraints.maxWidth;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(observedSize, _kViewport);
    expect(maxWidth, _kViewport.width);
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

    // The default test surface is 800x600; the harness does not override it.
    expect(observedSize, const Size(800, 600));
  });

  testWidgets('pumpAppShell with settle drains pending animations', (
    WidgetTester tester,
  ) async {
    await pumpAppShell(
      tester,
      settle: true,
      child: const _BrieflyAnimating(),
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
      // The same container the caller owns reads back the bound value.
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
        viewport: _kViewport,
        child: LayoutBuilder(
          builder: (context, constraints) {
            observedSize = MediaQuery.sizeOf(context);
            maxWidth = constraints.maxWidth;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(observedSize, _kViewport);
      expect(maxWidth, _kViewport.width);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'buildAppShell forwards onGenerateRoute so named routes resolve off the '
    'shared shell',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShell(
          onGenerateRoute: (settings) {
            if (settings.name == '/details') {
              return MaterialPageRoute<void>(
                builder: (_) => const Text('details-route'),
              );
            }
            return null;
          },
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/details'),
                    child: const Text('go'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The `'/'` home (child) renders first; the named route is not yet shown.
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
          shellWrapper: (app) => _ShellMarker(child: app),
          child: const SizedBox.shrink(),
        ),
      );

      // The wrapper sits above the MaterialApp (outside routing), as an
      // app-level scope such as AppEventHandlerScope would.
      expect(
        find.ancestor(
          of: find.byType(MaterialApp),
          matching: find.byType(_ShellMarker),
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

      expect(find.byType(_ShellMarker), findsNothing);
      expect(find.byType(MaterialApp), findsOneWidget);
    },
  );
}

/// Inert wrapper used to assert `shellWrapper` composes above the MaterialApp.
class _ShellMarker extends StatelessWidget {
  const _ShellMarker({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _BrieflyAnimating extends StatefulWidget {
  const _BrieflyAnimating();

  @override
  State<_BrieflyAnimating> createState() => _BrieflyAnimatingState();
}

class _BrieflyAnimatingState extends State<_BrieflyAnimating> {
  String _label = 'pending';

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => _label = 'done');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(_label),
    );
  }
}
