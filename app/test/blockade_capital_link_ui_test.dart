// Blockade capital-link player copy (Refs #4516).

import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_civilian_naval_sections.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_details.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_flow.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_target_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'naval_mission_goldens_test_support.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  group('navalMissionEffectLine (Refs #4516)', () {
    test('Blockade names capital-link cut and interception', () {
      final line = navalMissionEffectLine(l10n, FleetMission.blockade);
      expect(line.toLowerCase(), contains('capital'));
      expect(line.toLowerCase(), contains('warehouse'));
      expect(line.toLowerCase(), contains('intercept'));
    });

    test('target caption names warehouse cut', () {
      final caption = navalMissionTargetCaption(l10n, FleetMission.blockade);
      expect(caption, isNotNull);
      expect(caption!.toLowerCase(), contains('warehouse'));
    });
  });

  group('resolveHumanOwnedBlockadeStatus (Refs #4516)', () {
    test('human-owned blockaded port resolves portBlockaded', () {
      const target = 'oldWorld|enemy1';
      final game = buildNavalMissionHumanOwnedBlockadedPortGame();
      final status = resolveHumanOwnedBlockadeStatus(
        game: game,
        humanPlayerId: navalMissionGoldenHumanId,
        provinceId: target,
        topology: navalMissionWarTopology(),
        isSeaZone: false,
      );
      expect(status, ProvinceBlockadeStatus.portBlockaded);
    });

    test('human-owned blockaded capital resolves capitalBlockaded', () {
      const target = 'oldWorld|enemy1';
      final game = buildNavalMissionHumanOwnedBlockadedPortGame(
        capitalPort: true,
      );
      final status = resolveHumanOwnedBlockadeStatus(
        game: game,
        humanPlayerId: navalMissionGoldenHumanId,
        provinceId: target,
        topology: navalMissionWarTopology(),
        isSeaZone: false,
      );
      expect(status, ProvinceBlockadeStatus.capitalBlockaded);
    });

    test('foreign-owned province resolves none', () {
      const target = 'oldWorld|enemy1';
      final game = buildNavalMissionWarTargetsGame();
      final status = resolveHumanOwnedBlockadeStatus(
        game: game,
        humanPlayerId: navalMissionGoldenHumanId,
        provinceId: target,
        topology: navalMissionWarTopology(),
        isSeaZone: false,
      );
      expect(status, ProvinceBlockadeStatus.none);
    });
  });

  group('buildNavalSection blockade status (Refs #4516)', () {
    testWidgets('shows under blockade line for human-owned blockaded port', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          child: Builder(
            builder: (context) {
              return buildNavalSection(
                l10n: appL10n(context),
                game: buildNavalMissionMenuPeacetimeGame(),
                fleets: const [],
                humanPlayerId: navalMissionGoldenHumanId,
                draftOrders: const Orders(),
                blockadeStatus: ProvinceBlockadeStatus.portBlockaded,
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(find.text(l10n.provinceOverlay_underBlockade), findsOneWidget);
    });

    testWidgets(
      'shows capital under-blockade line for human-owned capital port',
      (tester) async {
        await tester.pumpWidget(
          buildAppShell(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            child: Builder(
              builder: (context) {
                return buildNavalSection(
                  l10n: appL10n(context),
                  game: buildNavalMissionMenuPeacetimeGame(),
                  fleets: const [],
                  humanPlayerId: navalMissionGoldenHumanId,
                  draftOrders: const Orders(),
                  blockadeStatus: ProvinceBlockadeStatus.capitalBlockaded,
                );
              },
            ),
          ),
        );
        await tester.pump();
        expect(
          find.text(l10n.provinceOverlay_underBlockadeCapital),
          findsOneWidget,
        );
      },
    );

    testWidgets('omits status line when not blockaded', (tester) async {
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          child: Builder(
            builder: (context) {
              return buildNavalSection(
                l10n: appL10n(context),
                game: buildNavalMissionMenuPeacetimeGame(),
                fleets: const [],
                humanPlayerId: navalMissionGoldenHumanId,
                draftOrders: const Orders(),
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(find.text(l10n.provinceOverlay_underBlockade), findsNothing);
      expect(
        find.text(l10n.provinceOverlay_underBlockadeCapital),
        findsNothing,
      );
    });
  });

  testWidgets(
    'Blockade target dialog adds capital extra when capital selected',
    (tester) async {
      const enemyCap = 'oldWorld|enemy1';
      final game = buildNavalMissionCapitalPortTargetGame();
      final fleet = game.worldState.fleets.single;

      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          child: NavalMissionTargetDialog(
            game: game,
            mission: FleetMission.blockade,
            fleet: fleet,
            targetProvinceIds: const [enemyCap],
            humanPlayerId: navalMissionGoldenHumanId,
            initialTargetProvinceId: enemyCap,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.naval_mission_blockade_capitalExtra),
        findsOneWidget,
      );
    },
  );
}
