// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 owner standing / Offer Peace
// stories (Refs #4479).
part of 'catalog.dart';

/// MAP20001 Political owner standing + Offer Peace use cases. Refs #4479.
List<WidgetbookUseCase> get provinceOverlayOwnerStandingUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Political owner standing at war + Offer Peace',
    builder: (context) => _provinceOverlayOwnerStandingStory(
      showStanding: true,
      atWar: true,
      showOfferPeace: true,
      offerPeaceEnabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political owner standing at war Offer Peace disabled',
    builder: (context) => _provinceOverlayOwnerStandingStory(
      showStanding: true,
      atWar: true,
      showOfferPeace: true,
      offerPeaceRejectionReason:
          'Already have a diplomatic order for this faction this turn',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political owner standing at war pending Cancel',
    builder: (context) => _provinceOverlayOwnerStandingStory(
      showStanding: true,
      atWar: true,
      showOfferPeace: true,
      offerPeaceEnabled: true,
      offerPeacePending: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political owner standing at peace',
    builder: (context) =>
        _provinceOverlayOwnerStandingStory(showStanding: true),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political owner standing + ALLIANCE',
    builder: (context) => _provinceOverlayOwnerStandingStory(
      showStanding: true,
      showAlliance: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political owner standing hidden (own)',
    builder: (context) =>
        _provinceOverlayOwnerStandingStory(showStanding: false),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political owner standing 320 dp',
    builder: (context) => SizedBox(
      width: 320,
      height: 640,
      child: _provinceOverlayOwnerStandingStory(
        showStanding: true,
        atWar: true,
        showOfferPeace: true,
        offerPeaceEnabled: true,
      ),
    ),
  ),
];

Widget _provinceOverlayOwnerStandingStory({
  required bool showStanding,
  bool atWar = false,
  bool showAlliance = false,
  bool showOfferPeace = false,
  bool offerPeaceEnabled = false,
  bool offerPeacePending = false,
  String? offerPeaceRejectionReason,
}) {
  final game = demoGameForOverlay;
  return SizedBox(
    width: 640,
    height: 520,
    child: ProvinceSeaZoneDetailOverlay(
      game: game,
      region: demoRegionForOverlay,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      humanPlayerId: game.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      showOwnerStanding: showStanding,
      ownerStandingAtWar: atWar,
      showOwnerAllianceBadge: showAlliance,
      showOfferPeaceControl: showOfferPeace,
      offerPeaceEnabled: offerPeaceEnabled,
      offerPeacePending: offerPeacePending,
      offerPeaceRejectionReason: offerPeaceRejectionReason,
      onOfferPeaceTap: () {},
      onClose: () {},
    ),
  );
}
