// Shared app-shell pump harness for `app/test/**` widget/screen tests.
//
// Dozens of widget tests re-declare a private `_pump<Thing>(...)` helper that
// repeats the same wrapper sequence: optionally force a surface size, then
// pump a `ProviderScope` > `MaterialApp(theme: AppThemes.editorialMonocle)`
// shell hosting a single screen/widget, then pump one frame (or settle). The
// only per-file variation is the provider override list, the hosted widget,
// the (optional) forced viewport, and the pump strategy.
//
// This is the generic counterpart to `min_viewport_harness.dart`: that file's
// `buildMinViewportApp` / `pumpAtMinViewport` are the always-forced-viewport
// specialization used by the `*_320dp_min_viewport_test.dart` family, and they
// delegate here so there is a single shell definition.
//
// Refs #3730 (consolidate app test scaffolding).
// SPEC: SPEC/program/repo-lint.md (test static-analysis scope).

import 'package:colonizethis_app/config/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Builds the canonical app shell used by widget/screen tests: a
/// [ProviderScope] (scoped by [overrides]) wrapping an editorial-monocle
/// [MaterialApp] whose [MaterialApp.home] hosts [child].
///
/// When [viewport] is non-null, [child] is wrapped in a [MediaQuery] forcing
/// that size so widget code reading `MediaQuery.sizeOf(context)` resolves to
/// it; callers must still force the binding surface size separately (see
/// [pumpAppShell], which does both). When [viewport] is null, [child] is the
/// [MaterialApp.home] directly and the ambient surface size is used.
///
/// [localizationsDelegates], [supportedLocales], and [locale] are forwarded to
/// the [MaterialApp]; their defaults match `MaterialApp`'s own so non-localized
/// callers are unaffected. Any extra structural wrappers a screen needs (a
/// [Scaffold] host, a [Stack], an event-handler scope, …) belong in [child].
Widget buildAppShell({
  required Widget child,
  Size? viewport,
  List<Override> overrides = const <Override>[],
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const <Locale>[Locale('en', 'US')],
  Locale? locale,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return ProviderScope(
    overrides: overrides,
    child: _appShellMaterialApp(
      home: _wrapViewport(child, viewport),
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: locale,
      navigatorKey: navigatorKey,
    ),
  );
}

/// Builds the canonical app shell bound to an externally-owned [container]
/// via an [UncontrolledProviderScope] (instead of an [overrides]-scoped
/// [ProviderScope]). The caller creates and disposes [container]; this is the
/// specialization used by tests that must read provider state back from the
/// **same** container after pumping — the [ProviderScope]-owning
/// [buildAppShell] does not expose its container.
///
/// Theme, viewport [MediaQuery] wrapping, localization forwarding, and the
/// hosted-[child] contract are identical to [buildAppShell]; only the scope
/// ownership differs, so there remains a single [MaterialApp]
/// (editorial-monocle) shell definition.
Widget buildAppShellWithContainer({
  required ProviderContainer container,
  required Widget child,
  Size? viewport,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const <Locale>[Locale('en', 'US')],
  Locale? locale,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: _appShellMaterialApp(
      home: _wrapViewport(child, viewport),
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: locale,
      navigatorKey: navigatorKey,
    ),
  );
}

/// The single editorial-monocle [MaterialApp] definition shared by every
/// shell builder in this harness; only the provider-scope wrapper differs
/// between the [ProviderScope] and [UncontrolledProviderScope] variants.
MaterialApp _appShellMaterialApp({
  required Widget home,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const <Locale>[Locale('en', 'US')],
  Locale? locale,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return MaterialApp(
    navigatorKey: navigatorKey,
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: localizationsDelegates,
    supportedLocales: supportedLocales,
    locale: locale,
    home: home,
  );
}

/// Wraps [child] in a forced-size [MediaQuery] when [viewport] is non-null so
/// widget code reading `MediaQuery.sizeOf(context)` resolves to it; otherwise
/// returns [child] unchanged so the ambient surface size is used.
Widget _wrapViewport(Widget child, Size? viewport) {
  return viewport == null
      ? child
      : MediaQuery(data: MediaQueryData(size: viewport), child: child);
}

/// Pumps [child] inside [buildAppShell].
///
/// When [viewport] is non-null, registers a tear-down that restores the
/// surface size and forces the binding surface to [viewport] (so the
/// framework's `RenderFlex` math sees it) before pumping. Pumps a single frame
/// by default; when [settle] is `true` the helper drives
/// [WidgetTester.pumpAndSettle] to completion instead — use it for screens
/// whose first-frame chrome must settle before an assertion runs, and keep the
/// single-pump default for screens with continuous animations that would never
/// settle.
///
/// For screens that need extra framed pumps with explicit durations, call this
/// helper (which leaves the tree on its first pumped frame) and then issue the
/// additional `tester.pump(...)` calls from the test body.
Future<void> pumpAppShell(
  WidgetTester tester, {
  required Widget child,
  Size? viewport,
  List<Override> overrides = const <Override>[],
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const <Locale>[Locale('en', 'US')],
  Locale? locale,
  GlobalKey<NavigatorState>? navigatorKey,
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
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: locale,
      navigatorKey: navigatorKey,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Pumps [child] inside [buildAppShellWithContainer], bound to the
/// externally-owned [container] (the caller is responsible for creating and
/// disposing it — typically via `addTearDown(container.dispose)`).
///
/// Use this for tests that read provider state back from the same container
/// after pumping (for example asserting on a notifier's value once the UI has
/// mutated it). Viewport forcing, tear-down restore, and the single-pump /
/// [settle] behaviour match [pumpAppShell].
Future<void> pumpAppShellWithContainer(
  WidgetTester tester, {
  required ProviderContainer container,
  required Widget child,
  Size? viewport,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const <Locale>[Locale('en', 'US')],
  Locale? locale,
  GlobalKey<NavigatorState>? navigatorKey,
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
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: locale,
      navigatorKey: navigatorKey,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
