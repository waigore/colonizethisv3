// coverage:ignore-file
// Dev-only Widgetbook catalog part; Game Tab Bar labour/feeding
// stories (Refs #4506). Split from catalog_game_chrome.dart so that
// fragment stays under the repo-wide 1000 non-comment-line ceiling.
part of 'catalog.dart';

const LabourReadinessSnapshot _kReducedLabour = LabourReadinessSnapshot(
  effectiveLabour: 12,
  fullCapacity: 20,
  tierStatuses: [],
  primaryCauseKind: LabourReadinessCauseKind.food,
);

const LabourReadinessSnapshot _kEmptyPoolLabour = LabourReadinessSnapshot(
  effectiveLabour: 0,
  fullCapacity: 0,
  tierStatuses: [],
);

const ForceFeedingSnapshot _kNoForcesFed = ForceFeedingSnapshot(
  totalRegiments: 0,
  fullyFedRegiments: 0,
  totalShips: 0,
  fullyFedShips: 0,
  landCombatTier: ForceFeedingCombatTier.full,
  navalCombatTier: ForceFeedingCombatTier.full,
  forcesFoodDemand: 0,
);

const ForceFeedingSnapshot _kUnderfedLand = ForceFeedingSnapshot(
  totalRegiments: 4,
  fullyFedRegiments: 1,
  totalShips: 0,
  fullyFedShips: 0,
  landCombatTier: ForceFeedingCombatTier.severe,
  navalCombatTier: ForceFeedingCombatTier.full,
  forcesFoodDemand: 8,
);

/// Game Tab Bar labour/feeding indicator use cases. Refs #4506.
List<WidgetbookUseCase> get _labourFeedingTabBarStories => [
  WidgetbookUseCase(
    name: 'Labour — reduced (accent numeric) (Refs #4506)',
    builder: (context) => _gameTabBarStoryFrame(
      showLabourFeedingIndicator: true,
      labourFeedingLabel: '12/20',
      labourReadiness: _kReducedLabour,
      forcesFeeding: _kNoForcesFed,
    ),
  ),
  WidgetbookUseCase(
    name: 'Labour — empty pool (muted 0/0) (Refs #4506)',
    builder: (context) => _gameTabBarStoryFrame(
      showLabourFeedingIndicator: true,
      labourFeedingLabel: '0/0',
      labourReadiness: _kEmptyPoolLabour,
      forcesFeeding: _kNoForcesFed,
    ),
  ),
  WidgetbookUseCase(
    name: 'Labour — underfed forces (danger) (Refs #4506)',
    builder: (context) => _gameTabBarStoryFrame(
      showLabourFeedingIndicator: true,
      labourFeedingLabel: '20/20',
      labourReadiness: const LabourReadinessSnapshot(
        effectiveLabour: 20,
        fullCapacity: 20,
        tierStatuses: [],
      ),
      forcesFeeding: _kUnderfedLand,
    ),
  ),
];
