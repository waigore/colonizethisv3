import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/game/widgets/units/shared/units_panel_sheet_surface.dart';
import '../../../features/game/widgets/units/shared/units_panel_viewport_constraints.dart';
import '../../../providers/games_provider.dart';
import '../../../widgets/ct_app_perf_interactive_ready_marker.dart';
import 'app_event_handler.dart';

/// Result of a unit-panel sheet body builder.
typedef UnitsPanelSheetBody = ({Widget? replacement, Widget? panel});

/// Shared bottom-sheet host for civilian / military / naval unit panels.
Future<void> appEventHandlerShowUnitsPanelSheet(
  AppEventHandler handler, {
  required NavigatorState nav,
  required String panelKind,
  required UnitsPanelSheetBody Function(
    BuildContext context,
    WidgetRef ref,
    Game game,
  )
  buildBody,
  bool applyCivilianE2eHeightOverride = false,
  VoidCallback? beforeClosedEvent,
}) async {
  await showModalBottomSheet<void>(
    context: nav.context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (ctx) => Consumer(
      builder: (context, ref, _) {
        final game = ref.watch(currentGameProvider);
        if (game == null) {
          return const SizedBox.shrink();
        }
        final body = buildBody(context, ref, game);
        final replacement = body.replacement;
        if (replacement != null) {
          return replacement;
        }
        final panel = body.panel;
        if (panel == null) {
          return const SizedBox.shrink();
        }
        final sheetConstraints = unitsPanelHostSheetConstraints(
          viewport: MediaQuery.sizeOf(context),
          applyCivilianE2eHeightOverride: applyCivilianE2eHeightOverride,
          e2eEnabled: kCtE2EEnabled,
        );
        return CtAppPerfInteractiveReadyMarker(
          markerName: '${panelKind}Units.interactiveReady',
          child: UnitsPanelSheetSurface(
            child: ConstrainedBox(
              constraints: sheetConstraints,
              child: panel,
            ),
          ),
        );
      },
    ),
  ).whenComplete(() {
    beforeClosedEvent?.call();
    handler.state.bus.emit(UnitsPanelClosedEvent(panelKind));
  });
}
