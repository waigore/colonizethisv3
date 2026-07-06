part of 'app_event_handler.dart';

extension _AppEventHandlerUnitPanels on AppEventHandler {
  Future<void> _openCivilianUnitsPanel(
    OpenCivilianUnitsPanelEvent event,
    NavigatorState? nav,
  ) async {
    if (nav == null) return;
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
          final shell = ref.read(shellPlayerContextProvider);
          final civilianOwnerIds = resolveCivilianMarkerOwnerIds(shell, game);
          final panelPlayerId = resolveShellPanelPlayerId(shell, game);
          final readOnly = !shell.canMutateViaUi;
          final currentOrders = ref.watch(currentOrdersProvider);
          final bus = ref.watch(appEventBusProvider);
          // Viewport-adaptive bottom-sheet sizing shared by all three unit
          // panels: 50% height (narrow), 70% width / 55vh (wide). Refs #3627,
          // SPEC/ui/components/units-panel-shell.md § Bottom-sheet sizing.
          final viewport = MediaQuery.sizeOf(context);
          final baseConstraints = unitsPanelSheetConstraints(viewport);
          // E2E panel-text assertions require every unit row mounted; the
          // adaptive sheet height virtualizes lower rows on the headless
          // 1280×720 host, so widen to 92% under E2E only (Refs #2336
          // AC6 / AC7 / AC10).
          final sheetConstraints = kCtE2EEnabled
              ? baseConstraints.copyWith(maxHeight: viewport.height * 0.92)
              : baseConstraints;
          return UnitsPanelSheetSurface(
            child: ConstrainedBox(
              constraints: sheetConstraints,
              child: CivilianUnitsPanel(
                game: game,
                humanPlayerId:
                    panelPlayerId ??
                    (civilianOwnerIds.isNotEmpty
                        ? civilianOwnerIds.first
                        : game.players.first.id),
                civilianOwnerIds: civilianOwnerIds,
                bus: bus,
                readOnly: readOnly,
                currentOrders: currentOrders,
                tileScopeTileKey: event.tileScopeTileKey,
                initialSelectedUnitId: event.initialSelectedUnitId,
                explorerOnly: event.explorerOnly,
                builderOnly: event.builderOnly,
                prospectShortcutTargetTileKey:
                    event.prospectShortcutTargetTileKey,
                exploreShortcutTargetTileKey:
                    event.exploreShortcutTargetTileKey,
                buildImprovementShortcutTargetTileKey:
                    event.buildImprovementShortcutTargetTileKey,
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      if (kCtE2EEnabled) {
        updateCtE2eCivilianPanelSnapshotIfEnabled(null);
      }
      _bus.emit(const UnitsPanelClosedEvent('civilian'));
    });
  }

  Future<void> _openMilitaryUnitsPanel(
    OpenMilitaryUnitsPanelEvent event,
    NavigatorState? nav,
  ) async {
    if (nav == null) return;
    await showModalBottomSheet<void>(
      context: nav.context,
      // Viewport-adaptive sizing requires the sheet to own its height
      // (Refs #3627); the host ConstrainedBox below sets the 50% / 55vh cap.
      isScrollControlled: true,
      // Transparent Material surface so UnitsPanelSheetSurface owns the
      // mockup `.sheet` chrome (#3514 owner decision #4).
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final game = ref.watch(currentGameProvider);
          if (game == null) {
            return const SizedBox.shrink();
          }
          final shell = ref.read(shellPlayerContextProvider);
          final sentinel = observeNotDefinedSentinel(shell, 'Military Units');
          if (sentinel != null) return sentinel;
          final humanPlayerId = resolveShellPanelPlayerId(shell, game);
          final readOnly = !shell.canMutateViaUi;
          final bus = ref.watch(appEventBusProvider);
          final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
          final draftOrders = ref.watch(currentOrdersProvider);
          // 50% height (narrow), 70% width / 55vh (wide). Refs #3627.
          final sheetConstraints = unitsPanelSheetConstraints(
            MediaQuery.sizeOf(context),
          );
          return UnitsPanelSheetSurface(
            child: ConstrainedBox(
              constraints: sheetConstraints,
              child: MilitaryUnitsPanel(
                game: game,
                humanPlayerId: humanPlayerId,
                bus: bus,
                readOnly: readOnly,
                topology: mapData?.combinedTopology ?? const MapTopology(),
                draftOrders: draftOrders,
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => _bus.emit(const UnitsPanelClosedEvent('military')));
  }

  Future<void> _openNavalUnitsPanel(
    OpenNavalUnitsPanelEvent event,
    NavigatorState? nav,
  ) async {
    if (nav == null) return;
    await showModalBottomSheet<void>(
      context: nav.context,
      // Viewport-adaptive sizing requires the sheet to own its height
      // (Refs #3627); the host ConstrainedBox below sets the 50% / 55vh cap.
      isScrollControlled: true,
      // Transparent Material surface so UnitsPanelSheetSurface owns the
      // mockup `.sheet` chrome (#3514 owner decision #4).
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final game = ref.watch(currentGameProvider);
          if (game == null) {
            return const SizedBox.shrink();
          }
          final shell = ref.read(shellPlayerContextProvider);
          final sentinel = observeNotDefinedSentinel(shell, 'Naval Units');
          if (sentinel != null) return sentinel;
          final humanPlayerId = resolveShellPanelPlayerId(shell, game);
          final readOnly = !shell.canMutateViaUi;
          final bus = ref.watch(appEventBusProvider);
          final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
          final draftOrders = ref.watch(currentOrdersProvider);
          // 50% height (narrow), 70% width / 55vh (wide). Naval uses the same
          // shared rule as the other panels (no fixed sidebar). Refs #3627.
          final sheetConstraints = unitsPanelSheetConstraints(
            MediaQuery.sizeOf(context),
          );
          return UnitsPanelSheetSurface(
            child: ConstrainedBox(
              constraints: sheetConstraints,
              child: NavalUnitsPanel(
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
            ),
          );
        },
      ),
    ).whenComplete(() {
      // Keep the last naval snapshot after close; [refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled]
      // updates it post–next-turn so fleet E2E can skip reopening the panel (Refs #2336).
      _bus.emit(const UnitsPanelClosedEvent('naval'));
    });
  }
}
