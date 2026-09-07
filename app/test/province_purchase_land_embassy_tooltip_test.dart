// Pins embassy-gated Purchase land tooltip copy (Refs #4739).

import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_overlay_tooltips.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_establish_embassy_shortcut_fixtures.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  test('wide embassy refusal names Embassy and not Political', () {
    final game = buildEstablishEmbassyShortcutGame(
      ownerId: kEstablishEmbassyMinorId,
    );
    final tooltip = provinceOverlayPurchaseLandTooltip(
      l10n: l10n,
      game: game,
      humanPlayerId: kEstablishEmbassyHumanPlayerId,
      currentOrders: const Orders(),
      selectedTileKey: kEstablishEmbassyTileKey,
      provinceId: kEstablishEmbassyProvinceId,
      enabled: false,
      hasMatchingUnits: true,
    );
    expect(tooltip, contains('Embassy'));
    expect(tooltip, isNot(contains('Political')));
    expect(
      tooltip,
      l10n.provinceOverlay_tilePurchaseLandDisabledEmbassyTooltip,
    );
  });

  test('narrow embassy refusal points to Political Establish Embassy', () {
    final game = buildEstablishEmbassyShortcutGame(
      ownerId: kEstablishEmbassyMinorId,
    );
    final tooltip = provinceOverlayPurchaseLandTooltip(
      l10n: l10n,
      game: game,
      humanPlayerId: kEstablishEmbassyHumanPlayerId,
      currentOrders: const Orders(),
      selectedTileKey: kEstablishEmbassyTileKey,
      provinceId: kEstablishEmbassyProvinceId,
      enabled: false,
      hasMatchingUnits: true,
      isNarrow: true,
    );
    expect(
      tooltip,
      l10n.provinceOverlay_tilePurchaseLandDisabledEmbassyNarrowTooltip,
    );
    expect(tooltip, contains('Embassy'));
    expect(tooltip, contains('Political'));
    expect(tooltip, contains('Establish Embassy'));
  });
}
