import 'package:flutter/material.dart';

import 'config/routes.dart';
import 'config/themes.dart';

/// Used by macOS menubar (View → Debug log) to push the debug log route.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Colonize This',
      theme: AppThemes.light,
      initialRoute: Routes.shell,
      onGenerateRoute: Routes.generate,
    );
    return PlatformMenuBar(
      menus: <PlatformMenuItem>[
        PlatformMenu(
          label: 'View',
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              label: 'Debug log',
              onSelected: () {
                appNavigatorKey.currentState?.pushNamed(Routes.debugLog);
              },
            ),
          ],
        ),
        if (PlatformProvidedMenuItem.hasMenu(
          PlatformProvidedMenuItemType.quit,
        ))
          const PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.quit,
          ),
      ],
      child: app,
    );
  }
}
