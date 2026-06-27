// Shared minimum-viewport pump harness for the
// `app/test/*_320dp_min_viewport_test.dart` family.
//
// Every 320 dp pin file previously re-declared its own private
// `_pump<Thing>AtSize(...)` helper that repeated the identical sequence:
// register a surface-size tear-down, force the binding surface size, pump a
// `ProviderScope` > `MaterialApp(theme: AppThemes.editorialMonocle)` >
// `MediaQuery(size)` shell, then pump one frame (or `pumpAndSettle`). This
// harness consolidates that boilerplate so the only per-file variation —
// the provider override list, the hosted widget, and the pump strategy —
// stays local to each test.
//
// Refs #3730 (consolidate app test scaffolding).
// SPEC: SPEC/program/repo-lint.md (test static-analysis scope).

import 'package:colonizethis_app/config/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Builds the canonical minimum-viewport app shell used by the 320 dp pin
/// suite: a [ProviderScope] (scoped by [overrides]) wrapping an
/// editorial-monocle [MaterialApp] whose [MaterialApp.home] forces [size]
/// via [MediaQuery] so widget code that reads
/// `MediaQuery.sizeOf(context).width` resolves to the minimum viewport.
///
/// [localizationsDelegates], [supportedLocales], and [locale] are forwarded
/// to the [MaterialApp] for screens whose chrome reads `AppLocalizations`;
/// their defaults match `MaterialApp`'s own so non-localized callers are
/// unaffected. Any extra structural wrappers a screen needs (a [Scaffold]
/// host, a [Stack], an event-handler scope, a launcher [Builder], …) belong
/// in [child].
///
/// Callers that need a fully custom pump sequence (multiple framed pumps,
/// explicit durations) can pump this widget directly after setting the
/// surface size; callers with the common single-pump / settle behaviour
/// should prefer [pumpAtMinViewport].
Widget buildMinViewportApp({
  required Size size,
  required Widget child,
  List<Override> overrides = const <Override>[],
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const <Locale>[Locale('en', 'US')],
  Locale? locale,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      navigatorKey: navigatorKey,
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: locale,
      home: MediaQuery(data: MediaQueryData(size: size), child: child),
    ),
  );
}

/// Pumps [child] inside [buildMinViewportApp] at the minimum viewport [size].
///
/// Registers a tear-down that restores the surface size, sets the binding
/// surface to [size] (so the framework's `RenderFlex` math sees the minimum
/// viewport), then pumps a single frame by default. When [settle] is `true`
/// the helper drives [WidgetTester.pumpAndSettle] to completion instead —
/// use it for screens whose first-frame chrome must settle before the
/// overflow assertion runs, and keep the single-pump default for screens
/// with continuous animations that would never settle.
///
/// For screens that need extra framed pumps with explicit durations, call
/// this helper (which leaves the tree on its first pumped frame) and then
/// issue the additional `tester.pump(...)` calls from the test body.
Future<void> pumpAtMinViewport(
  WidgetTester tester, {
  required Size size,
  required Widget child,
  List<Override> overrides = const <Override>[],
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const <Locale>[Locale('en', 'US')],
  Locale? locale,
  GlobalKey<NavigatorState>? navigatorKey,
  bool settle = false,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    buildMinViewportApp(
      size: size,
      overrides: overrides,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: locale,
      navigatorKey: navigatorKey,
      child: child,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
