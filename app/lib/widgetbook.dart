import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'config/themes.dart';
import 'features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'widgets/game_setup.dart';
import 'widgets/main_menu.dart';
import 'features/game/widgets/province_overlay_demo_data.dart';
import 'widgets/debug_init_game.dart';
import 'widgets/region_map_debug.dart';

/// Widgetbook entry point. Run with: flutter run -t lib/widgetbook.dart
void main() {
  runApp(const CtWidgetbookApp());
}

/// Simulated mobile viewport (360×640 dp) for layout verification. SPEC/ui/mobile-adaptation.md.
Widget mobileViewport(BuildContext context, Widget child) {
  const double width = 360;
  const double height = 640;
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(size: Size(width, height)),
    child: SizedBox(
      width: width,
      height: height,
      child: child,
    ),
  );
}

/// Widgetbook app with colonial theme. SPEC/ui/main-menu.md; UXD 03a. SPEC/ui/game-setup.md; UXD 03b. Mobile viewport: SPEC/ui/mobile-adaptation.md.
class CtWidgetbookApp extends StatelessWidget {
  const CtWidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        ...mainMenuDirectories,
        ...gameSetupDirectories,
        ...mapWidgetDirectories,
        ...provinceOverlayDirectories,
      ],
      lightTheme: AppThemes.colonial,
      darkTheme: AppThemes.colonial,
    );
  }
}

/// Main Menu stories (plain and pixel). Register in widget_catalog.json.
List<WidgetbookNode> get mainMenuDirectories => [
      WidgetbookFolder(
        name: 'Main Menu',
        children: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => CtMainMenu(
              variant: MainMenuVariant.plain,
              state: MainMenuState.default_,
              version: 'v1.0.0',
              onNewGame: () {},
              onLoadGame: () {},
              onSettings: () {},
              onQuit: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'After victory',
            builder: (context) => CtMainMenu(
              variant: MainMenuVariant.plain,
              state: MainMenuState.afterVictory,
              version: 'v1.0.0',
              onNewGame: () {},
              onLoadGame: () {},
              onSettings: () {},
              onQuit: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'No saves',
            builder: (context) => CtMainMenu(
              variant: MainMenuVariant.plain,
              state: MainMenuState.noSaves,
              version: 'v1.0.0',
              onNewGame: () {},
              onLoadGame: () {},
              onSettings: () {},
              onQuit: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'Default (pixel)',
            builder: (context) => CtMainMenu(
              variant: MainMenuVariant.pixelArt,
              state: MainMenuState.default_,
              version: 'v1.0.0',
              onNewGame: () {},
              onLoadGame: () {},
              onSettings: () {},
              onQuit: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'After victory (pixel)',
            builder: (context) => CtMainMenu(
              variant: MainMenuVariant.pixelArt,
              state: MainMenuState.afterVictory,
              version: 'v1.0.0',
              onNewGame: () {},
              onLoadGame: () {},
              onSettings: () {},
              onQuit: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'Default (mobile)',
            builder: (context) => mobileViewport(
              context,
              CtMainMenu(
                variant: MainMenuVariant.plain,
                state: MainMenuState.default_,
                version: 'v1.0.0',
                onNewGame: () {},
                onLoadGame: () {},
                onSettings: () {},
                onQuit: () {},
              ),
            ),
          ),
        ],
      ),
    ];

/// All choices unselected on load. SPEC/ui/game-setup.md.
List<String> _unselectedInitialOrderedGpIds() => List.filled(6, '');

/// Game Setup stories. SPEC/ui/game-setup.md; UXD 03b.
List<WidgetbookNode> get gameSetupDirectories => [
      WidgetbookFolder(
        name: 'Game Setup',
        children: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => CtGameSetup(
              variant: GameSetupVariant.plain,
              state: GameSetupState.default_,
              naming: defaultNamingConfig,
              initialOrderedGpIds: _unselectedInitialOrderedGpIds(),
              initialLeaderVariantByGpId: {},
              onStartGame: (_, __) {},
              onBack: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'Loading',
            builder: (context) => CtGameSetup(
              variant: GameSetupVariant.plain,
              state: GameSetupState.loading,
              naming: defaultNamingConfig,
              initialOrderedGpIds: _unselectedInitialOrderedGpIds(),
              initialLeaderVariantByGpId: {},
              onStartGame: (_, __) {},
              onBack: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'Default (pixel)',
            builder: (context) => CtGameSetup(
              variant: GameSetupVariant.pixelArt,
              state: GameSetupState.default_,
              naming: defaultNamingConfig,
              initialOrderedGpIds: _unselectedInitialOrderedGpIds(),
              initialLeaderVariantByGpId: {},
              onStartGame: (_, __) {},
              onBack: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'Loading (pixel)',
            builder: (context) => CtGameSetup(
              variant: GameSetupVariant.pixelArt,
              state: GameSetupState.loading,
              naming: defaultNamingConfig,
              initialOrderedGpIds: _unselectedInitialOrderedGpIds(),
              initialLeaderVariantByGpId: {},
              onStartGame: (_, __) {},
              onBack: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'Default (mobile)',
            builder: (context) => mobileViewport(
              context,
              CtGameSetup(
                variant: GameSetupVariant.plain,
                state: GameSetupState.default_,
                naming: defaultNamingConfig,
                initialOrderedGpIds: _unselectedInitialOrderedGpIds(),
                initialLeaderVariantByGpId: {},
                onStartGame: (_, __) {},
                onBack: () {},
              ),
            ),
          ),
        ],
      ),
    ];

/// Map Widget stories (debug mode). SPEC/ui/map-widget.md.
List<WidgetbookNode> get mapWidgetDirectories => [
      WidgetbookFolder(
        name: 'Map Widget',
        children: [
          WidgetbookUseCase(
            name: 'Debug mode',
            builder: (context) {
              final region = getDebugInitGameResult().mapViewData.oldWorld;
              return SizedBox(
                width: 400,
                height: 320,
                child: CtRegionMapDebug(
                  region: region,
                  showPoliticalOverlay: true,
                  cellSizePx: 28,
                  onProvinceSelected: (id) {},
                ),
              );
            },
          ),
          WidgetbookUseCase(
            name: 'Debug mode (political overlay off)',
            builder: (context) {
              final region = getDebugInitGameResult().mapViewData.oldWorld;
              return SizedBox(
                width: 400,
                height: 320,
                child: CtRegionMapDebug(
                  region: region,
                  showPoliticalOverlay: false,
                  cellSizePx: 28,
                  onProvinceSelected: (id) {},
                ),
              );
            },
          ),
          WidgetbookUseCase(
            name: 'Debug mode (mobile)',
            builder: (context) => mobileViewport(
              context,
              Builder(
                builder: (context) {
                  final region = getDebugInitGameResult().mapViewData.oldWorld;
                  return CtRegionMapDebug(
                    region: region,
                    showPoliticalOverlay: true,
                    cellSizePx: 24,
                    onProvinceSelected: (id) {},
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ];

/// Province/Sea Zone Detail Overlay stories. SPEC/ui/province-sea-zone-detail-overlay.md.
List<WidgetbookNode> get provinceOverlayDirectories => [
      WidgetbookFolder(
        name: 'Province Overlay',
        children: [
          WidgetbookUseCase(
            name: 'Standalone — province',
            builder: (context) {
              final game = demoGameForOverlay;
              final region = demoRegionForOverlay;
              return SizedBox(
                width: 320,
                height: 400,
                child: ProvinceSeaZoneDetailOverlay(
                  game: game,
                  region: region,
                  selectedId: sampleProvinceIdForOverlay,
                  displayId: sampleProvinceIdForOverlay,
                  humanPlayerId: game.players.first.id,
                  onClose: () {},
                ),
              );
            },
          ),
          WidgetbookUseCase(
            name: 'Standalone — sea zone',
            builder: (context) {
              final game = demoGameForOverlay;
              final region = demoRegionForOverlay;
              return SizedBox(
                width: 320,
                height: 280,
                child: ProvinceSeaZoneDetailOverlay(
                  game: game,
                  region: region,
                  selectedId: sampleSeaZoneIdForOverlay,
                  displayId: sampleSeaZoneIdForOverlay,
                  humanPlayerId: game.players.first.id,
                  onClose: () {},
                ),
              );
            },
          ),
          WidgetbookUseCase(
            name: 'Standalone (mobile)',
            builder: (context) => mobileViewport(
              context,
              Builder(
                builder: (context) {
                  final game = demoGameForOverlay;
                  final region = demoRegionForOverlay;
                  return ProvinceSeaZoneDetailOverlay(
                    game: game,
                    region: region,
                    selectedId: sampleProvinceIdForOverlay,
                    displayId: sampleProvinceIdForOverlay,
                    humanPlayerId: game.players.first.id,
                    onClose: () {},
                  );
                },
              ),
            ),
          ),
          WidgetbookUseCase(
            name: 'With map — province selected',
            builder: (context) =>
                _MapWithOverlayStory(selectedId: sampleProvinceIdForOverlay),
          ),
          WidgetbookUseCase(
            name: 'With map — sea zone selected',
            builder: (context) =>
                _MapWithOverlayStory(selectedId: sampleSeaZoneIdForOverlay),
          ),
        ],
      ),
    ];

/// Map + overlay in tandem for Widgetbook. SPEC/ui/province-sea-zone-detail-overlay.md.
class _MapWithOverlayStory extends StatefulWidget {
  const _MapWithOverlayStory({required this.selectedId});

  final String selectedId;

  @override
  State<_MapWithOverlayStory> createState() => _MapWithOverlayStoryState();
}

class _MapWithOverlayStoryState extends State<_MapWithOverlayStory> {
  late String _selectedId;
  String? _hoveredDetailId;
  String? _hoveredTileKey;
  String? _highlightedTileKey;

  String get _displayId {
    if (_hoveredTileKey != null) {
      final parts = _hoveredTileKey!.split('|');
      if (parts.length >= 2) {
        return '${parts[0]}|${parts[1]}';
      }
    }
    return _hoveredDetailId ?? _selectedId;
  }

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
  }

  @override
  void didUpdateWidget(covariant _MapWithOverlayStory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      _selectedId = widget.selectedId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = demoGameForOverlay;
    final region = demoRegionForOverlay;
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    return SizedBox(
      width: 800,
      height: 500,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: CtRegionMapDebug(
              region: region,
              cellSizePx: 28,
              onProvinceSelected: (id) =>
                  setState(() => _selectedId = _selectedId == id ? '' : id),
              onProvinceHovered: (id) => setState(() => _hoveredDetailId = id),
              onTileHovered: (key) => setState(() => _hoveredTileKey = key),
              highlightedTileKey: _highlightedTileKey,
            ),
          ),
          if (!isNarrow && _selectedId.isNotEmpty)
            SizedBox(
              width: 320,
              child: ProvinceSeaZoneDetailOverlay(
                game: game,
                region: region,
                selectedId: _selectedId,
                displayId: _displayId,
                humanPlayerId: 'gp1',
                hoveredTileKey: _hoveredTileKey,
                onHighlightTile: (k) =>
                    setState(() => _highlightedTileKey = k),
                onClose: () => setState(() => _selectedId = ''),
              ),
            ),
        ],
      ),
    );
  }
}
