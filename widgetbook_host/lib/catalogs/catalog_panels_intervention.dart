// coverage:ignore-file
// Dev-only Widgetbook catalog part; OVL50001 intervention dialogue (Refs #4267).
part of 'catalog.dart';

Game _interventionWidgetbookStoryGame() {
  return Game(
    id: 'wb_iv',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 3),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(
        id: 'spain',
        displayName: 'Spain',
        isHuman: false,
        treasury: 0,
      ),
      Player(
        id: 'portugal',
        displayName: 'Portugal',
        isHuman: true,
        treasury: 0,
      ),
    ],
    minorNations: const [
      MinorNation(id: 'minorca', displayName: 'Minorca'),
    ],
    overtureStates: const [
      OvertureState(
        gpId: 'portugal',
        targetId: 'minorca',
        stage: OvertureStage.embassy,
      ),
    ],
  );
}

TextStyle _interventionOverlayTitleStyle(ThemeData theme) {
  final TextStyle base =
      theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
  final double fontSize = base.fontSize ?? 16;
  return base.copyWith(
    color: EditorialMonoclePalette.accent,
    letterSpacing:
        fontSize * kInterventionOverlayTitleLetterSpacingEm,
  );
}

/// Static choice-picker preview mirroring OVL50001 choice phase (#4267).
Widget _interventionChoicePickerEffectsPreview(BuildContext context) {
  final l10n = appL10n(context);
  const aggressorName = 'Spain';
  const defenderName = 'Minorca';
  final TextStyle? holdReasonStyle =
      Theme.of(context).textTheme.bodySmall?.copyWith(
            color: EditorialMonoclePalette.muted,
          );
  return SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.game_intervention_resolutionProgress(1, 1),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: CtSpacing.ml),
        Text(
          l10n.game_intervention_choiceSituation(aggressorName, defenderName),
          key: const ValueKey<String>(kInterventionChoiceSituationKey),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: CtSpacing.s),
        Text(
          l10n.game_intervention_holdReasonEmbassy,
          key: const ValueKey<String>(kInterventionHoldReasonKey),
          style: holdReasonStyle,
        ),
        const SizedBox(height: CtSpacing.l),
        InterventionChoiceButtons(
          onPick: (_) {},
          interveneEffect: l10n.game_intervention_effectIntervene(
            aggressorName,
            defenderName,
          ),
          doNothingEffect: l10n.game_intervention_effectDoNothing(
            aggressorName,
            defenderName,
          ),
          protestEffect: l10n.game_intervention_effectProtest(
            aggressorName,
            defenderName,
          ),
        ),
      ],
    ),
  );
}

/// Intervention blocking dialogue. SPEC/ui/screens/pending-intervention-overlay.md.
List<WidgetbookNode> get interventionDialogueDirectories => [
  WidgetbookFolder(
    name: 'Dialogue',
    children: [
      WidgetbookUseCase(
        name: 'InterventionDialogueOverlay',
        builder: (context) {
          return widgetbookEditorialMonocleApp(
            child: InterventionDialogueOverlay(
              game: _interventionWidgetbookStoryGame(),
              prompts: const [
                InterventionPrompt(
                  aggressorGpId: 'spain',
                  defenderMinorOrTribeId: 'minorca',
                  interveningGpId: 'portugal',
                ),
              ],
              skipIntroForTest: true,
              onDecisions: (_) {},
              child: Center(child: Text(appL10n(context).widgetbook_gameShell)),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Choice picker — Effects (#4267)',
        builder: (context) {
          final theme = Theme.of(context);
          return widgetbookEditorialMonocleApp(
            child: CtFullScreenDialogueShell(
              backdrop: Center(child: Text(appL10n(context).widgetbook_gameShell)),
              maxWidth: kInterventionShellMaxWidth,
              padding: const EdgeInsets.all(CtSpacing.xl),
              body: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    appL10n(context).game_intervention_overlayTitle,
                    key: const ValueKey<String>(kInterventionOverlayTitleKey),
                    style: _interventionOverlayTitleStyle(theme),
                  ),
                  const SizedBox(height: kInterventionTitleToDividerGap),
                  const CtBrassDivider(
                    key: ValueKey<String>(kInterventionOverlayBrassDividerKey),
                  ),
                  const SizedBox(height: kInterventionDividerToBodyGap),
                  _interventionChoicePickerEffectsPreview(context),
                ],
              ),
            ),
          );
        },
      ),
    ],
  ),
];
