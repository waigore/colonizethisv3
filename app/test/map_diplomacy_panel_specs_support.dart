import 'package:colonizethis_app/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_detail_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay;
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

export 'package:colonizethis_app/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';
export 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_detail_screen.dart';
export 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
export 'package:colonizethis_app/providers/map_province_panel_provider.dart';
export 'package:colonizethis_app/widgets/ct_back_button.dart';
export 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show sampleTileKeyForProvinceOverlay;
export 'package:colonizethis_logic/colonizethis_logic.dart';
export 'package:colonizethis_models/colonizethis_models.dart';
export 'package:colonizethis_app/providers/app_event_bus_provider.dart';
export 'app_shell_harness.dart';
export 'package:flutter/material.dart';
export 'package:flutter_riverpod/flutter_riverpod.dart';

/// Canonical narrow-detail overlay host for this suite (Refs #4035).
Widget narrowDetailOverlayShell({
  required ProviderContainer container,
  required Widget body,
  Size viewport = const Size(400, 600),
}) {
  return buildAppShellWithContainer(
    container: container,
    viewport: viewport,
    child: Scaffold(body: body),
  );
}

GameMapNarrowDetailOverlaySlot narrowDetailSlot() {
  return GameMapNarrowDetailOverlaySlot(
    game: demoGameForOverlay,
    region: demoRegionForOverlay,
    humanPlayerId: demoGameForOverlay.players.first.id,
    playerView: demoHumanPlayerViewForOverlay,
    workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
  );
}

Game diplomacyStoryGame({
  required bool includeHistory,
  required bool includeDossier,
  required FactionKind kind,
}) {
  const humanId = 'gp_human';
  const rivalId = 'gp_rival';
  return Game(
    id: 'spec_test',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(
        id: humanId,
        displayName: 'England',
        isHuman: true,
        treasury: 0,
      ),
      Player(
        id: rivalId,
        displayName: 'Spain',
        isHuman: false,
        treasury: 0,
      ),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: humanId,
        factionId2: rivalId,
        score: 70,
        state: RelationState.atPeace,
      ),
    ],
    diplomaticHistoryEvents: includeHistory
        ? [
            DiplomaticEvent(
              turn: 2,
              intraTurnIndex: 0,
              type: DiplomaticEventType.peace,
              participants: {humanId, rivalId},
              fromFactionId: humanId,
              toFactionId: rivalId,
            ),
          ]
        : const [],
    dossierEvidenceEntries: includeDossier
        ? [
            DossierEvidenceEntry(
              observerId: humanId,
              subjectId: rivalId,
              agendaType: 'test',
              turnNumber: 2,
              description: 'evidence line',
            ),
          ]
        : const [],
  );
}

Future<void> pumpDiplomacyDetailScreen(
  WidgetTester tester, {
  required Game game,
  required FactionKind kind,
  required DiplomacyRelation? relation,
  required AppEventBus bus,
}) async {
  const humanId = 'gp_human';
  const rivalId = 'gp_rival';
  // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
  await tester.pumpWidget(
    buildAppShell(
      overrides: [
        appEventBusProvider.overrideWith((ref) => bus),
      ],
      child: DiplomacyDetailScreen(
        game: game,
        humanPlayerId: humanId,
        factionId: rivalId,
        factionDisplayName: 'Spain',
        kind: kind,
        relation: relation,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
