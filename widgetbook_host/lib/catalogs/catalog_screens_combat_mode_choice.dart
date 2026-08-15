part of 'catalog.dart';

/// CMPT10001 force/fort/Details stories. SPEC/ui/combat-mode-choice-dialog.md
/// § Widgetbook (Refs #4438).
List<WidgetbookNode> get combatModeChoiceDirectories => [
  WidgetbookFolder(
    name: 'Combat Mode Choice Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Regular province',
        builder: (context) => _combatStoryFrame(
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: 'Lisbon',
            isCapitalSiege: false,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Capital siege',
        builder: (context) => _combatStoryFrame(
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: 'Madrid',
            isCapitalSiege: true,
            intel: const CombatModeChoiceIntel(
              role: CombatModeChoiceRole.attacker,
              ownRegimentCount: 4,
              ownTypesByRegimentId: {'musketeers': 4},
              enemyRegimentCount: 6,
              enemyTypesByRegimentId: {'pikemen': 6},
              fortLevel: 3,
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Attacker full intel',
        builder: (context) => _combatStoryFrame(
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: 'Lisbon',
            isCapitalSiege: false,
            intel: const CombatModeChoiceIntel(
              role: CombatModeChoiceRole.attacker,
              ownRegimentCount: 3,
              ownTypesByRegimentId: {'musketeers': 2, 'pikemen': 1},
              enemyRegimentCount: 2,
              enemyTypesByRegimentId: {'musketeers': 2},
              fortLevel: 1,
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Attacker unknown intel',
        builder: (context) => _combatStoryFrame(
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: 'Lisbon',
            isCapitalSiege: false,
            intel: const CombatModeChoiceIntel(
              role: CombatModeChoiceRole.attacker,
              ownRegimentCount: 3,
              ownTypesByRegimentId: {'musketeers': 3},
              defendersUnknown: true,
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Defender full intel',
        builder: (context) => _combatStoryFrame(
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: 'Lisbon',
            isCapitalSiege: false,
            intel: const CombatModeChoiceIntel(
              role: CombatModeChoiceRole.defender,
              ownRegimentCount: 5,
              ownTypesByRegimentId: {'musketeers': 3, 'pikemen': 2},
              enemyRegimentCount: 4,
              enemyTypesByRegimentId: {'musketeers': 4},
              fortLevel: 2,
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Details open',
        builder: (context) => _combatStoryFrame(
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: 'Lisbon',
            isCapitalSiege: false,
            detailsInitiallyOpen: true,
            intel: const CombatModeChoiceIntel(
              role: CombatModeChoiceRole.attacker,
              ownRegimentCount: 3,
              ownTypesByRegimentId: {'musketeers': 2, 'pikemen': 1},
              enemyRegimentCount: 2,
              enemyTypesByRegimentId: {'musketeers': 2},
              fortLevel: 0,
            ),
          ),
        ),
      ),
    ],
  ),
];
