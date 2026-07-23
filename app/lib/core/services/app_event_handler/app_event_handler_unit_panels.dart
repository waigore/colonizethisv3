part of 'app_event_handler.dart';

/// Result of a unit-panel sheet body builder: either an early [replacement]
/// (e.g. observe-mode sentinel) or the [panel] widget to wrap in sheet chrome.
typedef _UnitsPanelSheetBody = ({Widget? replacement, Widget? panel});

extension _AppEventHandlerUnitPanels on AppEventHandler {
  /// Shared bottom-sheet host for civilian / military / naval unit panels.
  ///
  /// Owns transparent Material chrome, [UnitsPanelSheetSurface], host
  /// [ConstrainedBox] sizing, and the [UnitsPanelClosedEvent] emission.
  /// Panel bodies (and military/naval observe-mode sentinels) are injected via
  /// [buildBody]. Civilian-only E2E height override is gated by
  /// [applyCivilianE2eHeightOverride]. Refs #4035 AC1 /
  /// SPEC/ui/components/units-panel-shell.md.
  Future<void> _showUnitsPanelSheet({
    required NavigatorState nav,
    required String panelKind,
    required _UnitsPanelSheetBody Function(
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
      // Transparent Material surface so UnitsPanelSheetSurface owns the
      // mockup `.sheet` chrome (gradient + 2 px accent-dim top edge + 4 dp
      // top radius). SPEC/ui/components/units-panel-shell.md § Bottom-sheet
      // host chrome (#3514 owner decision #4).
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
          return UnitsPanelSheetSurface(
            child: ConstrainedBox(
              constraints: sheetConstraints,
              child: panel,
            ),
          );
        },
      ),
    ).whenComplete(() {
      beforeClosedEvent?.call();
      _bus.emit(UnitsPanelClosedEvent(panelKind));
    });
  }

  Future<void> _openCivilianUnitsPanel(
    OpenCivilianUnitsPanelEvent event,
    NavigatorState? nav,
  ) async {
    if (nav == null) return;
    await _showUnitsPanelSheet(
      nav: nav,
      panelKind: 'civilian',
      applyCivilianE2eHeightOverride: true,
      beforeClosedEvent: () {
        if (kCtE2EEnabled) {
          updateCtE2eCivilianPanelSnapshotIfEnabled(null);
        }
      },
      buildBody: (context, ref, game) {
        final shell = ref.read(shellPlayerContextProvider);
        final civilianOwnerIds = resolveCivilianMarkerOwnerIds(shell, game);
        final panelPlayerId = resolveShellPanelPlayerId(shell, game);
        final readOnly = !shell.canMutateViaUi;
        final currentOrders = ref.watch(currentOrdersProvider);
        final bus = ref.watch(appEventBusProvider);
        return (
          replacement: null,
          panel: CivilianUnitsPanel(
            game: game,
            humanPlayerId: panelPlayerId,
            civilianOwnerIds: civilianOwnerIds,
            bus: bus,
            readOnly: readOnly,
            currentOrders: currentOrders,
            tileScopeTileKey: event.tileScopeTileKey,
            initialSelectedUnitId: event.initialSelectedUnitId,
            explorerOnly: event.explorerOnly,
            builderOnly: event.builderOnly,
            prospectShortcutTargetTileKey: event.prospectShortcutTargetTileKey,
            exploreShortcutTargetTileKey: event.exploreShortcutTargetTileKey,
            buildImprovementShortcutTargetTileKey:
                event.buildImprovementShortcutTargetTileKey,
          ),
        );
      },
    );
  }

  Future<void> _openMilitaryUnitsPanel(
    OpenMilitaryUnitsPanelEvent event,
    NavigatorState? nav,
  ) async {
    if (nav == null) return;
    await _showUnitsPanelSheet(
      nav: nav,
      panelKind: 'military',
      buildBody: (context, ref, game) {
        final shell = ref.read(shellPlayerContextProvider);
        final sentinel = observeNotDefinedSentinel(shell, 'Military Units');
        if (sentinel != null) {
          return (replacement: sentinel, panel: null);
        }
        final humanPlayerId = resolveShellPanelPlayerId(shell, game);
        final readOnly = !shell.canMutateViaUi;
        final bus = ref.watch(appEventBusProvider);
        final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
        final draftOrders = ref.watch(currentOrdersProvider);
        return (
          replacement: null,
          panel: MilitaryUnitsPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            bus: bus,
            readOnly: readOnly,
            topology: mapData?.combinedTopology ?? const MapTopology(),
            draftOrders: draftOrders,
          ),
        );
      },
    );
  }

  Future<void> _openNavalUnitsPanel(
    OpenNavalUnitsPanelEvent event,
    NavigatorState? nav,
  ) async {
    if (nav == null) return;
    await _showUnitsPanelSheet(
      nav: nav,
      panelKind: 'naval',
      // Keep the last naval snapshot after close; refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled
      // updates it post–next-turn so fleet E2E can skip reopening the panel (Refs #2336).
      buildBody: (context, ref, game) {
        final shell = ref.read(shellPlayerContextProvider);
        final sentinel = observeNotDefinedSentinel(shell, 'Naval Units');
        if (sentinel != null) {
          return (replacement: sentinel, panel: null);
        }
        final humanPlayerId = resolveShellPanelPlayerId(shell, game);
        final readOnly = !shell.canMutateViaUi;
        final bus = ref.watch(appEventBusProvider);
        final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
        final draftOrders = ref.watch(currentOrdersProvider);
        return (
          replacement: null,
          panel: NavalUnitsPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            bus: bus,
            readOnly: readOnly,
            topology: mapData?.combinedTopology ?? const MapTopology(),
            draftOrders: draftOrders,
            tileMapByRegion: mapData?.tileMapByRegion,
            topologyByRegion: mapData?.topologyByRegion,
            locationScopeKey: event.locationScopeKey,
            initialSelectedFleetId: event.initialSelectedFleetId,
            tileScopeTileKey: event.tileScopeTileKey,
          ),
        );
      },
    );
  }
}
