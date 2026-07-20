// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
//
// Debug log viewer screen (`SYS10001`). SPEC/ui/debug-log-viewer.md.
part of 'catalog.dart';

/// Debug log viewer stories.
/// SPEC/ui/debug-log-viewer.md (`SYS10001`).
List<WidgetbookNode> get debugLogViewerDirectories => [
  WidgetbookFolder(
    name: 'Debug Log Viewer',
    children: [
      WidgetbookUseCase(
        name: 'Default — empty buffer',
        builder: (context) => _debugLogViewerFrame(
          seedLogs: false,
          child: const DebugLogViewerScreen(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Populated — warning rows',
        builder: (context) => _debugLogViewerFrame(
          seedLogs: true,
          child: const DebugLogViewerScreen(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Mobile viewport',
        builder: (context) => mobileViewport(
          context,
          _debugLogViewerFrame(
            seedLogs: false,
            child: const DebugLogViewerScreen(),
          ),
        ),
      ),
    ],
  ),
];

Widget _debugLogViewerFrame({
  required Widget child,
  required bool seedLogs,
}) {
  SessionLogBuffer.resetForTest();
  SessionLogBuffer.init();
  if (seedLogs) {
    final logger = Logger();
    // ignore: avoid_hardcoded_strings_in_widgets
    logger.w('app: widgetbook seeded warning one');
    // ignore: avoid_hardcoded_strings_in_widgets
    logger.w('app: widgetbook seeded warning two');
  }
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    useScaffold: false,
    child: child,
  );
}
