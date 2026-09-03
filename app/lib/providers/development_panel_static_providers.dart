import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show ConnectivityResult, allProvinces, buildPlayerView;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/widgets/shell/shell_player_context.dart';
import 'development_panel_session_cache.dart';
import 'development_panel_session_revision.dart';
import 'game_service_provider.dart';
import 'games_provider.dart';

/// Connectivity map — invalidates on game/map changes only (not draft orders).
final developmentPanelConnectivityProvider =
    Provider.autoDispose<Map<String, ConnectivityResult>?>((ref) {
      final game = ref.watch(currentGameProvider);
      final mapData = game == null
          ? null
          : ref.watch(gameServiceProvider).getMapData(game.id);
      if (game == null || mapData == null) return null;
      final staticRevision = developmentPanelStaticSessionRevision(game: game);
      final session = ref.read(developmentPanelSessionCacheProvider).state;
      if (session.staticRevision == staticRevision &&
          session.connectivity != null) {
        return session.connectivity;
      }
      final humanPlayerId = resolveShellPanelPlayerId(
        ref.watch(shellPlayerContextProvider),
        game,
      );
      final connectivity = ctAppPerfSync(
        'developmentPanel.connectivity',
        () => resolveDevelopmentPanelConnectivity(
          game: game,
          tileMapByRegion: mapData.tileMapByRegion,
          topology: mapData.combinedTopology,
          humanPlayerId: humanPlayerId,
        ),
      );
      ref
          .read(developmentPanelSessionCacheProvider)
          .storeConnectivity(revision: staticRevision, connectivity: connectivity);
      return connectivity;
    });

/// [PlayerView], display-name maps, and map topology — invalidates on game/map/shell
/// changes only (not draft orders).
final developmentPanelStaticContextProvider =
    Provider.autoDispose<DevelopmentPanelStaticContext?>((ref) {
      final game = ref.watch(currentGameProvider);
      final mapData = game == null
          ? null
          : ref.watch(gameServiceProvider).getMapData(game.id);
      if (game == null || mapData == null) return null;
      final staticRevision = developmentPanelStaticSessionRevision(game: game);
      final session = ref.read(developmentPanelSessionCacheProvider).state;
      if (session.staticRevision == staticRevision &&
          session.staticContext != null) {
        return session.staticContext;
      }
      final humanPlayerId = resolveShellPanelPlayerId(
        ref.watch(shellPlayerContextProvider),
        game,
      );
      final staticContext = ctAppPerfSync('developmentPanel.staticContext', () {
        final topology = mapData.combinedTopology;
        return (
          game: game,
          humanPlayerId: humanPlayerId,
          playerView: buildPlayerView(game, topology, humanPlayerId),
          provinceDisplayNamesById: {
            for (final p in allProvinces(game.worldState))
              p.id: p.displayName ?? p.id,
          },
          playerDisplayNamesById: {
            for (final player in game.players) player.id: player.displayName,
          },
          topology: topology,
          tileMapByRegion: mapData.tileMapByRegion,
        );
      });
      ref
          .read(developmentPanelSessionCacheProvider)
          .storeStaticContext(
            revision: staticRevision,
            staticContext: staticContext,
          );
      return staticContext;
    });
