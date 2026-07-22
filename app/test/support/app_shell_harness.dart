// Shared app-shell pump harness for `app/test/**` widget/screen tests.
// Generic counterpart to `min_viewport_harness.dart` (Refs #3730, #4035).
// SPEC: SPEC/program/repo-lint.md.

import 'package:colonizethis_app/config/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Canonical [ProviderScope] + themed [MaterialApp] host (Refs #4035).
/// Defaults to [AppThemes.editorialMonocle]. [viewport] forces MediaQuery size
/// (binding surface still via [pumpAppShell]). [initialRoute] skips `home`.
/// [shellWrapper] wraps the [MaterialApp] under the scope.
Widget buildAppShell({
  required Widget child,
  Size? viewport,
  List<Override> overrides = const <Override>[],
  ThemeData? theme,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const <Locale>[Locale('en', 'US')],
  Locale? locale,
  GlobalKey<NavigatorState>? navigatorKey,
  RouteFactory? onGenerateRoute,
  Map<String, WidgetBuilder>? routes,
  String? initialRoute,
  bool debugShowCheckedModeBanner = true,
  Widget Function(Widget app)? shellWrapper,
}) {
  final MaterialApp app = buildAppShellMaterialApp(
    home: initialRoute == null ? _wrapViewport(child, viewport) : null,
    theme: theme,
    localizationsDelegates: localizationsDelegates,
    supportedLocales: supportedLocales,
    locale: locale,
    navigatorKey: navigatorKey,
    onGenerateRoute: onGenerateRoute,
    routes: routes,
    initialRoute: initialRoute,
    debugShowCheckedModeBanner: debugShowCheckedModeBanner,
  );
  return ProviderScope(
    overrides: overrides,
    child: shellWrapper == null ? app : shellWrapper(app),
  );
}

/// Like [buildAppShell] but binds an externally-owned [container] via
/// [UncontrolledProviderScope] so callers can read the same container after
/// pumping. MaterialApp chrome stays [buildAppShellMaterialApp].
Widget buildAppShellWithContainer({
  required ProviderContainer container,
  required Widget child,
  Size? viewport,
  ThemeData? theme,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const <Locale>[Locale('en', 'US')],
  Locale? locale,
  GlobalKey<NavigatorState>? navigatorKey,
  RouteFactory? onGenerateRoute,
  Map<String, WidgetBuilder>? routes,
  String? initialRoute,
  bool debugShowCheckedModeBanner = true,
  Widget Function(Widget app)? shellWrapper,
}) {
  final MaterialApp app = buildAppShellMaterialApp(
    home: initialRoute == null ? _wrapViewport(child, viewport) : null,
    theme: theme,
    localizationsDelegates: localizationsDelegates,
    supportedLocales: supportedLocales,
    locale: locale,
    navigatorKey: navigatorKey,
    onGenerateRoute: onGenerateRoute,
    routes: routes,
    initialRoute: initialRoute,
    debugShowCheckedModeBanner: debugShowCheckedModeBanner,
  );
  return UncontrolledProviderScope(
    container: container,
    child: shellWrapper == null ? app : shellWrapper(app),
  );
}

/// Single MaterialApp chrome for shell/golden hosts; optional bare theme (#4035).
MaterialApp buildAppShellMaterialApp({
  Widget? home,
  ThemeData? theme,
  bool applyEditorialTheme = true,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const <Locale>[Locale('en', 'US')],
  Locale? locale,
  GlobalKey<NavigatorState>? navigatorKey,
  RouteFactory? onGenerateRoute,
  Map<String, WidgetBuilder>? routes,
  String? initialRoute,
  bool debugShowCheckedModeBanner = true,
}) {
  return MaterialApp(
    navigatorKey: navigatorKey,
    debugShowCheckedModeBanner: debugShowCheckedModeBanner,
    theme: theme ?? (applyEditorialTheme ? AppThemes.editorialMonocle : null),
    localizationsDelegates: localizationsDelegates,
    supportedLocales: supportedLocales,
    locale: locale,
    onGenerateRoute: onGenerateRoute,
    routes: routes ?? const <String, WidgetBuilder>{},
    initialRoute: initialRoute,
    home: home,
  );
}

Widget _wrapViewport(Widget child, Size? viewport) {
  return viewport == null
      ? child
      : MediaQuery(
          data: MediaQueryData(size: viewport),
          child: child,
        );
}

/// Editorial-monocle [Scaffold] host for panel widget tests (Refs #4117).
Widget buildPanelScaffoldShell(
  Widget panel, {
  Size? viewport,
  List<Override> overrides = const <Override>[],
}) {
  return buildAppShell(
    viewport: viewport,
    overrides: overrides,
    child: Scaffold(body: panel),
  );
}

/// Forces a fixed binding surface for tall/wide panel layout pins.
Future<void> bindFixedTestSurface(WidgetTester tester, Size size) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
}

/// Pumps a prebuilt widget tree; settles by default (panel pump canonical).
Future<void> pumpSettledWidget(
  WidgetTester tester,
  Widget widget, {
  bool settle = true,
}) async {
  await tester.pumpWidget(widget);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Pumps [child] inside [buildAppShell].
///
/// When [viewport] is non-null, registers a tear-down that restores the
/// surface size and forces the binding surface to [viewport] before pumping.
/// Single frame by default; [settle] drains animations.
Future<void> pumpAppShell(
  WidgetTester tester, {
  required Widget child,
  Size? viewport,
  List<Override> overrides = const <Override>[],
  ThemeData? theme,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const <Locale>[Locale('en', 'US')],
  Locale? locale,
  GlobalKey<NavigatorState>? navigatorKey,
  RouteFactory? onGenerateRoute,
  Widget Function(Widget app)? shellWrapper,
  bool settle = false,
}) async {
  if (viewport != null) {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(viewport);
  }
  await tester.pumpWidget(
    buildAppShell(
      child: child,
      viewport: viewport,
      overrides: overrides,
      theme: theme,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: locale,
      navigatorKey: navigatorKey,
      onGenerateRoute: onGenerateRoute,
      shellWrapper: shellWrapper,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Pumps [child] inside [buildAppShellWithContainer] (caller owns [container]).
Future<void> pumpAppShellWithContainer(
  WidgetTester tester, {
  required ProviderContainer container,
  required Widget child,
  Size? viewport,
  ThemeData? theme,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const <Locale>[Locale('en', 'US')],
  Locale? locale,
  GlobalKey<NavigatorState>? navigatorKey,
  RouteFactory? onGenerateRoute,
  Widget Function(Widget app)? shellWrapper,
  bool settle = false,
}) async {
  if (viewport != null) {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(viewport);
  }
  await tester.pumpWidget(
    buildAppShellWithContainer(
      container: container,
      child: child,
      viewport: viewport,
      theme: theme,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: locale,
      navigatorKey: navigatorKey,
      onGenerateRoute: onGenerateRoute,
      shellWrapper: shellWrapper,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
