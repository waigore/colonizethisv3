import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../config/routes.dart';
import '../../providers/game_service_provider.dart';
import '../../providers/games_provider.dart';
import '../../widgets/ct_dialog_shell.dart';
import '../../widgets/ct_dropdown.dart';
import '../../widgets/ct_nine_patch_button.dart';
import '../../widgets/main_menu.dart';

/// App shell. Shows CtMainMenu per SPEC/ui/main-menu.md. Phase 1: wired to resolve and persist.
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CtMainMenu(
      variant: MainMenuVariant.plain,
      state: MainMenuState.default_,
      version: 'v0.0.1',
      onNewGame: () => _showNewGameFlow(context, ref),
      onLoadGame: () async {
        final service = ref.read(gameServiceProvider);
        final ids = service.listGameIds();
        if (ids.isEmpty || !context.mounted) return;
        final game = service.loadGame(ids.first);
        if (game != null && context.mounted) {
          ref.read(currentGameProvider.notifier).state = game;
          if (context.mounted) {
            Navigator.pushNamed(context, Routes.game);
          }
        }
      },
      onSettings: () {},
      onQuit: () {
        SystemNavigator.pop();
      },
    );
  }

  void _showNewGameFlow(BuildContext context, WidgetRef ref) {
    final baseConfig = GameSetupConfig.defaultConfig;
    final naming = defaultNamingConfig;
    // Per-GP leader selection: gpId -> chosen variant id (leaderKey comes from variant).
    final initialSelections = <String, String>{};
    for (final gpId in baseConfig.selectedGreatPowerIds) {
      final gp = naming.gpById(gpId);
      if (gp != null && gp.leaderVariants.isNotEmpty) {
        initialSelections[gpId] = gp.defaultLeaderVariantId;
      }
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => _LeaderSelectionDialog(
        baseConfig: baseConfig,
        naming: naming,
        initialLeaderByGpId: initialSelections,
        onStart: (leaderVariantByGpId) {
          Navigator.of(ctx).pop();
          final config = GameSetupConfig(
            selectedGreatPowerIds: baseConfig.selectedGreatPowerIds,
            leaderVariantByGpId: leaderVariantByGpId,
            continentCount: baseConfig.continentCount,
            minorNationCount: baseConfig.minorNationCount,
            tribeCount: baseConfig.tribeCount,
            numProvincesOldWorld: baseConfig.numProvincesOldWorld,
            numProvincesNewWorld: baseConfig.numProvincesNewWorld,
            minProvincesPerMinor: baseConfig.minProvincesPerMinor,
            seed: baseConfig.seed,
            startingResources: baseConfig.startingResources,
          );
          final service = ref.read(gameServiceProvider);
          final game = service.createNewGame(config: config);
          ref.read(currentGameProvider.notifier).state = game;
          if (context.mounted) {
            Navigator.pushNamed(context, Routes.game);
          }
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }
}

/// Dialog for each human/selected Great Power to choose leader (or default). SPEC Phase 5 Dev 12.
class _LeaderSelectionDialog extends StatefulWidget {
  const _LeaderSelectionDialog({
    required this.baseConfig,
    required this.naming,
    required this.initialLeaderByGpId,
    required this.onStart,
    required this.onCancel,
  });

  final GameSetupConfig baseConfig;
  final ResolvedNamingConfig naming;
  final Map<String, String> initialLeaderByGpId;
  final void Function(Map<String, String> leaderVariantByGpId) onStart;
  final VoidCallback onCancel;

  @override
  State<_LeaderSelectionDialog> createState() => _LeaderSelectionDialogState();
}

class _LeaderSelectionDialogState extends State<_LeaderSelectionDialog> {
  late Map<String, String> _leaderByGpId;

  @override
  void initState() {
    super.initState();
    _leaderByGpId = Map<String, String>.from(widget.initialLeaderByGpId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final children = <Widget>[
      Text(
        l10n.shell_leaderDialog_intro,
        style: const TextStyle(fontSize: 14),
      ),
      const SizedBox(height: 16),
    ];

    for (final gpId in widget.baseConfig.selectedGreatPowerIds) {
      final gp = widget.naming.gpById(gpId);
      if (gp == null || gp.leaderVariants.isEmpty) continue;
      final currentVariantId = _leaderByGpId[gpId] ?? gp.defaultLeaderVariantId;
      children.addAll([
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(gp.countryName, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CtDropdown<String>(
                  value: currentVariantId,
                  items: gp.leaderVariants.map((v) => v.id).toList(),
                  hint: l10n.shell_leaderDialog_selectLeaderHint,
                  itemLabel: (id) =>
                      gp.leaderVariants.firstWhere((v) => v.id == id).name,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _leaderByGpId[gpId] = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ]);
    }

    children.addAll([
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CtNinePatchButton(
            onPressed: widget.onCancel,
            child: Text(l10n.common_cancel),
          ),
          const SizedBox(width: 8),
          CtNinePatchButton(
            onPressed: () => widget.onStart(_leaderByGpId),
            child: Text(l10n.common_start),
          ),
        ],
      ),
    ]);

    return CtDialogShell(
      maxWidth: 480,
      maxHeight: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shell_leaderDialog_title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
