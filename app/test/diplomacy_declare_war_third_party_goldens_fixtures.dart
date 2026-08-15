// Fixtures for Declare War third-party visual goldens (Refs #4409).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_detail_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/invade_province_declare_war_body.dart';
import 'package:colonizethis_app/widgets/ct_confirm_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

const kDeclareWarGoldenHumanId = 'gp1';
const kDeclareWarGoldenSpainId = 'gp2';
const kDeclareWarGoldenFranceId = 'gp3';
const kDeclareWarGoldenEnglandId = 'gp4';

Game declareWarGoldenNamedAllyGame({
  bool includeEnglandAlly = false,
  bool franceAtWarWithHuman = false,
}) {
  return Game(
    id: 'declare-war-third-party-golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      const Player(
        id: kDeclareWarGoldenHumanId,
        displayName: 'Portugal',
        isHuman: true,
      ),
      const Player(
        id: kDeclareWarGoldenSpainId,
        displayName: 'Spain',
        isHuman: false,
      ),
      const Player(
        id: kDeclareWarGoldenFranceId,
        displayName: 'France',
        isHuman: false,
      ),
      if (includeEnglandAlly)
        const Player(
          id: kDeclareWarGoldenEnglandId,
          displayName: 'England',
          isHuman: false,
        ),
    ],
    diplomacyRelations: [
      const DiplomacyRelation(
        factionId1: kDeclareWarGoldenHumanId,
        factionId2: kDeclareWarGoldenSpainId,
      ),
      const DiplomacyRelation(
        factionId1: kDeclareWarGoldenSpainId,
        factionId2: kDeclareWarGoldenFranceId,
        formalAlliance: true,
      ),
      if (includeEnglandAlly)
        const DiplomacyRelation(
          factionId1: kDeclareWarGoldenSpainId,
          factionId2: kDeclareWarGoldenEnglandId,
          formalAlliance: true,
        ),
      if (franceAtWarWithHuman)
        const DiplomacyRelation(
          factionId1: kDeclareWarGoldenHumanId,
          factionId2: kDeclareWarGoldenFranceId,
          state: RelationState.atWar,
        ),
    ],
  );
}

Game declareWarGoldenNoAllyGame() {
  return Game(
    id: 'declare-war-no-ally-golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: const [
      Player(
        id: kDeclareWarGoldenHumanId,
        displayName: 'Portugal',
        isHuman: true,
      ),
      Player(
        id: kDeclareWarGoldenSpainId,
        displayName: 'Spain',
        isHuman: false,
      ),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: kDeclareWarGoldenHumanId,
        factionId2: kDeclareWarGoldenSpainId,
      ),
    ],
  );
}

String declareWarGoldenConfirmMessage(Game game) {
  return buildDiplomacyConfirmPreviewMessage(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.declareWar,
      targetFactionId: kDeclareWarGoldenSpainId,
    ),
    game: game,
    humanPlayerId: kDeclareWarGoldenHumanId,
    targetDisplayName: 'Spain',
  );
}

Future<void> pumpDeclareWarConfirmGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size physicalSize,
  required Game game,
}) {
  return pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    settle: false,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: CtConfirmDialog(
      title: 'Declare War',
      message: declareWarGoldenConfirmMessage(game),
    ),
  );
}

Widget declareWarGoldenInvadeConfirm({
  required AppLocalizations l10n,
  required Game game,
}) {
  return Builder(
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
          .copyWith(color: EditorialMonoclePalette.danger);
      final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
          .copyWith(color: EditorialMonoclePalette.fg);
      return CtDialogShell(
        borderColor: EditorialMonoclePalette.danger,
        borderWidth: CtDialogShell.dangerBorderWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.moveArmy_invadeProvinceTitle, style: titleStyle),
            const SizedBox(height: CtSpacing.m),
            Text(
              invadeProvinceDeclareWarBody(
                l10n: l10n,
                game: game,
                humanPlayerId: kDeclareWarGoldenHumanId,
                targetFactionId: kDeclareWarGoldenSpainId,
                ownerLabel: 'Spain',
              ),
              style: bodyStyle,
            ),
            const SizedBox(height: CtSpacing.l),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: CtSpacing.m,
              runSpacing: CtSpacing.m,
              children: [
                CtNinePatchButton(
                  onPressed: () {},
                  child: Text(l10n.common_cancel),
                ),
                CtNinePatchButton(
                  dangerVariant: true,
                  onPressed: () {},
                  child: Text(l10n.moveArmy_declareWarAndMove),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget declareWarGoldenDetailHost({
  required Game game,
  required Key boundaryKey,
}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    center: false,
    useScaffold: false,
    includeLocalizations: true,
    wrapInProviderScope: true,
    child: DiplomacyDetailScreen(
      game: game,
      humanPlayerId: kDeclareWarGoldenHumanId,
      factionId: kDeclareWarGoldenSpainId,
      factionDisplayName: 'Spain',
      kind: FactionKind.greatPower,
      relation: getRelation(
        game,
        kDeclareWarGoldenHumanId,
        kDeclareWarGoldenSpainId,
      ),
    ),
  );
}
