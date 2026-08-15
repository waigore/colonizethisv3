part of 'catalog.dart';

List<TileRadialSpokeView> _tileRadialDemoWedges({
  bool exploreEnabled = true,
  bool prospectEnabled = true,
  bool includeBuild = true,
}) {
  return [
    TileRadialSpokeView(
      action: TileRadialCatalogAction.explore,
      enabled: exploreEnabled,
      // ignore: avoid_hardcoded_strings_in_widgets
      label: 'Explore',
      // ignore: avoid_hardcoded_strings_in_widgets
      tooltip: 'Explore with explorer',
    ),
    TileRadialSpokeView(
      action: TileRadialCatalogAction.prospect,
      enabled: prospectEnabled,
      // ignore: avoid_hardcoded_strings_in_widgets
      label: 'Prospect',
      // ignore: avoid_hardcoded_strings_in_widgets
      tooltip: 'Prospect with explorer',
    ),
    if (includeBuild)
      TileRadialSpokeView(
        action: TileRadialCatalogAction.buildImprovement,
        enabled: true,
        // ignore: avoid_hardcoded_strings_in_widgets
        label: 'Build improvement',
        // ignore: avoid_hardcoded_strings_in_widgets
        tooltip: 'Build improvement',
      ),
  ];
}

Widget _tileRadialStoryFrame({
  required Widget child,
  double width = 400,
  double height = 400,
}) {
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    scaffoldBackgroundColor: EditorialMonoclePalette.bgDeep,
    child: SizedBox(width: width, height: height, child: child),
  );
}

/// MAP30001 / MAP30002 stories. SPEC/ui/tile-context-radial.md (Refs #4440).
List<WidgetbookNode> get tileRadialDirectories => [
  WidgetbookFolder(
    name: 'Tile Context Radial',
    children: [
      WidgetbookUseCase(
        name: 'Enabled three wedges',
        builder: (context) => _tileRadialStoryFrame(
          child: TileContextRadial(
            // ignore: avoid_hardcoded_strings_in_widgets
            placeLine: 'Place: Wessex',
            wedges: _tileRadialDemoWedges(),
            onWedge: (_) {},
            onMore: () {},
            onDismiss: () {},
            anchor: const Offset(200, 200),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Prospect enabled Explore disabled',
        builder: (context) => _tileRadialStoryFrame(
          child: TileContextRadial(
            // ignore: avoid_hardcoded_strings_in_widgets
            placeLine: 'Place: Wessex',
            wedges: _tileRadialDemoWedges(exploreEnabled: false),
            onWedge: (_) {},
            onMore: () {},
            onDismiss: () {},
            anchor: const Offset(200, 200),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Empty catalog More-only',
        builder: (context) => _tileRadialStoryFrame(
          child: TileContextRadial(
            // ignore: avoid_hardcoded_strings_in_widgets
            placeLine: 'Place: Mid-Atlantic',
            wedges: const [],
            onWedge: (_) {},
            onMore: () {},
            onDismiss: () {},
            anchor: const Offset(200, 200),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Sea-zone few shortcuts',
        builder: (context) => _tileRadialStoryFrame(
          child: TileContextRadial(
            // ignore: avoid_hardcoded_strings_in_widgets
            placeLine: 'Place: Channel',
            wedges: _tileRadialDemoWedges(includeBuild: false),
            onWedge: (_) {},
            onMore: () {},
            onDismiss: () {},
            anchor: const Offset(200, 200),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: '320 dp clamp',
        builder: (context) => _tileRadialStoryFrame(
          width: 320,
          height: 640,
          child: TileContextRadial(
            // ignore: avoid_hardcoded_strings_in_widgets
            placeLine: 'Place: Wessex',
            wedges: _tileRadialDemoWedges(),
            onWedge: (_) {},
            onMore: () {},
            onDismiss: () {},
            anchor: const Offset(16, 16),
          ),
        ),
      ),
    ],
  ),
  WidgetbookFolder(
    name: 'More Tile Actions',
    children: [
      WidgetbookUseCase(
        name: 'Empty remainder',
        builder: (context) => _tileRadialStoryFrame(
          child: TileMoreActionsDialog(
            // ignore: avoid_hardcoded_strings_in_widgets
            placeLine: 'Place: Wessex',
            remainder: const [],
            onAction: (_) {},
            onProvinceDetails: () {},
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Remainder Prospect',
        builder: (context) => _tileRadialStoryFrame(
          child: TileMoreActionsDialog(
            // ignore: avoid_hardcoded_strings_in_widgets
            placeLine: 'Place: Wessex',
            remainder: _tileRadialDemoWedges(includeBuild: false).sublist(1),
            onAction: (_) {},
            onProvinceDetails: () {},
          ),
        ),
      ),
      WidgetbookUseCase(
        name: '320 dp',
        builder: (context) => _tileRadialStoryFrame(
          width: 320,
          height: 640,
          child: TileMoreActionsDialog(
            // ignore: avoid_hardcoded_strings_in_widgets
            placeLine: 'Place: Wessex',
            remainder: _tileRadialDemoWedges(),
            onAction: (_) {},
            onProvinceDetails: () {},
          ),
        ),
      ),
    ],
  ),
];
