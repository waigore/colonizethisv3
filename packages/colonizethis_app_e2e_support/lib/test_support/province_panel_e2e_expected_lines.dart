// coverage:ignore-file
// E2E test fixture; exercised only by integration_test scenarios (which do not
// run in `flutter test test/`). Pulled into the test isolate's import graph by
// `app/integration_test/e2e_test_shared_panel_text_match.dart` (Refs #2336);
// excluded from the app coverage gate using the same convention as
// `app/lib/widgetbook/catalog*.dart`.
// Expected plain-text lines for ProvinceSeaZoneDetailOverlay wide layout (scroll column).
// Mirrors app/lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart for e2e.
// If drift fails tests, align this file with the overlay widget.

import 'package:colonizethis_data/colonizethis_data.dart'
    show
        CommodityCatalog,
        MapTopology,
        TileMapResult,
        isMilitaryUnit,
        terrainDisplayName;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_panel_labels.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_panel_pending_orders.dart';
import 'package:colonizethis_app/widgets/commodity_display_name.dart';
import 'province_panel_e2e_expected_lines_ctx.dart';
import 'province_panel_e2e_expected_lines_political_tile.dart';
import 'province_panel_e2e_expected_lines_economic.dart';
import 'province_panel_e2e_expected_lines_units.dart';
import 'province_panel_e2e_expected_lines_labels.dart';


/// In-order [Text.data] strings matching depth-first pre-order of the wide-layout panel
/// (section titles and bodies) for a **land** province.
List<String> provincePanelWideLayoutExpectedTexts(
  CtE2eLastPanelSnapshot snap,
  AppLocalizations l10n,
) {
  final ctx = buildProvincePanelWideExpectedCtx(snap);
  final out = <String>['Province', '×'];
  appendProvincePanelPoliticalSection(out, ctx, l10n);
  appendProvincePanelTileSection(out, ctx, l10n);
  appendProvincePanelEconomicSection(out, ctx, l10n);
  appendProvincePanelMilitarySection(out, ctx, l10n);
  appendProvincePanelCivilianSection(out, ctx, l10n);
  appendProvincePanelNavalSection(out, ctx, l10n);
  return out;
}
