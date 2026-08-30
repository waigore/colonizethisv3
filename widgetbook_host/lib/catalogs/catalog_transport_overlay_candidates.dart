// coverage:ignore-file
// Dev-only Widgetbook catalog part (Refs #1819).
part of 'catalog.dart';

/// Candidate road/rail atlas review surface — Widgetbook host only.
///
/// Does not retarget production `transport_tilesets` or
/// [TransportOverlayTilesetCache] defaults.
List<WidgetbookNode> get transportOverlayCandidatesDirectories => [
  WidgetbookFolder(
    name: 'Transport Overlay Candidates',
    children: [
      WidgetbookUseCase(
        name: 'Road — mask grid (candidate)',
        builder: (context) => widgetbookEditorialMonocleApp(
          child: const TransportOverlayCandidateMaskGrid(
            family: TransportOverlayPreviewFamily.road,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Rail — mask grid (candidate)',
        builder: (context) => widgetbookEditorialMonocleApp(
          child: const TransportOverlayCandidateMaskGrid(
            family: TransportOverlayPreviewFamily.rail,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Road — network joins (candidate)',
        builder: (context) => widgetbookEditorialMonocleApp(
          child: const TransportOverlayCandidateNetworkJoins(
            family: TransportOverlayPreviewFamily.road,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Rail — network joins (candidate)',
        builder: (context) => widgetbookEditorialMonocleApp(
          child: const TransportOverlayCandidateNetworkJoins(
            family: TransportOverlayPreviewFamily.rail,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Road — shipped vs candidate',
        builder: (context) => widgetbookEditorialMonocleApp(
          child: const TransportOverlayCandidateCompare(
            family: TransportOverlayPreviewFamily.road,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Rail — shipped vs candidate',
        builder: (context) => widgetbookEditorialMonocleApp(
          child: const TransportOverlayCandidateCompare(
            family: TransportOverlayPreviewFamily.rail,
          ),
        ),
      ),
    ],
  ),
];
