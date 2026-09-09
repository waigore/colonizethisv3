// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP30001 / MAP30002 Train {type} (Refs #4752).
part of 'catalog.dart';

const String _trainExplorerMissingUnitLabel = 'Train Explorer';
const String _trainExplorerMissingUnitGist =
    'A new Explorer appears at your capital after Next turn. This does not assign Explore or Prospect on this tile.';

TileRadialSpokeView _trainExplorerMissingUnitSpoke() {
  return const TileRadialSpokeView(
    action: TileRadialCatalogAction.explore,
    enabled: true,
    label: _trainExplorerMissingUnitLabel,
    tooltip: _trainExplorerMissingUnitLabel,
    caption: _trainExplorerMissingUnitGist,
  );
}

/// MAP30001 **Train Explorer missing-unit**. Refs #4752.
List<WidgetbookUseCase> get tileRadialTrainCivilianUseCases => [
  WidgetbookUseCase(
    name: 'Train Explorer missing-unit',
    builder: (context) => _tileRadialStoryFrame(
      child: TileContextRadial(
        // ignore: avoid_hardcoded_strings_in_widgets
        placeLine: 'Place: Wessex',
        wedges: [_trainExplorerMissingUnitSpoke()],
        onWedge: (_) {},
        onMore: () {},
        onDismiss: () {},
        anchor: const Offset(200, 200),
      ),
    ),
  ),
];

/// MAP30002 **Train Explorer missing-unit**. Refs #4752.
List<WidgetbookUseCase> get tileMoreActionsTrainCivilianUseCases => [
  WidgetbookUseCase(
    name: 'Train Explorer missing-unit',
    builder: (context) => _tileRadialStoryFrame(
      child: TileMoreActionsDialog(
        // ignore: avoid_hardcoded_strings_in_widgets
        placeLine: 'Place: Wessex',
        remainder: [_trainExplorerMissingUnitSpoke()],
        onAction: (_) {},
        onProvinceDetails: () {},
      ),
    ),
  ),
];
