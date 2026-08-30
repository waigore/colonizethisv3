/// Shared source-scan helpers for MAP20001 architecture pins (Refs #2865, #4642).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String kOverlayRelativePath =
    'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';

const List<String> kOverlaySectionsPartRelativePaths = <String>[
  'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_support.dart',
  'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_sections_political.dart',
  'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_sections_economic_labels.dart',
];

const String kOverlayEconomicSectionRelativePath =
    'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_economic_section.dart';

const String kOverlayMilitarySectionRelativePath =
    'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_military_section.dart';

const String kOverlayCivilianNavalSectionsRelativePath =
    'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_civilian_naval_sections.dart';

const String kOverlayCloseButtonRelativePath =
    'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_close_button.dart';

const List<String> kOverlayEconomicUnitPartRelativePaths = <String>[
  kOverlayEconomicSectionRelativePath,
  kOverlayMilitarySectionRelativePath,
  kOverlayCivilianNavalSectionsRelativePath,
  kOverlayCloseButtonRelativePath,
];

const String kCtRegionMapRelativePath = 'lib/widgets/ct_region_map.dart';

const String kSidePanelHostRelativePath =
    'lib/features/game/flame/overlays/game_map_province_detail_side_panel.dart';

const String kNarrowOverlayHostRelativePath =
    'lib/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';

final RegExp ctRegionMapImportPattern = RegExp(
  r'''^\s*import\s+['"][^'"]*ct_region_map\.dart['"]''',
  multiLine: true,
);

final RegExp mapProvincePanelProviderImportPattern = RegExp(
  r'''^\s*import\s+['"][^'"]*map_province_panel_provider\.dart['"]''',
  multiLine: true,
);

final RegExp overlayImportPattern = RegExp(
  r'''^\s*import\s+['"][^'"]*province_sea_zone_detail_overlay\.dart['"]''',
  multiLine: true,
);

List<File> overlayArchitectureSourceCandidates(String relativePath) {
  final repoRoot = Directory.current.path;
  return <File>[
    File('$repoRoot/$relativePath'),
    File('$repoRoot/app/$relativePath'),
    File('$repoRoot/../$relativePath'),
  ];
}

String readOverlayArchitectureSource(String relativePath) {
  for (final file in overlayArchitectureSourceCandidates(relativePath)) {
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  fail(
    'Could not locate app source at any of: '
    '${overlayArchitectureSourceCandidates(relativePath).map((f) => f.path).join(', ')}. '
    'The architecture pin must read the on-disk library to enforce '
    'SPEC § Architecture and wiring (Refs #2865 S1).',
  );
}

String stripOverlayArchitectureComments(String source) {
  return source
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
}

void expectNoImportMatches({
  required String relativePath,
  required RegExp pattern,
  required String reason,
}) {
  final code = stripOverlayArchitectureComments(
    readOverlayArchitectureSource(relativePath),
  );
  final matches = pattern
      .allMatches(code)
      .map((m) => m.group(0)?.trim())
      .toList(growable: false);
  expect(
    matches,
    isEmpty,
    reason: '$reason Forbidden import lines found: $matches.',
  );
}
