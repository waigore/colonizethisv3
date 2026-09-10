// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Grant Aid / Set Subsidy
// overlay stories (Refs #4761).
part of 'catalog.dart';

const String _grantSubsidyTreasuryReason =
    'Insufficient treasury for GrantAid (need 1000)';

/// MAP20001 Political **Grant Aid** / **Set Subsidy** use cases. Refs #4761.
List<WidgetbookUseCase> get provinceOverlayGrantSubsidyUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Political Grant Aid Set Subsidy enabled',
    builder: (context) => _provinceOverlayGrantSubsidyStory(
      showGrant: true,
      grantEnabled: true,
      showSubsidy: true,
      subsidyEnabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Grant Aid disabled',
    builder: (context) => _provinceOverlayGrantSubsidyStory(
      showGrant: true,
      grantEnabled: false,
      grantReason: _grantSubsidyTreasuryReason,
      showSubsidy: true,
      subsidyEnabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Grant Aid pending',
    builder: (context) => _provinceOverlayGrantSubsidyStory(
      showGrant: true,
      grantEnabled: true,
      grantPending: true,
      showSubsidy: true,
      subsidyEnabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Set Subsidy pending',
    builder: (context) => _provinceOverlayGrantSubsidyStory(
      showGrant: true,
      grantEnabled: true,
      showSubsidy: true,
      subsidyEnabled: true,
      subsidyPending: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Grant Aid Set Subsidy hidden',
    builder: (context) => _provinceOverlayGrantSubsidyStory(
      showGrant: false,
      grantEnabled: false,
      showSubsidy: false,
      subsidyEnabled: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Grant Aid Set Subsidy 320 dp',
    builder: (context) => _provinceOverlayGrantSubsidyStory(
      showGrant: true,
      grantEnabled: false,
      grantReason: _grantSubsidyTreasuryReason,
      showSubsidy: true,
      subsidyEnabled: true,
      showStanding: true,
      width: 320,
      height: 640,
    ),
  ),
];

Widget _provinceOverlayGrantSubsidyStory({
  required bool showGrant,
  required bool grantEnabled,
  bool grantPending = false,
  String? grantReason,
  required bool showSubsidy,
  required bool subsidyEnabled,
  bool subsidyPending = false,
  bool showStanding = false,
  double width = 640,
  double height = 520,
}) {
  final game = demoGameForOverlay;
  return SizedBox(
    width: width,
    height: height,
    child: ProvinceSeaZoneDetailOverlay(
      game: game,
      region: demoRegionForOverlay,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      humanPlayerId: game.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      showOwnerStanding: showStanding,
      grantSubsidy: (
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
      ),
      onClose: () {},
    ),
  );
}
