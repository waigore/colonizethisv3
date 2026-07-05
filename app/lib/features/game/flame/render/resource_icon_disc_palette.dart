import 'package:flutter/material.dart';

/// Optional commodity hue reference generated from resource icons.
/// Region-map extraction throughput discs use fixed gold/brown fills instead
/// (`region_map_component_shared.dart`; SPEC/ui/map-widget.md).
///
/// Regenerate with:
/// `dart run tool/generate_resource_icon_disc_palette.dart`
const Map<String, Color> kResourceIconDiscPalette = <String, Color>{
  'bronze': Color(0xFFF0D040),
  'cast_iron': Color(0xFF9090A0),
  'cigars': Color(0xFF302010),
  'coal': Color(0xFF302040),
  'copper': Color(0xFFE07050),
  'cotton': Color(0xFFF0F0F0),
  'diamonds': Color(0xFFA0E0F0),
  'fabric': Color(0xFFF0E0D0),
  'fur_hats': Color(0xFF503020),
  'furs': Color(0xFF402020),
  'gems': Color(0xFF700080),
  'gold': Color(0xFFF0D060),
  'grain': Color(0xFF503010),
  'horses': Color(0xFF805030),
  'iron': Color(0xFF202030),
  'lumber': Color(0xFF502030),
  'meat': Color(0xFF600030),
  'paper': Color(0xFFE0D090),
  'refined_sugar': Color(0xFFA07050),
  'silver': Color(0xFFF0F0F0),
  'spices': Color(0xFFE0B060),
  'steel': Color(0xFFF0C0D0),
  'sugar_cane': Color(0xFF607000),
  'timber': Color(0xFFA06030),
  'tin': Color(0xFFE0E0F0),
  'tobacco': Color(0xFF302020),
  'wool': Color(0xFFE0D0A0),
};

Color discColorForResourceId(String resourceId) {
  return kResourceIconDiscPalette[resourceId] ?? const Color(0xFF888888);
}
