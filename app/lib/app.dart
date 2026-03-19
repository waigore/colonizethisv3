import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:colonizethis_app/l10n/app_localizations.dart';
import 'package:colonizethis_app/l10n/l10n.dart';

import 'config/routes.dart';
import 'config/themes.dart';

/// Used by macOS menubar (View → Debug log) to push the debug log route.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final rootL10n = lookupAppLocalizations(const Locale('en'));
    final app = MaterialApp(
      navigatorKey: appNavigatorKey,
      onGenerateTitle: (context) => appL10n(context).app_title,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppThemes.light,
      initialRoute: Routes.shell,
      onGenerateRoute: Routes.generate,
    );
    return PlatformMenuBar(
      menus: <PlatformMenuItem>[
        PlatformMenu(
          label: rootL10n.menu_view,
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              label: rootL10n.menu_debugLog,
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
