// Move army dialog. SPEC/ui/military-units-panel.md, SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';

String moveArmyFactionGroupHeaderLabel(
  Game game,
  ArmyMovePickerDestination entry,
  AppLocalizations l10n,
) {
  if (entry.isPlayerOwned) return l10n.moveArmy_groupYourProvinces;
  if (entry.ownerFactionId == '__unowned__') return l10n.moveArmy_groupUnowned;
  final gp = game.playerById(entry.ownerFactionId);
  if (gp != null) return gp.displayName;
  for (final m in game.minorNations) {
    if (m.id == entry.ownerFactionId) {
      return m.displayName ?? m.id;
    }
  }
  for (final t in game.tribes) {
    if (t.id == entry.ownerFactionId) {
      return t.displayName ?? t.id;
    }
  }
  return entry.ownerFactionId;
}

class MoveArmyDialog extends StatefulWidget {
  const MoveArmyDialog({
    super.key,
    required this.army,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
    required this.draftOrders,
    this.playerView,
  });

  /// SPEC/ui/move-army-dialog.md — [UiScreenIds.moveArmyDialog].
  static const screenId = UiScreenIds.moveArmyDialog;

  final Army army;
  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;
  final MapTopology topology;
  final Orders draftOrders;

  /// When supplied, destination probing reuses this [PlayerView] and a single
  /// per-dialog [IncrementalCandidateValidator] instead of rebuilding them on
  /// every picker call (Refs #2394, SPEC/program/order-suggestions.md).
  final PlayerView? playerView;

  @override
  State<MoveArmyDialog> createState() => _MoveArmyDialogState();
}

class _MoveArmyDialogState extends State<MoveArmyDialog> {
  String? _selected;
  IncrementalCandidateValidator? _sharedCandidateValidator;
  List<ArmyMovePickerDestination>? _cachedDestinations;
  Orders? _cachedDestinationsOrders;
  String? _cachedDestinationsArmyId;

  void _syncSharedValidatorAndDestinations({bool rebuildValidator = false}) {
    final view = widget.playerView;
    if (view == null) {
      _sharedCandidateValidator = null;
      _cachedDestinations = null;
      _cachedDestinationsOrders = null;
      _cachedDestinationsArmyId = null;
      return;
    }
    final orders = widget.draftOrders;
    if (rebuildValidator || _sharedCandidateValidator == null) {
      _sharedCandidateValidator = IncrementalCandidateValidator.forPlayer(
        game: widget.game,
        topology: widget.topology,
        playerId: widget.humanPlayerId,
        basePrefix: orders,
        view: view,
        unitsById: unitsByIdFromWorld(widget.game.worldState),
      );
    } else {
      _sharedCandidateValidator = _sharedCandidateValidator!.forBasePrefix(
        orders,
      );
    }
    final armyId = widget.army.id;
    if (_cachedDestinationsOrders != orders ||
        _cachedDestinationsArmyId != armyId) {
      _cachedDestinations = armyMovePickerDestinations(
        game: widget.game,
        topology: widget.topology,
        playerId: widget.humanPlayerId,
        army: widget.army,
        currentOrders: orders,
        playerView: view,
        sharedCandidateValidator: _sharedCandidateValidator,
      );
      _cachedDestinationsOrders = orders;
      _cachedDestinationsArmyId = armyId;
    }
  }

  List<ArmyMovePickerDestination> _destinationEntries() {
    final view = widget.playerView;
    if (view != null) {
      _syncSharedValidatorAndDestinations();
      return _cachedDestinations!;
    }
    return armyMovePickerDestinations(
      game: widget.game,
      topology: widget.topology,
      playerId: widget.humanPlayerId,
      army: widget.army,
      currentOrders: widget.draftOrders,
    );
  }

  String _groupKey(ArmyMovePickerDestination e) =>
      e.isPlayerOwned ? '__player__' : e.ownerFactionId;

  List<DropdownMenuItem<String>> _groupedDropdownItems(
    List<ArmyMovePickerDestination> entries,
    AppLocalizations l10n,
  ) {
    final items = <DropdownMenuItem<String>>[];
    String? currentGroup;
    for (final entry in entries) {
      final g = _groupKey(entry);
      if (g != currentGroup) {
        currentGroup = g;
        items.add(
          DropdownMenuItem<String>(
            enabled: false,
            value: '__header__$g',
            child: Text(
              moveArmyFactionGroupHeaderLabel(widget.game, entry, l10n),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
      items.add(
        DropdownMenuItem<String>(
          value: entry.fullProvinceId,
          child: Text(entry.provinceLabel),
        ),
      );
    }
    return items;
  }

  ArmyMovePickerDestination? _selectedEntry(
    List<ArmyMovePickerDestination> entries,
  ) {
    final id = _selected;
    if (id == null) return null;
    for (final e in entries) {
      if (e.fullProvinceId == id) return e;
    }
    return null;
  }

  void _emitAndClose(ArmyMovePickerDestination entry) {
    widget.bus.emit(
      ArmyMoveRequestedEvent(
        humanPlayerId: widget.humanPlayerId,
        moveOrder: ArmyMoveOrder(
          armyId: widget.army.id,
          destinationProvinceId: entry.fullProvinceId,
        ),
        declareWarTargetFactionId: entry.requiresDeclareWarOnConfirm
            ? entry.ownerFactionId
            : null,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _onConfirmPressed() async {
    final entries = _destinationEntries();
    final entry = _selectedEntry(entries);
    if (entry == null) return;
    final l10n = appL10n(context);

    if (!entry.requiresDeclareWarOnConfirm) {
      _emitAndClose(entry);
      return;
    }

    final ownerLabel = moveArmyFactionGroupHeaderLabel(
      widget.game,
      entry,
      l10n,
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.moveArmy_invadeProvinceTitle),
        content: Text(l10n.moveArmy_invadeProvinceBody(ownerLabel)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.moveArmy_declareWarAndMove),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      _emitAndClose(entry);
    }
  }

  @override
  void initState() {
    super.initState();
    _syncSharedValidatorAndDestinations();
    final entries = _destinationEntries();
    if (entries.isNotEmpty) {
      _selected = entries.first.fullProvinceId;
    }
  }

  @override
  void didUpdateWidget(MoveArmyDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draftOrders != widget.draftOrders ||
        oldWidget.game != widget.game ||
        oldWidget.army != widget.army ||
        oldWidget.playerView != widget.playerView) {
      _syncSharedValidatorAndDestinations(
        rebuildValidator:
            oldWidget.game != widget.game ||
            oldWidget.playerView != widget.playerView,
      );
      final entries = _destinationEntries();
      if (_selected == null ||
          !entries.any((e) => e.fullProvinceId == _selected)) {
        _selected = entries.isEmpty ? null : entries.first.fullProvinceId;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final entries = _destinationEntries();
    final items = _groupedDropdownItems(entries, l10n);

    return AlertDialog(
      title: Text(l10n.moveArmy_title(widget.army.id)),
      content: SizedBox(
        width: 320,
        child: entries.isEmpty
            ? Text(l10n.moveArmy_noValidDestinations)
            : DropdownButtonFormField<String>(
                initialValue: _selected,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.moveArmy_destinationProvince,
                ),
                items: items,
                onChanged: (v) => setState(() => _selected = v),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        TextButton(
          onPressed: _selected == null ? null : _onConfirmPressed,
          child: Text(l10n.common_confirm),
        ),
      ],
    );
  }
}
