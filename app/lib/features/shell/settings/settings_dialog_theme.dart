import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_models.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_gap.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

class SettingsDialogThemeGroupPicker extends StatelessWidget {
  const SettingsDialogThemeGroupPicker({
    super.key,
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
          settingsDialogGroupLabel(l10n, group),
          style: theme.textTheme.labelLarge?.copyWith(
            color: EditorialMonoclePalette.fg,
          ),
        ),
        CtGap.m,
        CtDropdown<String>(
          key: ValueKey<String>('settingsDialog.theme.${group.catalogId}'),
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

String settingsDialogGroupLabel(AppLocalizations l10n, MapThemeGroupId group) {
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
