// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
//
// Observe-mode global sentinel panel (`OVL60001`). SPEC/ui/observe-mode.md.
part of 'catalog.dart';

/// Global-observe "not defined" sentinel stories.
/// SPEC/ui/observe-mode.md (`OVL60001`).
List<WidgetbookNode> get observeModeNotDefinedPanelDirectories => [
  WidgetbookFolder(
    name: 'Observe Mode Not Defined Panel',
    children: [
      WidgetbookUseCase(
        name: 'Default — label only',
        builder: (context) => _observeModeNotDefinedPanelFrame(
          child: const ObserveModeNotDefinedPanel(),
        ),
      ),
      WidgetbookUseCase(
        name: 'With title — Trade',
        builder: (context) => _observeModeNotDefinedPanelFrame(
          // ignore: avoid_hardcoded_strings_in_widgets
          child: const ObserveModeNotDefinedPanel(title: 'Trade'),
        ),
      ),
      WidgetbookUseCase(
        name: 'Mobile viewport',
        builder: (context) => mobileViewport(
          context,
          _observeModeNotDefinedPanelFrame(
            // ignore: avoid_hardcoded_strings_in_widgets
            child: const ObserveModeNotDefinedPanel(title: 'Diplomacy'),
          ),
        ),
      ),
    ],
  ),
];

Widget _observeModeNotDefinedPanelFrame({required Widget child}) {
  return ColoredBox(
    color: EditorialMonoclePalette.bgDeep,
    child: Center(child: child),
  );
}
