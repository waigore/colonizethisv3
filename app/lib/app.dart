import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/config/app_display_strings.dart';
import 'package:colonizethis_app/config/desktop_window_settings.dart';
import 'package:colonizethis_app/providers/settings_provider.dart';

import 'config/routes.dart';
import 'config/themes.dart';

/// Used by macOS menubar (View → Debug log) to push the debug log route.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rootL10n = lookupAppLocalizations(const Locale('en'));
    final settings = ref.watch(settingsProvider);
    final startupMaximized =
        settings[DesktopWindowSettingsKeys.startupMaximized] as bool? ?? true;
    final isDesktopMenuPlatform =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows);
    final app = MaterialApp(
      navigatorKey: appNavigatorKey,
      onGenerateTitle: (context) =>
          formatDebugAwareTitle(appL10n(context).app_title),
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
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
                AppEventBus().emit(const NavigateToRouteEvent(Routes.debugLog));
              },
            ),
            if (isDesktopMenuPlatform)
              PlatformMenuItem(
                label:
                    '${rootL10n.menu_openMaximizedOnStartup}: ${startupMaximized ? rootL10n.common_on : rootL10n.common_off}',
                onSelected: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setValue(
                        DesktopWindowSettingsKeys.startupMaximized,
                        !startupMaximized,
                      );
                },
              ),
          ],
        ),
        if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.quit))
          const PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.quit,
          ),
      ],
      child: app,
    );
  }
}
