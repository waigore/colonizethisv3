// Scenario table + fixtures for Grant Aid / Set Subsidy goldens (Refs #4761).

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_grant_subsidy_props.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'province_establish_embassy_shortcut_goldens_cases.dart';

const String provinceGrantSubsidyGoldenTreasuryReason =
    'Insufficient treasury for GrantAid (need 1000)';

class ProvinceGrantSubsidyGoldenCase {
  const ProvinceGrantSubsidyGoldenCase({
    required this.name,
    required this.goldenFile,
    required this.props,
  });

  final String name;
  final String goldenFile;
  final ProvinceOverlayGrantSubsidyProps props;
}

ProvinceOverlayGrantSubsidyProps grantSubsidyGoldenProps({
  bool showGrant = true,
  bool grantEnabled = true,
  bool grantPending = false,
  String? grantReason,
  bool showSubsidy = true,
  bool subsidyEnabled = true,
  bool subsidyPending = false,
}) => (
  showGrantAid: showGrant,
  grantAidEnabled: grantEnabled,
  grantAidPending: grantPending,
  grantAidRejectionReason: grantReason,
  onGrantAidTap: () {},
  showSetSubsidy: showSubsidy,
  setSubsidyEnabled: subsidyEnabled,
  setSubsidyPending: subsidyPending,
  setSubsidyRejectionReason: null,
  onSetSubsidyTap: () {},
);

final List<ProvinceGrantSubsidyGoldenCase> provinceGrantSubsidyWideCases = [
  ProvinceGrantSubsidyGoldenCase(
    name: 'Grant Aid Set Subsidy enabled',
    goldenFile: 'goldens/province_grant_subsidy_enabled.png',
    props: grantSubsidyGoldenProps(),
  ),
  ProvinceGrantSubsidyGoldenCase(
    name: 'Grant Aid disabled treasury',
    goldenFile: 'goldens/province_grant_subsidy_grant_disabled.png',
    props: grantSubsidyGoldenProps(
      grantEnabled: false,
      grantReason: provinceGrantSubsidyGoldenTreasuryReason,
    ),
  ),
  ProvinceGrantSubsidyGoldenCase(
    name: 'Grant Aid pending',
    goldenFile: 'goldens/province_grant_subsidy_grant_pending.png',
    props: grantSubsidyGoldenProps(grantPending: true),
  ),
  ProvinceGrantSubsidyGoldenCase(
    name: 'Set Subsidy pending',
    goldenFile: 'goldens/province_grant_subsidy_subsidy_pending.png',
    props: grantSubsidyGoldenProps(subsidyPending: true),
  ),
  ProvinceGrantSubsidyGoldenCase(
    name: 'Grant Aid Set Subsidy hidden',
    goldenFile: 'goldens/province_grant_subsidy_hidden.png',
    props: grantSubsidyGoldenProps(
      showGrant: false,
      grantEnabled: false,
      showSubsidy: false,
      subsidyEnabled: false,
    ),
  ),
];

Future<void> pumpProvinceGrantSubsidyGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size surface,
  required Size overlaySize,
  required ProvinceGrantSubsidyGoldenCase c,
}) async {
  await configureGoldenSurface(tester, size: surface);
  configureGoldenView(tester, physicalSize: surface, devicePixelRatio: 1.0);
  final game = provinceEmbassyGoldenMinorOwnedGame();
  await tester.pumpWidget(
    wrapGoldenBoundary(
      boundaryKey: boundaryKey,
      includeLocalizations: true,
      child: SizedBox(
        width: overlaySize.width,
        height: overlaySize.height,
        child: ProvinceSeaZoneDetailOverlay(
          game: game,
          region: provinceEmbassyGoldenRegion(),
          displayId: provinceEmbassyGoldenProvinceId,
          selectedTileKey: provinceEmbassyGoldenTileKey,
          humanPlayerId: provinceEmbassyGoldenHumanId,
          playerView: buildPlayerView(
            game,
            const MapTopology(),
            provinceEmbassyGoldenHumanId,
          ),
          omniscientDetail: true,
          showOwnerStanding: true,
          grantSubsidy: c.props,
          onClose: () {},
        ),
      ),
    ),
  );
  await pumpForGolden(tester);
}

void assertProvinceGrantSubsidyControl(
  WidgetTester tester,
  ProvinceGrantSubsidyGoldenCase c,
  AppLocalizationsEn l10n,
) {
  final grant = find.widgetWithText(
    CtActionTextButton,
    l10n.provinceOverlay_grantAidAction,
  );
  final subsidy = find.widgetWithText(
    CtActionTextButton,
    l10n.provinceOverlay_setSubsidyAction,
  );
  final cancel = find.widgetWithText(
    CtActionTextButton,
    l10n.provinceOverlay_cancelGrantAidAction,
  );
  if (!c.props.showGrantAid && !c.props.showSetSubsidy) {
    expect(grant, findsNothing);
    expect(subsidy, findsNothing);
    return;
  }
  if (c.props.grantAidPending) {
    expect(cancel, findsOneWidget);
  } else if (c.props.showGrantAid) {
    expect(grant, findsOneWidget);
    expect(
      tester.widget<CtActionTextButton>(grant).enabled,
      c.props.grantAidEnabled,
    );
  }
  if (c.props.showSetSubsidy && !c.props.setSubsidyPending) {
    expect(subsidy, findsOneWidget);
  }
}
