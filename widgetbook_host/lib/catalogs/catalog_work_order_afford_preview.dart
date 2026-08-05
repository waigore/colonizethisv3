part of 'catalog.dart';

/// Work-order cost and affordability preview stories. SPEC/ui/map-widget.md
/// (selection prompt); Refs #4262.
List<WidgetbookNode> get workOrderAffordPreviewDirectories => [
  WidgetbookFolder(
    name: 'Work order afford preview',
    children: [
      WidgetbookUseCase(
        name: 'Selection prompt — can afford',
        builder: (context) => _workOrderAffordSelectionPromptStory(
          affordPreview: const WorkOrderAffordPreview(
            materialCosts: {'lumber': 1, 'castIron': 2},
            canAfford: true,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Selection prompt — material shortfall',
        builder: (context) => _workOrderAffordSelectionPromptStory(
          affordPreview: const WorkOrderAffordPreview(
            materialCosts: {'lumber': 2},
            canAfford: false,
            materialShortfalls: [(commodityId: 'lumber', quantity: 1)],
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Selection prompt — treasury shortfall',
        builder: (context) => _workOrderAffordSelectionPromptStory(
          affordPreview: const WorkOrderAffordPreview(
            treasuryAmount: 500,
            canAfford: false,
            treasuryShortfall: 200,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Selection prompt — free target (no cost)',
        builder: (context) => _workOrderAffordSelectionPromptStory(
          affordPreview: const WorkOrderAffordPreview(canAfford: true),
        ),
      ),
    ],
  ),
];

Widget _workOrderAffordSelectionPromptStory({
  required WorkOrderAffordPreview affordPreview,
}) {
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    child: SizedBox(
      width: 520,
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GameMapCanvasStackSelectionPrompt(
            isNarrow: false,
            overlayOpen: false,
            onCancel: () {},
            affordPreview: affordPreview,
          ),
        ],
      ),
    ),
  );
}
