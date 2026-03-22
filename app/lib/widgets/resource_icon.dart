import 'package:flutter/material.dart';

import '../config/app_assets.dart';
import 'strict_asset_icon.dart';

class ResourceIcon extends StatelessWidget {
  const ResourceIcon({super.key, required this.commodityId, this.size = 16});

  final String commodityId;
  final double size;

  static const Map<String, String> _commodityIconPaths = {
    'grain': 'ui_icon_com_grain.png',
    'meat': 'ui_icon_com_meat.png',
    'timber': 'ui_icon_com_timber.png',
    'iron': 'ui_icon_com_iron.png',
    'wool': 'ui_icon_com_wool.png',
    'cotton': 'ui_icon_com_cotton.png',
    'coal': 'ui_icon_com_coal.png',
    'sugarCane': 'ui_icon_com_sugar_cane.png',
    'tobacco': 'ui_icon_com_tobacco.png',
    'furs': 'ui_icon_com_furs.png',
    'copper': 'ui_icon_com_copper.png',
    'tin': 'ui_icon_com_tin.png',
    'horses': 'ui_icon_com_horses.png',
    'lumber': 'ui_icon_com_lumber.png',
    'castIron': 'ui_icon_com_cast_iron.png',
    'fabric': 'ui_icon_com_fabric.png',
    'refinedSugar': 'ui_icon_com_refined_sugar.png',
    'cigars': 'ui_icon_com_cigars.png',
    'furHats': 'ui_icon_com_fur_hats.png',
    'steel': 'ui_icon_com_steel.png',
    'paper': 'ui_icon_com_paper.png',
    'bronze': 'ui_icon_com_bronze.png',
    'gold': 'ui_icon_com_gold.png',
    'silver': 'ui_icon_com_silver.png',
    'gems': 'ui_icon_com_gems.png',
    'diamonds': 'ui_icon_com_diamonds.png',
    'spices': 'ui_icon_com_spices.png',
  };

  static String? getIconPath(String commodityId) {
    return _commodityIconPaths[commodityId];
  }

  static bool hasIcon(String commodityId) {
    return _commodityIconPaths.containsKey(commodityId);
  }

  @override
  Widget build(BuildContext context) {
    final iconPath = _commodityIconPaths[commodityId];
    if (iconPath == null) {
      return SizedBox(width: size, height: size);
    }
    return StrictAssetIcon(
      assetPath: '$kAppIconAssetPrefix$iconPath',
      width: size,
      height: size,
    );
  }
}

class WorkerIcon extends StatelessWidget {
  const WorkerIcon({super.key, required this.workerType, this.size = 16});

  final String workerType;
  final double size;

  static const Map<String, String> _workerIconPaths = {
    'peasant': 'ui_icon_worker_peasant.png',
    'apprentice': 'ui_icon_worker_apprentice.png',
    'journeyman': 'ui_icon_worker_journeyman.png',
    'master': 'ui_icon_worker_master.png',
  };

  static String? getIconPath(String workerType) {
    return _workerIconPaths[workerType];
  }

  static bool hasIcon(String workerType) {
    return _workerIconPaths.containsKey(workerType);
  }

  @override
  Widget build(BuildContext context) {
    final iconPath = _workerIconPaths[workerType];
    if (iconPath == null) {
      return SizedBox(width: size, height: size);
    }
    return StrictAssetIcon(
      assetPath: '$kAppIconAssetPrefix$iconPath',
      width: size,
      height: size,
    );
  }
}
