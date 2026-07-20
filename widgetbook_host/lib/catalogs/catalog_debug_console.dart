// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
//
// Debug console overlay panel (`SYS20001`). SPEC/ui/debug-console-panel.md.
part of 'catalog.dart';

/// Debug console overlay panel stories.
/// SPEC/ui/debug-console-panel.md (`SYS20001`).
List<WidgetbookNode> get debugConsolePanelDirectories => [
  WidgetbookFolder(
    name: 'Debug Console Panel',
    children: [
      WidgetbookUseCase(
        name: 'Default — empty input',
        builder: (context) => _debugConsolePanelFrame(
          child: DebugConsoleOverlayPanel(
            bus: AppEventBus.create(),
            // ignore: avoid_hardcoded_strings_in_widgets
            humanPlayerId: 'gp1',
            readOnlyContextProvider: () => null,
            onClose: () {},
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Mobile viewport',
        builder: (context) => mobileViewport(
          context,
          _debugConsolePanelFrame(
            child: DebugConsoleOverlayPanel(
              bus: AppEventBus.create(),
              // ignore: avoid_hardcoded_strings_in_widgets
              humanPlayerId: 'gp1',
              readOnlyContextProvider: () => null,
              onClose: () {},
            ),
          ),
        ),
      ),
    ],
  ),
];

Widget _debugConsolePanelFrame({required Widget child}) {
  return ColoredBox(
    color: EditorialMonoclePalette.bgDeep,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(height: 280, child: child),
    ),
  );
}
