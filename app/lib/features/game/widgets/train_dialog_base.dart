// Shared base for the train-at-capital dialogs (civilian, military, naval).
// SPEC/ui/train-civilians-dialog.md, SPEC/ui/train-military-dialog.md,
// SPEC/ui/train-naval-dialog.md, SPEC/ui/components/train-dialog-chrome.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_spacing.dart';
import 'train_dialog_chrome.dart';
import 'train_unit_dialog_helper.dart';

/// Common widget contract for the train-at-capital dialogs. Each concrete
/// dialog (civilian / military / naval) carries the same inputs: the active
/// [game], the [humanPlayerId] whose capital the units train at, the
/// [currentOrders] used to seed stepper counts, and the [bus] that the
/// committed [BuildUnitOrder] list is emitted on when the dialog closes.
abstract class TrainDialogBase extends StatefulWidget {
  const TrainDialogBase({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.currentOrders,
    required this.bus,
  });

  final Game game;
  final String humanPlayerId;
  final Orders currentOrders;
  final AppEventBus bus;
}

/// Shared [State] for [TrainDialogBase] subclasses.
///
/// Owns the structural scaffolding called out in `SPEC/ui/.../train-*` and
/// `colonizethis-component-structure.mdc` (reuse at 2+ call sites): the
/// `PopScope` + [CtDialogShell] wrapper, the no-capital message, the header +
/// body composition, the stepper count state, count mutation, tech-lock
/// resolution, and order materialization on close. Unit-type-specific cost
/// modelling (treasury / peasants / commodities, deficit hint, resource bar,
/// and per-row rendering) stays in each subclass via [buildBody] and
/// [canAffordIncrement].
abstract class TrainDialogBaseState<T extends TrainDialogBase>
    extends State<T> {
  late Map<String, int> counts;

  @override
  void initState() {
    super.initState();
    counts = initialTrainDialogCountsFromOrders(
      unitTypeIds: unitTypeIds,
      currentOrders: widget.currentOrders,
      humanPlayerId: widget.humanPlayerId,
      capitalProvinceId: player?.capitalProvinceId,
      isMilitary: ordersAreMilitary,
    );
  }

  // --- Subclass contract ---------------------------------------------------

  /// Ordered trainable unit-type ids for this dialog (catalog key order).
  Iterable<String> get unitTypeIds;

  /// `isMilitary` flag stamped on materialized [BuildUnitOrder]s and used to
  /// match this dialog's managed orders when seeding counts.
  bool get ordersAreMilitary;

  /// Map of unit-type id to the tech id that unlocks it (absent ⇒ always
  /// available). Drives [isLocked] and [techRequiredLabel].
  Map<String, String> get unlockingTechByUnitType;

  /// Whether one more of [unitTypeId] remains affordable given currently
  /// committed counts. Subclass-specific because the cost model differs
  /// (civilian: treasury + paper; military/naval: treasury + peasants +
  /// commodities).
  bool canAffordIncrement(String unitTypeId);

  /// Localized dialog title shown in the [TrainDialogHeader].
  String dialogTitle(AppLocalizations l10n);

  /// Emits this dialog's committed-orders event on [widget.bus].
  void emitCommittedOrders(List<BuildUnitOrder> orders);

  /// Builds the dialog body (resource bar, unit rows, reset action) shown when
  /// the player has a capital.
  List<Widget> buildBody(AppLocalizations l10n);

  // --- Shared state / derived data -----------------------------------------

  Player? get player => trainDialogPlayerById(
    players: widget.game.players,
    playerId: widget.humanPlayerId,
  );

  bool get hasCapital => trainDialogHasCapital(player);

  int get treasury => trainDialogTreasury(player);

  int get peasants => player?.workerPool.peasants ?? 0;

  Map<String, bool> get techUnlocked => trainDialogTechUnlocked(player);

  int stockpileQty(String commodityId) =>
      player?.stockpile.quantityOf(commodityId) ?? 0;

  bool isLocked(String unitType) {
    return trainDialogIsLocked(
      unitType: unitType,
      unlockingTechByUnitType: unlockingTechByUnitType,
      techUnlocked: techUnlocked,
    );
  }

  String techRequiredLabel(String unitType) {
    final techId = unlockingTechByUnitType[unitType];
    if (techId == null) return '';
    return 'Requires: ${techDisplayName(techId)}';
  }

  // --- Stepper / order mutation --------------------------------------------

  void increment(String unitType) {
    if (isLocked(unitType)) return;
    if (!canAffordIncrement(unitType)) return;
    setState(() {
      counts = incrementTrainDialogCount(counts, unitType);
    });
  }

  void decrement(String unitType) {
    if ((counts[unitType] ?? 0) <= 0) return;
    setState(() {
      counts = decrementTrainDialogCount(counts, unitType);
    });
  }

  void reset() {
    setState(() {
      counts = resetTrainDialogCounts(counts);
    });
  }

  void applyOrders() {
    final capital = player?.capitalProvinceId;
    if (capital == null) return;
    final orders = materializeTrainDialogOrdersFromCounts(
      orderedUnitTypeIds: unitTypeIds,
      counts: counts,
      capitalProvinceId: capital,
      isMilitary: ordersAreMilitary,
    );
    emitCommittedOrders(orders);
  }

  // --- Shared chrome --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          applyOrders();
        }
      },
      child: CtDialogShell(
        padding: const EdgeInsets.fromLTRB(
          CtSpacing.l,
          CtSpacing.ml,
          CtSpacing.l,
          CtSpacing.l,
        ),
        child: _buildDialogContent(context, l10n),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrainDialogHeader(title: dialogTitle(l10n)),
        if (!hasCapital) ...[
          const SizedBox(height: CtSpacing.m),
          _buildNoCapitalMessage(context, l10n),
        ] else
          ...buildBody(l10n),
      ],
    );
  }

  Widget _buildNoCapitalMessage(BuildContext context, AppLocalizations l10n) {
    return Text(
      l10n.trainUnits_noCapital,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: EditorialMonoclePalette.danger,
      ),
    );
  }
}
