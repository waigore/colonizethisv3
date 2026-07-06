// Diplomacy panel. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/routes.dart';
import '../../../config/themes.dart' show editorialMonocleDisplayFontFamily;
import '../../../config/ui_screen_ids.dart';
import '../../../core/services/app_event_handler_scope.dart';
import '../../../core/services/subscription_tracker.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_gradients.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_radius.dart';
import '../../../widgets/ct_gap.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/relation_meter.dart';
import 'diplomacy_order_helpers.dart';
import 'panels/game_panel_contract.dart';
import 'diplomacy_panel_rows.dart';
import 'fnv1a_hash_constants.dart';
import 'relative_power_line.dart';

export 'diplomacy_panel_rows.dart';
export 'relative_power_line.dart';

part 'diplomacy_panel_body.dart';
part 'diplomacy_panel_chrome.dart';
part 'diplomacy_panel_mode_bar.dart';
part 'diplomacy_panel_order_actions.dart';
part 'diplomacy_panel_row.dart';

/// Maximum viewport width (Flutter dp) at which the diplomacy faction-row
/// body switches to its narrow stacked variant (info column above the
/// action-button cluster, left-aligned).
///
/// SPEC/ui/diplomacy-panel.md § Responsive layout — mirrors the
/// `@media (max-width: 500px)` cutoff in
/// [mockups/GAME30001-diplomacy-panel.html](../../../../../SPEC/ui/mockups/GAME30001-diplomacy-panel.html)
/// and the `≤ 500 dp` Diplomacy entry in
/// [mobile-adaptation.md](../../../../../SPEC/ui/mobile-adaptation.md) § 4.
///
/// Exposed at library scope so widget tests can pin the boundary
/// deterministically without re-deriving the constant.
const double kDiplomacyRowNarrowMaxWidth = 500.0;

/// Key prefix attached to a faction-row body widget so tests can resolve
/// the live Row (wide) vs Column (narrow) layout selection driven by
/// [kDiplomacyRowNarrowMaxWidth].
///
/// Each row uses `ValueKey('${kDiplomacyRowBodyKeyPrefix}<factionId>')`.
/// SPEC/ui/diplomacy-panel.md § Responsive layout cites this key so
/// widget tests can pin both variants without touching private types.
const String kDiplomacyRowBodyKeyPrefix = 'diplomacyRowBody:';

/// Spacing and run-spacing (Flutter dp) between diplomacy action buttons in
/// the trailing cluster `Wrap`. Mirrors the mockup `.f-actions { gap: 4px }`.
/// SPEC/ui/diplomacy-panel.md § Action button styling (Refs #3621).
const double kDiplomacyActionWrapSpacing = 4.0;

/// Minimum height (Flutter dp) of a diplomacy **compact** action button —
/// tighter than the default [CtNinePatchButton.minHeight] (48 dp) so the
/// action cluster matches the compact mockup density
/// (`.f-actions button`). SPEC/ui/diplomacy-panel.md § Action button
/// styling (Refs #3621).
const double kDiplomacyActionButtonMinHeight = 24.0;

/// Inner padding for a diplomacy **compact** action button — tighter than
/// [CtNinePatchButton.defaultPadding] (16 × 12 dp) to match the mockup
/// `.f-actions button { padding: 3px 7px }`. SPEC/ui/diplomacy-panel.md
/// § Action button styling (Refs #3621).
const EdgeInsets kDiplomacyActionButtonPadding = EdgeInsets.symmetric(
  horizontal: 7,
  vertical: 3,
);

/// Label font size (Flutter sp) for a diplomacy **compact** action button.
/// The label resolves to the editorial-monocle **display** font stack
/// ([editorialMonocleDisplayFontFamily], Cinzel) at this compact size —
/// materially smaller than the ~12 dp M3 `bodySmall` slot — so the mockup
/// `.f-actions button { font-size: 8px; font-family: var(--font-display) }`
/// density is honoured and more buttons pack onto each trailing-cluster run.
/// Pinned at library scope so widget tests assert the size from one source.
/// SPEC/ui/diplomacy-panel.md § Action button styling (Refs #3621).
const double kDiplomacyActionButtonFontSize = 10.0;

/// Label for the formal-alliance (treaty) badge rendered on the relation line
/// when `DiplomacyRelation.formalAlliance` is `true`. Exposed at library scope
/// so widget tests pin the badge text from a single source.
/// SPEC/ui/diplomacy-panel.md § Formal alliance indicator (Refs #3625).
const String kDiplomacyAllianceBadgeLabel = 'ALLIANCE';

/// OKLCH token for the translucent accent overlay behind the formal-alliance
/// badge, mirroring the WAR/PEACE relation-state badge derivation but on the
/// accent hue (`oklch(40% 0.06 85)`), tinted at [kDiplomacyAllianceBadgeAlpha].
/// SPEC/ui/diplomacy-panel.md § Formal alliance indicator (Refs #3625).
const OklchToken kDiplomacyAllianceBadgeBgToken = OklchToken(0.40, 0.06, 85);

/// Alpha applied on top of [kDiplomacyAllianceBadgeBgToken] for the
/// formal-alliance badge background overlay.
/// SPEC/ui/diplomacy-panel.md § Formal alliance indicator (Refs #3625).
const double kDiplomacyAllianceBadgeAlpha = 0.30;

/// Resolves the editorial-monocle color for the one-word relation label
/// derived from the hidden relation [score], per SPEC/ui/diplomacy-panel.md
/// § Relation word styling and SPEC/ui/components/relation-meter.md § Gradient.
///
/// The word color now matches its position on the 10-step relation meter: the
/// score maps to a 1-based meter step via [relationScoreToMeterStep] and that
/// step resolves through [relationMeterStepColor], the red → green OKLCH ladder
/// anchored on the canonical `--danger` (step 1) and `--success` (step 10)
/// tokens (Refs #3753 R13.3). This supersedes the legacy 4-band word-color map
/// so the inline word and the meter indicator always read in the same hue.
Color diplomacyRelationWordColor(num score) =>
    relationMeterStepColor(relationScoreToMeterStep(score));

/// Full-page diplomacy panel. SPEC/ui/diplomacy-panel.md.
class DiplomacyPanel extends StatefulWidget with GamePanelMixin {
  const DiplomacyPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.topology,
    required this.currentOrders,
    required this.bus,
    this.onClose,
    this.readOnly = false,
  });

  /// SPEC/ui/diplomacy-panel.md — [UiScreenIds.diplomacyScreen]. Hosted by
  /// `DiplomacyScreen`; shares its stable surface ID.
  static const screenId = UiScreenIds.diplomacyScreen;

  @override
  final Game game;
  @override
  final String humanPlayerId;
  final MapTopology topology;
  final Orders currentOrders;
  @override
  final AppEventBus bus;
  final VoidCallback? onClose;
  @override
  final bool readOnly;

  @override
  State<DiplomacyPanel> createState() => _DiplomacyPanelState();
}

class _DiplomacyPanelState extends State<DiplomacyPanel>
    with _DiplomacyOrderActions {
  final Map<String, String> _moodByLeaderId = <String, String>{};
  final SubscriptionTracker _subscriptions = SubscriptionTracker();

  @override
  Map<String, String> get moodByLeaderId => _moodByLeaderId;

  /// Bottom-mode-bar filter (SPEC/ui/diplomacy-panel.md § Mode bar (filter)).
  /// Local UI state — does not persist across panel close/reopen.
  DiplomacyFilterMode _filterMode = DiplomacyFilterMode.all;

  @override
  void initState() {
    super.initState();
    _subscriptions.track(
      widget.bus.on<PortraitMoodEvent>().listen((event) {
        _moodByLeaderId[event.leaderId] = event.toMood;
      }),
    );
  }

  @override
  void dispose() {
    _subscriptions.cancelAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = buildDiplomacyRows(
      widget.game,
      widget.topology,
      widget.humanPlayerId,
      widget.currentOrders,
    );
    final gps = <DiplomacyRowData>[];
    final minors = <DiplomacyRowData>[];
    final tribes = <DiplomacyRowData>[];
    for (final r in rows) {
      switch (r.kind) {
        case FactionKind.greatPower:
          gps.add(r);
        case FactionKind.minor:
          minors.add(r);
        case FactionKind.tribe:
          tribes.add(r);
      }
    }
    final showGps = diplomacyFilterShowsKind(
      _filterMode,
      FactionKind.greatPower,
    );
    final showMinors = diplomacyFilterShowsKind(_filterMode, FactionKind.minor);
    final showTribes = diplomacyFilterShowsKind(_filterMode, FactionKind.tribe);

    // SPEC/ui/diplomacy-panel.md § Section headings (first-heading top rhythm,
    // Refs #3621): the first heading rendered under the active filter drops
    // its top gap to 0 (mockup `.section-head:first-child`).
    final FactionKind? firstShownKind = showGps
        ? FactionKind.greatPower
        : showMinors
        ? FactionKind.minor
        : showTribes
        ? FactionKind.tribe
        : null;

    return Column(
      children: [
        Expanded(
          child: _DiplomacyPanelBody(
            gps: gps,
            minors: minors,
            tribes: tribes,
            showGps: showGps,
            showMinors: showMinors,
            showTribes: showTribes,
            firstShownKind: firstShownKind,
            onAction: submitOrDialog,
            onTap: openDetail,
            readOnly: widget.readOnly,
          ),
        ),
        _DiplomacyModeBar(
          mode: _filterMode,
          onModeChanged: (next) {
            if (next == _filterMode) return;
            setState(() => _filterMode = next);
          },
        ),
      ],
    );
  }
}
