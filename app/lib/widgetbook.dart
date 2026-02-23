import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'config/themes.dart';
import 'widgets/main_menu.dart';

/// Widgetbook entry point. Run with: flutter run -t lib/widgetbook.dart
void main() {
  runApp(const CtWidgetbookApp());
}

/// Widgetbook app with colonial theme. SPEC/ui/main-menu.md; UXD 03a.
class CtWidgetbookApp extends StatelessWidget {
  const CtWidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: mainMenuDirectories,
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
