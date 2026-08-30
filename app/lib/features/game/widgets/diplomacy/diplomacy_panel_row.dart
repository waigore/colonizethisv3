// Per-faction diplomacy row layout for DiplomacyPanel.
// SPEC/ui/diplomacy-panel.md § Per-faction row, § Responsive layout.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_spacing.dart';
import 'diplomacy_panel_chrome_standing.dart';
import 'diplomacy_panel_constants.dart';
import 'diplomacy_panel_row_actions.dart';
import 'diplomacy_panel_row_info.dart';
import 'diplomacy_panel_rows.dart';

class DiplomacyRow extends StatelessWidget {
  const DiplomacyRow({
    super.key,
    required this.data,
    required this.onAction,
    this.onTap,
    this.readOnly = false,
  });

  final DiplomacyRowData data;
  final void Function(DiplomaticOrder) onAction;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final bool narrow = viewportWidth <= kDiplomacyRowNarrowMaxWidth;
    return DiplomacyRowChrome(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CtSpacing.ml),
          child: narrow ? _buildNarrowBody(context) : _buildWideBody(context),
        ),
      ),
    );
  }

  Key get _bodyKey => ValueKey('$kDiplomacyRowBodyKeyPrefix${data.factionId}');

  Widget _buildWideBody(BuildContext context) {
    return Row(
      key: _bodyKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: DiplomacyRowInfo(data: data)),
        Flexible(
          child: Align(
            alignment: Alignment.topRight,
            child: _buildActionButtons(alignEnd: true),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowBody(BuildContext context) {
    final bool hasActions = !readOnly && data.actions.isNotEmpty;
    return Column(
      key: _bodyKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DiplomacyRowInfo(data: data),
        if (hasActions) ...[
          CtGap.m,
          Align(alignment: Alignment.centerLeft, child: _buildActionButtons()),
        ],
      ],
    );
  }

  Widget _buildActionButtons({bool alignEnd = false}) {
    if (readOnly) {
      return const SizedBox.shrink();
    }
    return DiplomacyRowActions(
      factionId: data.factionId,
      actions: data.actions,
      pendingOrderTypes: data.pendingOrderTypes,
      pendingOvertureStage: data.pendingOvertureStage,
      onAction: onAction,
      alignEnd: alignEnd,
    );
  }
}
