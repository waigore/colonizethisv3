import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'config/themes.dart';
import 'widgets/game_setup.dart';
import 'widgets/main_menu.dart';

/// Widgetbook entry point. Run with: flutter run -t lib/widgetbook.dart
void main() {
  runApp(const CtWidgetbookApp());
}

/// Widgetbook app with colonial theme. SPEC/ui/main-menu.md; UXD 03a. SPEC/ui/game-setup.md; UXD 03b.
class CtWidgetbookApp extends StatelessWidget {
  const CtWidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [...mainMenuDirectories, ...gameSetupDirectories],
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
        ],
      ),
    ];
