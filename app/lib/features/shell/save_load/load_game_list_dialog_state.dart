// Stateful host for [LoadGameListDialog] (de-parted wave-9 cluster, Refs #4117).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_gap.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';

import 'load_game_list_dialog_body.dart';
import 'load_game_list_dialog_confirm.dart';
import 'load_game_list_dialog_row.dart';
import 'load_game_list_dialog_state_base.dart';
import 'load_game_list_dialog_widget.dart';

class LoadGameListDialogState extends ConsumerState<LoadGameListDialog>
    with
        LoadGameListDialogStateBase,
        LoadGameListDialogRow,
        LoadGameListDialogBody,
        LoadGameListDialogConfirm {
  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
        .copyWith(
          color: EditorialMonoclePalette.accent,
          fontWeight: FontWeight.w700,
        );
    final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.fg,
    );
    final mutedStyle = bodyStyle.copyWith(color: EditorialMonoclePalette.muted);
    final entries = currentEntries();

    LoadableSaveEntry? autoSave;
    final manuals = <LoadableSaveEntry>[];
    for (final entry in entries) {
      if (entry.kind == LoadableSaveKind.autoSave) {
        autoSave = entry;
      } else {
        manuals.add(entry);
      }
    }
    final pageCount = manuals.isEmpty
        ? 0
        : ((manuals.length + kLoadGameManualPageSize - 1) ~/
              kLoadGameManualPageSize);
    final showPager = manuals.length > kLoadGameManualPageSize;
    final pageIndex = pageCount == 0
        ? 0
        : manualPageIndex.clamp(0, pageCount - 1);
    final pageManuals = pageCount == 0
        ? const <LoadableSaveEntry>[]
        : manuals
              .skip(pageIndex * kLoadGameManualPageSize)
              .take(kLoadGameManualPageSize)
              .toList();

    final showConfirm = pendingDelete != null || pendingLoad != null;

    return CtDialogShell(
      maxWidth: 420,
      maxHeight: 480,
      padding: const EdgeInsets.all(CtSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.loadGameList_title, style: titleStyle),
          CtGap.ml,
          if (showConfirm)
            ...confirmBodyChildren(
              l10n: l10n,
              bodyStyle: bodyStyle,
              pendingDeleteEntry: pendingDelete,
              pendingLoadEntry: pendingLoad,
            )
          else
            ...listAndPagerChildren(
              l10n: l10n,
              bodyStyle: bodyStyle,
              mutedStyle: mutedStyle,
              entries: entries,
              autoSave: autoSave,
              pageManuals: pageManuals,
              showPager: showPager,
              pageIndex: pageIndex,
              pageCount: pageCount,
            ),
        ],
      ),
    );
  }
}
