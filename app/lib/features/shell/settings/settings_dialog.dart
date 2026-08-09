// App Settings dialog. OpenDialogEvent id `settings`.
// SPEC/ui/settings-dialog.md.

import 'package:colonizethis_app/config/ux_settings_keys.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_catalog_loader.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_models.dart';
import 'package:colonizethis_app/providers/settings_provider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_gap.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-global Settings surface (map theme pickers). Applies on next app start.
class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  /// SPEC/ui/settings-dialog.md — [UiScreenIds.settingsDialog].
  static const screenId = UiScreenIds.settingsDialog;

  static const Key titleKey = ValueKey<String>('settingsDialog.title');
  static const Key restartHintKey = ValueKey<String>(
    'settingsDialog.restartHint',
  );
  static const Key closeButtonKey = ValueKey<String>(
    'settingsDialog.closeButton',
  );

  static const Key warnIdleCiviliansToggleKey = ValueKey<String>(
    'settingsDialog.warnIdleCiviliansOnEndTurn',
  );

  static Key groupDropdownKey(MapThemeGroupId group) =>
      ValueKey<String>('settingsDialog.theme.${group.catalogId}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final catalog = MapThemeCatalogLoader.isLoaded
        ? MapThemeCatalogLoader.instance
        : null;
    final settings = ref.watch(settingsProvider);

    final warnIdleCiviliansOnEndTurn =
        settings[UxSettingsKeys.warnIdleCiviliansOnEndTurn] as bool? ?? true;

    return CtDialogShell(
      maxWidth: 420,
      maxHeight: 520,
      padding: const EdgeInsets.all(CtSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.settingsDialog_title,
            key: titleKey,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: EditorialMonoclePalette.accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          CtGap.m,
          Text(
            l10n.settingsDialog_section_gameplay,
            style: theme.textTheme.labelLarge?.copyWith(
              color: EditorialMonoclePalette.fg,
            ),
          ),
          CtGap.m,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CtToggleSwitch(
                key: warnIdleCiviliansToggleKey,
                value: warnIdleCiviliansOnEndTurn,
                onChanged: (value) {
                  ref
                      .read(settingsProvider.notifier)
                      .setValue(UxSettingsKeys.warnIdleCiviliansOnEndTurn, value);
                },
              ),
              CtGap.m,
              Expanded(
                child: Text(
                  l10n.settingsDialog_warnIdleCiviliansOnEndTurn,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: EditorialMonoclePalette.fg,
                  ),
                ),
              ),
            ],
          ),
          CtGap.l,
          Text(
            l10n.settingsDialog_section_themes,
            style: theme.textTheme.labelLarge?.copyWith(
              color: EditorialMonoclePalette.fg,
            ),
          ),
          CtGap.m,
          Text(
            l10n.settingsDialog_restartHint,
            key: restartHintKey,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.muted,
            ),
          ),
          CtGap.l,
          if (catalog == null)
            Text(
              l10n.settingsDialog_catalogUnavailable,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            )
          else
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in catalog.multiThemeGroups) ...[
                    _ThemeGroupPicker(
                      group: group,
                      themes: catalog.themesFor(group),
                      selectedId:
                          settings[group.settingsKey] as String? ??
                          MapThemeGroupId.defaultThemeId,
                      onChanged: (id) {
                        if (id == null) return;
                        ref
                            .read(settingsProvider.notifier)
                            .setValue(group.settingsKey, id);
                      },
                    ),
                    CtGap.m,
                  ],
                ],
              ),
            ),
          CtGap.l,
          CtNinePatchButton(
            key: closeButtonKey,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.settingsDialog_close),
          ),
        ],
      ),
    );
  }
}

class _ThemeGroupPicker extends StatelessWidget {
  const _ThemeGroupPicker({
    required this.group,
    required this.themes,
    required this.selectedId,
    required this.onChanged,
  });

  final MapThemeGroupId group;
  final List<MapThemeEntry> themes;
  final String selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final ids = themes.map((t) => t.id).toList(growable: false);
    final value = ids.contains(selectedId)
        ? selectedId
        : MapThemeGroupId.defaultThemeId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _groupLabel(l10n, group),
          style: theme.textTheme.labelLarge?.copyWith(
            color: EditorialMonoclePalette.fg,
          ),
        ),
        CtGap.m,
        CtDropdown<String>(
          key: SettingsDialog.groupDropdownKey(group),
          value: value,
          items: ids,
          itemLabel: (id) {
            final entry = themes.firstWhere((t) => t.id == id);
            return mapThemeDisplayName(l10n, entry.nameL10nKey);
          },
          onChanged: onChanged,
        ),
      ],
    );
  }
}

String _groupLabel(AppLocalizations l10n, MapThemeGroupId group) {
  switch (group) {
    case MapThemeGroupId.terrain:
      return l10n.settingsDialog_group_terrain;
    case MapThemeGroupId.civilianIcons:
      return l10n.settingsDialog_group_civilianIcons;
    case MapThemeGroupId.townIcons:
      return l10n.settingsDialog_group_townIcons;
    case MapThemeGroupId.resourceIcons:
      return l10n.settingsDialog_group_resourceIcons;
    case MapThemeGroupId.fleetIcons:
      return l10n.settingsDialog_group_fleetIcons;
    case MapThemeGroupId.provinceLabelIcons:
      return l10n.settingsDialog_group_provinceLabelIcons;
  }
}

/// Resolves a catalog `name_l10n_key` to a localized display string.
String mapThemeDisplayName(AppLocalizations l10n, String nameL10nKey) {
  switch (nameL10nKey) {
    case 'mapTheme_terrain_default':
      return l10n.mapTheme_terrain_default;
    case 'mapTheme_terrain_sepia':
      return l10n.mapTheme_terrain_sepia;
    case 'mapTheme_civilian_default':
      return l10n.mapTheme_civilian_default;
    case 'mapTheme_civilian_sepia':
      return l10n.mapTheme_civilian_sepia;
    case 'mapTheme_town_default':
      return l10n.mapTheme_town_default;
    case 'mapTheme_resource_default':
      return l10n.mapTheme_resource_default;
    case 'mapTheme_fleet_default':
      return l10n.mapTheme_fleet_default;
    case 'mapTheme_provinceLabel_default':
      return l10n.mapTheme_provinceLabel_default;
    default:
      return nameL10nKey;
  }
}
