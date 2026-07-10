// Shared golden-capture host for `app/test/**/*golden*_test.dart` (Refs #3952).
//
// Golden suites previously each re-declared surface sizing (`physicalSize` /
// `setSurfaceSize`), an editorial-monocle `MaterialApp` + keyed
// `RepaintBoundary` shell, and either `pumpAndSettle` or a two-frame bounded
// flush (nine-patch / Flame tickers hang `pumpAndSettle`). This module owns
// those pieces; golden files supply fixtures, finders, and golden paths only.
//
// Prefer [pumpGoldenHost] for the common physicalSize + settle path. Use
// [configureGoldenSurface] + [wrapGoldenBoundary] + [pumpForGolden] (or
// [pumpDiplomacyPanelBuilt] for diplomacy panels) when the hosted tree needs
// ProviderScope overrides or a custom outer shell.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Configures the test view for a golden capture via [TestFlutterView].
///
/// Registers `tester.view.reset` teardown. Prefer this over binding
/// [TestWidgetsFlutterBinding.setSurfaceSize] when the suite already pins
/// layout through view metrics (research/tech/leader-selection goldens).
void configureGoldenView(
  WidgetTester tester, {
  required Size physicalSize,
  double devicePixelRatio = 1.0,
}) {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
}

/// Configures the binding surface size for a golden capture.
///
/// Registers a teardown that clears the forced surface. Prefer this when the
/// suite historically used `setSurfaceSize` (diplomacy / train / unit panels).
Future<void> configureGoldenSurface(
  WidgetTester tester, {
  required Size size,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
}

/// Editorial-monocle [MaterialApp] hosting [child] inside a keyed
/// [RepaintBoundary] for `matchesGoldenFile`.
///
/// When [center] is true (default), the boundary is wrapped in [Center].
/// When [useScaffold] is true (default), the boundary sits in a [Scaffold]
/// body. Pass [scaffoldBackgroundColor] to match dialog chrome that paints
/// against the theme scaffold color explicitly.
///
/// When [includeLocalizations] is true, wires [AppLocalizationsBinding]
/// delegates / locales (leader selection, research slot, technology goldens).
/// When [wrapInProviderScope] is true (or [overrides] is non-empty), wraps the
/// app in a [ProviderScope].
/// When [alignment] is non-null, the boundary is wrapped in [Align] (used by
/// bottom-anchored unit-panel mobile goldens). Otherwise when [center] is true
/// (default), the boundary is wrapped in [Center].
Widget wrapGoldenBoundary({
  required Key boundaryKey,
  required Widget child,
  bool center = true,
  Alignment? alignment,
  bool useScaffold = true,
  Color? scaffoldBackgroundColor,
  bool includeLocalizations = false,
  bool wrapInProviderScope = false,
  List<Override> overrides = const <Override>[],
}) {
  Widget boundary = RepaintBoundary(key: boundaryKey, child: child);
  if (alignment != null) {
    boundary = Align(alignment: alignment, child: boundary);
  } else if (center) {
    boundary = Center(child: boundary);
  }
  final Widget home = useScaffold
      ? Scaffold(
          backgroundColor: scaffoldBackgroundColor,
          body: boundary,
        )
      : boundary;
  final MaterialApp app = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: includeLocalizations
        ? AppLocalizationsBinding.localizationsDelegates
        : null,
    supportedLocales: includeLocalizations
        ? AppLocalizations.supportedLocales
        : const <Locale>[Locale('en', 'US')],
    locale: includeLocalizations ? const Locale('en') : null,
    home: home,
  );
  if (!wrapInProviderScope && overrides.isEmpty) {
    return app;
  }
  return ProviderScope(overrides: overrides, child: app);
}

/// Flushes frames after pumping a golden host.
///
/// When [settle] is true, uses [WidgetTester.pumpAndSettle]. When false, runs
/// the two-frame bounded flush used where animated chrome keeps the ticker
/// busy (diplomacy / pennant / players-bar goldens).
Future<void> pumpForGolden(
  WidgetTester tester, {
  bool settle = true,
}) async {
  if (settle) {
    await tester.pumpAndSettle();
    return;
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

/// Configures the view, pumps [wrapGoldenBoundary], and flushes frames.
Future<void> pumpGoldenHost(
  WidgetTester tester, {
  required Key boundaryKey,
  required Widget child,
  required Size physicalSize,
  double devicePixelRatio = 1.0,
  bool settle = true,
  bool center = true,
  bool useScaffold = true,
  Color? scaffoldBackgroundColor,
  bool includeLocalizations = false,
  bool wrapInProviderScope = false,
  List<Override> overrides = const <Override>[],
}) async {
  configureGoldenView(
    tester,
    physicalSize: physicalSize,
    devicePixelRatio: devicePixelRatio,
  );
  await tester.pumpWidget(
    wrapGoldenBoundary(
      boundaryKey: boundaryKey,
      child: child,
      center: center,
      useScaffold: useScaffold,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      includeLocalizations: includeLocalizations,
      wrapInProviderScope: wrapInProviderScope,
      overrides: overrides,
    ),
  );
  await pumpForGolden(tester, settle: settle);
}
