/// Pins the SPEC `Architecture and wiring` contract for
/// `ProvinceSeaZoneDetailOverlay`
/// (`SPEC/ui/province-sea-zone-detail-overlay.md` § Architecture and wiring;
/// issue #2865 § Architecture and wiring ACs).
///
/// The overlay must remain a presentation-only widget that:
/// 1. Does **not** import the Flame map widget (`CtRegionMap`) directly, and
/// 2. Does **not** read `mapProvincePanelProvider` itself — the panel hosts
///    (`GameMapProvinceDetailSidePanel`, `GameMapNarrowDetailOverlay*`) bridge
///    the provider state through plain constructor parameters
///    (`displayId`, `selectedTileKey`, `playerView`, `draftOrders`).
///
/// Conversely, `CtRegionMap` must **not** import the overlay; the Flame map
/// surface and the overlay live in independent feature folders and must not
/// cross-couple.
///
/// These contracts are already satisfied by the current code; this test layer
/// pins them so a future refactor that re-introduces either direction of the
/// cross-import (or sneaks the provider read back into the overlay's library)
/// fails in `flutter test test/` before it can land on `dev`.
///
/// Refs GitHub #2865 § Architecture and wiring (S1).
library;

import 'dart:io';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _overlayRelativePath =
    'lib/features/game/widgets/province_sea_zone_detail_overlay.dart';

const String _overlaySectionsRelativePath =
    'lib/features/game/widgets/province_sea_zone_detail_overlay_sections.dart';

const String _overlayEconomicMilitaryRelativePath =
    'lib/features/game/widgets/province_sea_zone_detail_overlay_economic_military_sections.dart';

const String _ctRegionMapRelativePath = 'lib/widgets/ct_region_map.dart';

const String _sidePanelHostRelativePath =
    'lib/features/game/flame/game_map_province_detail_side_panel.dart';

const String _narrowOverlayHostRelativePath =
    'lib/features/game/flame/game_map_narrow_detail_overlay.dart';

/// Matches any `import` line that pulls in `ct_region_map.dart` (relative or
/// package import). The overlay must never import the Flame map widget per
/// SPEC § Architecture and wiring.
final RegExp _ctRegionMapImportPattern = RegExp(
  r'''^\s*import\s+['"][^'"]*ct_region_map\.dart['"]''',
  multiLine: true,
);

/// Matches any `import` line that pulls in `map_province_panel_provider.dart`.
/// The overlay must never import the panel provider; it must receive
/// `displayId`, `selectedTileKey`, `playerView`, and `draftOrders` through
/// constructor parameters from the host widgets.
final RegExp _mapProvincePanelProviderImportPattern = RegExp(
  r'''^\s*import\s+['"][^'"]*map_province_panel_provider\.dart['"]''',
  multiLine: true,
);

/// Matches any `import` line that pulls in
/// `province_sea_zone_detail_overlay.dart`. `CtRegionMap` must never import
/// the overlay per SPEC § Architecture and wiring.
final RegExp _overlayImportPattern = RegExp(
  r'''^\s*import\s+['"][^'"]*province_sea_zone_detail_overlay\.dart['"]''',
  multiLine: true,
);

List<File> _appSourceCandidates(String relativePath) {
  final repoRoot = Directory.current.path;
  // `flutter test` runs from the `app/` directory; the fallback path traversals
  // keep the pin runnable from either the repo root or the `app/` directory
  // without requiring a custom test runner invocation.
  return <File>[
    File('$repoRoot/$relativePath'),
    File('$repoRoot/app/$relativePath'),
    File('$repoRoot/../$relativePath'),
  ];
}

String _readAppSource(String relativePath) {
  for (final file in _appSourceCandidates(relativePath)) {
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  fail(
    'Could not locate app source at any of: '
    '${_appSourceCandidates(relativePath).map((f) => f.path).join(', ')}. '
    'The architecture pin must read the on-disk library to enforce '
    'SPEC § Architecture and wiring (Refs #2865 S1).',
  );
}

String _stripDartComments(String source) {
  // Strip block + line comments so dartdoc/inline references to the forbidden
  // import targets (for example a doc comment saying "do not import
  // ct_region_map.dart") cannot trigger the structural guard. Only live import
  // declarations should match.
  return source
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay does not import the Flame map widget',
    () {
      test(
        '$_overlayRelativePath contains no import of ct_region_map.dart',
        () {
          final code = _stripDartComments(_readAppSource(_overlayRelativePath));
          final matches = _ctRegionMapImportPattern
              .allMatches(code)
              .map((m) => m.group(0)?.trim())
              .toList(growable: false);
          expect(
            matches,
            isEmpty,
            reason:
                '$_overlayRelativePath must not import `ct_region_map.dart`. '
                'SPEC/ui/province-sea-zone-detail-overlay.md § Architecture and '
                'wiring requires the overlay to remain decoupled from the '
                'Flame map widget; bridge via panel hosts and the '
                '`mapProvincePanelProvider` (Refs #2865 S1). '
                'Forbidden import lines found: $matches.',
          );
        },
      );

      // The two `part`-files for the overlay library share the parent's
      // import directives by Dart language rules — they cannot declare their
      // own imports — but a refactor could turn them into stand-alone libraries
      // and re-introduce the forbidden import there. The structural pin guards
      // against that regression shape by asserting the same property on the
      // current part-file paths.
      test(
        '$_overlaySectionsRelativePath contains no import of ct_region_map.dart',
        () {
          final code = _stripDartComments(
            _readAppSource(_overlaySectionsRelativePath),
          );
          final matches = _ctRegionMapImportPattern
              .allMatches(code)
              .map((m) => m.group(0)?.trim())
              .toList(growable: false);
          expect(
            matches,
            isEmpty,
            reason:
                '$_overlaySectionsRelativePath must not import '
                '`ct_region_map.dart`. Even if this file is converted from a '
                'part-of fragment into a stand-alone library, the SPEC '
                'no-cross-import contract remains in force (Refs #2865 S1). '
                'Forbidden import lines found: $matches.',
          );
        },
      );

      test(
        '$_overlayEconomicMilitaryRelativePath contains no import of '
        'ct_region_map.dart',
        () {
          final code = _stripDartComments(
            _readAppSource(_overlayEconomicMilitaryRelativePath),
          );
          final matches = _ctRegionMapImportPattern
              .allMatches(code)
              .map((m) => m.group(0)?.trim())
              .toList(growable: false);
          expect(
            matches,
            isEmpty,
            reason:
                '$_overlayEconomicMilitaryRelativePath must not import '
                '`ct_region_map.dart`. Even if this file is converted from a '
                'part-of fragment into a stand-alone library, the SPEC '
                'no-cross-import contract remains in force (Refs #2865 S1). '
                'Forbidden import lines found: $matches.',
          );
        },
      );
    },
  );

  group('ProvinceSeaZoneDetailOverlay does not import mapProvincePanelProvider',
      () {
    test(
      '$_overlayRelativePath contains no import of map_province_panel_provider.dart',
      () {
        final code = _stripDartComments(_readAppSource(_overlayRelativePath));
        final matches = _mapProvincePanelProviderImportPattern
            .allMatches(code)
            .map((m) => m.group(0)?.trim())
            .toList(growable: false);
        expect(
          matches,
          isEmpty,
          reason:
              '$_overlayRelativePath must not import '
              '`map_province_panel_provider.dart`. SPEC/ui/province-sea-zone-'
              'detail-overlay.md § Architecture and wiring requires the '
              'overlay to read `displayId`, `selectedTileKey`, `playerView`, '
              'and `draftOrders` from constructor parameters supplied by the '
              'panel hosts (Refs #2865 S1). Forbidden import lines found: '
              '$matches.',
        );
      },
    );

    test(
      '$_overlaySectionsRelativePath contains no import of '
      'map_province_panel_provider.dart',
      () {
        final code = _stripDartComments(
          _readAppSource(_overlaySectionsRelativePath),
        );
        final matches = _mapProvincePanelProviderImportPattern
            .allMatches(code)
            .map((m) => m.group(0)?.trim())
            .toList(growable: false);
        expect(
          matches,
          isEmpty,
          reason:
              '$_overlaySectionsRelativePath must not import '
              '`map_province_panel_provider.dart`. The provider belongs to '
              'panel hosts only (Refs #2865 S1). Forbidden import lines '
              'found: $matches.',
        );
      },
    );

    test(
      '$_overlayEconomicMilitaryRelativePath contains no import of '
      'map_province_panel_provider.dart',
      () {
        final code = _stripDartComments(
          _readAppSource(_overlayEconomicMilitaryRelativePath),
        );
        final matches = _mapProvincePanelProviderImportPattern
            .allMatches(code)
            .map((m) => m.group(0)?.trim())
            .toList(growable: false);
        expect(
          matches,
          isEmpty,
          reason:
              '$_overlayEconomicMilitaryRelativePath must not import '
              '`map_province_panel_provider.dart`. The provider belongs to '
              'panel hosts only (Refs #2865 S1). Forbidden import lines '
              'found: $matches.',
        );
      },
    );
  });

  group('CtRegionMap does not import ProvinceSeaZoneDetailOverlay', () {
    test(
      '$_ctRegionMapRelativePath contains no import of '
      'province_sea_zone_detail_overlay.dart',
      () {
        final code = _stripDartComments(
          _readAppSource(_ctRegionMapRelativePath),
        );
        final matches = _overlayImportPattern
            .allMatches(code)
            .map((m) => m.group(0)?.trim())
            .toList(growable: false);
        expect(
          matches,
          isEmpty,
          reason:
              '$_ctRegionMapRelativePath must not import '
              '`province_sea_zone_detail_overlay.dart`. SPEC/ui/province-sea-'
              'zone-detail-overlay.md § Architecture and wiring keeps the '
              'Flame map widget and the overlay decoupled in both directions '
              '(Refs #2865 S1). Forbidden import lines found: $matches.',
        );
      },
    );
  });

  group('Panel hosts bridge mapProvincePanelProvider → overlay', () {
    test(
      '$_sidePanelHostRelativePath imports both '
      'map_province_panel_provider.dart and '
      'province_sea_zone_detail_overlay.dart',
      () {
        final code = _stripDartComments(
          _readAppSource(_sidePanelHostRelativePath),
        );
        final providerMatches = _mapProvincePanelProviderImportPattern
            .allMatches(code)
            .map((m) => m.group(0)?.trim())
            .toList(growable: false);
        final overlayMatches = _overlayImportPattern
            .allMatches(code)
            .map((m) => m.group(0)?.trim())
            .toList(growable: false);
        expect(
          providerMatches,
          isNotEmpty,
          reason:
              '$_sidePanelHostRelativePath must import '
              '`map_province_panel_provider.dart` so the wide-layout host '
              'reads the provider and projects it into constructor '
              'parameters for the overlay (SPEC § Architecture and wiring, '
              'Refs #2865 S1).',
        );
        expect(
          overlayMatches,
          isNotEmpty,
          reason:
              '$_sidePanelHostRelativePath must import '
              '`province_sea_zone_detail_overlay.dart` so the host can '
              'instantiate the overlay (SPEC § Architecture and wiring, '
              'Refs #2865 S1).',
        );
      },
    );

    test(
      '$_narrowOverlayHostRelativePath imports both '
      'map_province_panel_provider.dart and '
      'province_sea_zone_detail_overlay.dart',
      () {
        final code = _stripDartComments(
          _readAppSource(_narrowOverlayHostRelativePath),
        );
        final providerMatches = _mapProvincePanelProviderImportPattern
            .allMatches(code)
            .map((m) => m.group(0)?.trim())
            .toList(growable: false);
        final overlayMatches = _overlayImportPattern
            .allMatches(code)
            .map((m) => m.group(0)?.trim())
            .toList(growable: false);
        expect(
          providerMatches,
          isNotEmpty,
          reason:
              '$_narrowOverlayHostRelativePath must import '
              '`map_province_panel_provider.dart` so the narrow-shell host '
              'reads the provider and projects it into constructor '
              'parameters for the overlay (SPEC § Architecture and wiring, '
              'Refs #2865 S1).',
        );
        expect(
          overlayMatches,
          isNotEmpty,
          reason:
              '$_narrowOverlayHostRelativePath must import '
              '`province_sea_zone_detail_overlay.dart` so the host can '
              'instantiate the overlay (SPEC § Architecture and wiring, '
              'Refs #2865 S1).',
        );
      },
    );
  });
}
