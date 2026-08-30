import 'package:colonizethis_logic/civilian_intel_api.dart'
    show CivilianMissingWorkOrderEntry;
import 'package:flutter/material.dart';

import '../../../../widgets/ct_icon_action.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../widgets/civilian/civilian_unit_type_icon.dart';

class NextTurnIdleCivilianWarningRow extends StatelessWidget {
  const NextTurnIdleCivilianWarningRow({
    super.key,
    required this.entry,
    required this.bodyStyle,
    required this.mutedStyle,
    required this.locateTooltip,
    required this.noWorkOrderLabel,
    required this.onGoTo,
  });

  final CivilianMissingWorkOrderEntry entry;
  final TextStyle bodyStyle;
  final TextStyle mutedStyle;
  final String locateTooltip;
  final String noWorkOrderLabel;
  final VoidCallback? onGoTo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CivilianUnitTypeIcon(unitType: entry.type),
          const SizedBox(width: CtSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.type,
                  style: bodyStyle,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.locationLabel,
                  style: mutedStyle,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  noWorkOrderLabel,
                  style: mutedStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CtIconAction(
            key: ValueKey('idle-civilian-locate-${entry.unitId}'),
            tooltip: locateTooltip,
            icon: Icons.my_location,
            onPressed: onGoTo,
          ),
        ],
      ),
    );
  }
}
