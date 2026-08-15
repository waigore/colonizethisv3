part of 'catalog.dart';

/// MAP10001 improvement-headroom legend chrome (Refs #4408).
List<WidgetbookNode> get improvementHeadroomLegendDirectories => [
  WidgetbookFolder(
    name: 'Improvement headroom legend',
    children: [
      WidgetbookUseCase(
        name: 'Visible — legend above corner controls',
        builder: (context) => _improvementHeadroomLegendChromeStory(
          flags: MapBaseLayerFlags.fullDetail,
          viewingPlayerId: 'gp_player',
        ),
      ),
      WidgetbookUseCase(
        name: 'Hidden — improvements off',
        builder: (context) => _improvementHeadroomLegendChromeStory(
          flags: MapBaseLayerFlags.resourcesOnly,
          viewingPlayerId: 'gp_player',
        ),
      ),
      WidgetbookUseCase(
        name: 'Hidden — global observe',
        builder: (context) => _improvementHeadroomLegendChromeStory(
          flags: MapBaseLayerFlags.fullDetail,
          viewingPlayerId: null,
        ),
      ),
      WidgetbookUseCase(
        name: '320 dp narrow',
        builder: (context) => _improvementHeadroomLegendChromeStory(
          flags: MapBaseLayerFlags.fullDetail,
          viewingPlayerId: 'gp_player',
          narrow: true,
        ),
      ),
      WidgetbookUseCase(
        name: 'Details panel',
        builder: (context) => widgetbookEditorialMonocleApp(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          scaffoldBackgroundColor: EditorialMonoclePalette.bgDeep,
          child: Builder(
            builder: (BuildContext ctx) {
              final l10n = appL10n(ctx);
              return Center(
                child: SizedBox(
                  width: 280,
                  child: ImprovementHeadroomLegendPanel(
                    l10n: l10n,
                    onClose: () {},
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ],
  ),
];

/// MAP10001 improvement-mark paint variants (Refs #4408).
List<WidgetbookNode> get improvementHeadroomMarkDirectories => [
  WidgetbookFolder(
    name: 'Improvement headroom marks',
    children: [
      WidgetbookUseCase(
        name: 'At cap — muted 1 of 1',
        builder: (context) => ImprovementHeadroomMarkStory(
          region: improvementHeadroomMarkRegion(
            improvementLevel: 1,
            improvementTechCap: 1,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Has headroom — 1 of 2',
        builder: (context) => ImprovementHeadroomMarkStory(
          region: improvementHeadroomMarkRegion(
            improvementLevel: 1,
            improvementTechCap: 2,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Foreign level-only',
        builder: (context) => ImprovementHeadroomMarkStory(
          region: improvementHeadroomMarkRegion(
            improvementLevel: 2,
            ownerFactionId: 'gp2',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Owned hidden-resource level-only',
        builder: (context) => ImprovementHeadroomMarkStory(
          region: improvementHeadroomMarkRegion(
            improvementLevel: 2,
            improvementTechCap: 3,
            resourceId: 'gold',
          ),
          playerConstrained: true,
        ),
      ),
      WidgetbookUseCase(
        name: 'Unimproved unmarked',
        builder: (context) => ImprovementHeadroomMarkStory(
          region: improvementHeadroomMarkRegion(
            improvementLevel: 0,
            improvementTechCap: 1,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Unrevealed hidden',
        builder: (context) => ImprovementHeadroomMarkStory(
          region: improvementHeadroomMarkRegion(
            improvementLevel: 2,
            improvementTechCap: 2,
            visibility: TileVisibility.unrevealed,
          ),
          playerConstrained: true,
        ),
      ),
      WidgetbookUseCase(
        name: 'Improvements off',
        builder: (context) => ImprovementHeadroomMarkStory(
          region: improvementHeadroomMarkRegion(
            improvementLevel: 1,
            improvementTechCap: 1,
          ),
          showImprovements: false,
        ),
      ),
    ],
  ),
];

Widget _improvementHeadroomLegendChromeStory({
  required MapBaseLayerFlags flags,
  required String? viewingPlayerId,
  bool narrow = false,
}) {
  final GlobalKey anchor = GlobalKey();
  return _gameMapCornerControlsStoryFrame(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shouldShowImprovementHeadroomLegend(
          flags: flags,
          viewingPlayerId: viewingPlayerId,
        )) ...[
          ImprovementHeadroomLegend(
            key: anchor,
            narrow: narrow,
            anchorKey: anchor,
            chromeBottomY: 0,
          ),
          const SizedBox(height: 4),
        ],
        GameMapCornerControls(
          onCycleBaseLayerDisplayMode: () {},
          onCenterOnHomeCapital: () {},
          onOpenMapDisplayOptions: () {},
          homeToCapitalEnabled: viewingPlayerId != null,
          mapBaseLayerFlags: flags,
          narrow: narrow,
        ),
      ],
    ),
  );
}
