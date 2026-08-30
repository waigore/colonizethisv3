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
      WidgetbookUseCase(
        name: 'Selection prompt — Build improvement next yield raise',
        builder: (context) => _workOrderAffordSelectionPromptStory(
          affordPreview: const WorkOrderAffordPreview(
            materialCosts: {'lumber': 1, 'castIron': 1},
            canAfford: true,
          ),
          nextYieldGist: 'After this work: 0 → 1 Grain if still linked',
        ),
      ),
      WidgetbookUseCase(
        name: 'Selection prompt — Build improvement next yield road cap',
        builder: (context) => _workOrderAffordSelectionPromptStory(
          affordPreview: const WorkOrderAffordPreview(
            materialCosts: {'lumber': 4, 'castIron': 4},
            canAfford: true,
          ),
          nextYieldGist:
              'After this work: still 2 Timber — the road is the limit',
        ),
      ),
      WidgetbookUseCase(
        name: 'Selection prompt — Build improvement next yield town cap',
        builder: (context) => _workOrderAffordSelectionPromptStory(
          affordPreview: const WorkOrderAffordPreview(
            materialCosts: {'lumber': 4, 'castIron': 4},
            canAfford: true,
          ),
          nextYieldGist:
              'After this work: still 2 Grain — town development is the limit',
        ),
      ),
      WidgetbookUseCase(
        name: 'Selection prompt — Build improvement next yield disconnected',
        builder: (context) => _workOrderAffordSelectionPromptStory(
          affordPreview: const WorkOrderAffordPreview(
            materialCosts: {'lumber': 1, 'castIron': 1},
            canAfford: true,
          ),
          nextYieldGist:
              'After this work: still none — not bound to the capital',
        ),
      ),
      WidgetbookUseCase(
        name: 'Selection prompt — transport step yield raise',
        builder: (context) => _workOrderAffordSelectionPromptStory(
          affordPreview: const WorkOrderAffordPreview(
            materialCosts: {'lumber': 1, 'castIron': 1},
            canAfford: true,
          ),
          transportGist: 'After this work: 0 → 1 Grain if still linked',
        ),
      ),
      WidgetbookUseCase(
        name: 'Selection prompt — transport step yield road cap',
        builder: (context) => _workOrderAffordSelectionPromptStory(
          affordPreview: const WorkOrderAffordPreview(
            materialCosts: {'lumber': 1, 'castIron': 1},
            canAfford: true,
          ),
          transportGist:
              'After this work: still 2 Timber — the road is the limit',
        ),
      ),
      WidgetbookUseCase(
        name: 'Selection prompt — transport step yield disconnected',
        builder: (context) => _workOrderAffordSelectionPromptStory(
          affordPreview: const WorkOrderAffordPreview(
            materialCosts: {'lumber': 1, 'castIron': 1},
            canAfford: true,
          ),
          transportGist:
              'After this work: still none — not bound to the capital until a path home exists',
        ),
      ),
      WidgetbookUseCase(
        name: 'Selection prompt — transport step yield binds capital',
        builder: (context) => _workOrderAffordSelectionPromptStory(
          affordPreview: const WorkOrderAffordPreview(
            materialCosts: {'lumber': 1, 'castIron': 1},
            canAfford: true,
          ),
          transportGist: 'After this work: binds this tile to the capital',
        ),
      ),
      WidgetbookUseCase(
        name: 'Selection prompt — transport step yield port on coast',
        builder: (context) => _workOrderAffordSelectionPromptStory(
          affordPreview: const WorkOrderAffordPreview(
            materialCosts: {'lumber': 2, 'castIron': 2},
            canAfford: true,
          ),
          transportGist: 'After this work: this coast gets a port',
        ),
      ),
      WidgetbookUseCase(
        name: 'Selection prompt — Purchase land tradeable gist',
        builder: (context) {
          final l10n = AppLocalizationsEn();
          return _workOrderAffordSelectionPromptStory(
            affordPreview: const WorkOrderAffordPreview(
              treasuryAmount: 150,
              canAfford: true,
            ),
            payoffGist: l10n.provinceOverlay_tilePurchaseLandPayoffTradeable(
              'Timber',
              'Portugal',
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Selection prompt — Purchase land riches gist',
        builder: (context) {
          final l10n = AppLocalizationsEn();
          return _workOrderAffordSelectionPromptStory(
            affordPreview: const WorkOrderAffordPreview(
              treasuryAmount: 750,
              canAfford: true,
            ),
            payoffGist: l10n.provinceOverlay_tilePurchaseLandPayoffRiches(
              'Gold',
              'Ashanti',
            ),
          );
        },
      ),
    ],
  ),
];

Widget _workOrderAffordSelectionPromptStory({
  required WorkOrderAffordPreview affordPreview,
  String? nextYieldGist,
  String? payoffGist,
  String? transportGist,
}) {
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    child: SizedBox(
      width: 520,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GameMapCanvasStackSelectionPrompt(
            isNarrow: false,
            overlayOpen: false,
            onCancel: () {},
            affordPreview: affordPreview,
            nextYieldGist: nextYieldGist,
            payoffGist: payoffGist,
            transportGist: transportGist,
          ),
        ],
      ),
    ),
  );
}
