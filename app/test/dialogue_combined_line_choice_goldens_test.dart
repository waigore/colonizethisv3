// Widget goldens proving the combined line+choice presentation step for the
// blocking Jenny dialogue overlays (Refs #3628). The core fix (retained
// `CtDialogueView.contextLine` rendered by the shared `CtDialogueLineChoiceBody`)
// shipped in #3634; these goldens close the visual-proof gap flagged during
// verification: the pre-existing OVL80001 herald golden freezes the *line* step
// before advancing, so no `matchesGoldenFile` baseline captured the combined
// line+choice layout that is the deliverable of #3628.
//
// Each test advances the overlay past the narrative line to the Yarn `-> option`
// choice step, then asserts both (a) the narrative text and the option button
// render together (structural finders, so the AC still holds when goldens are
// regenerated on another platform) and (b) the pixel baseline under
// `app/test/goldens/`.
//
// Harness mirrors `diplomacy_panel_goldens_test.dart`: a keyed `RepaintBoundary`
// wraps the surface, an in-memory `AssetBundle` pins deterministic Yarn, and
// `AppThemes.editorialMonocle` supplies the dark-theme chrome
// (`colonizethis-ui-design.mdc`). Text renders in the flutter_test Ahem font, so
// the goldens are deterministic across platforms.
//
// SPEC: SPEC/ui/game-start-intro-overlay.md § Acceptance Criteria (Refs #3628
// AC-2 golden coverage) and SPEC/ui/tribe-first-contact-overlay.md § Acceptance
// criteria (AC-11).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/dialogue/intervention_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/dialogue/tribe_first_contact_overlay.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

/// Minimal in-memory [AssetBundle] returning the supplied yarn text so the
/// goldens are deterministic and offline (mirrors
/// `tribe_first_contact_overlay_test.dart`).
class _StringAssetBundle extends Fake implements AssetBundle {
  _StringAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final text = _assets[key];
    if (text == null) throw Exception('missing asset: $key');
    return text;
  }
}

// OVL10001 fixture: the production `game_start_intro` node shape (one narrative
// line followed by `-> I shall.`), kept short so the golden is decoupled from
// future intro-copy edits.
const _kIntroYarn = '''
title: game_start_intro
---
The age of imperialism draweth nigh.
-> I shall.
===
''';

// OVL80001 fixture: mirrors the production `{\$var}` interpolation so the herald
// golden exercises the same variable-binding path as the overlay.
const _kHeraldYarn = '''
title: tribe_first_contact
---
Scouts return with word of the {\$tribeName}, who hold their seat at {\$capitalName}.
-> Continue
===
''';

// Overture intro fixture: the production `DialoguePoint/overture_target_response`
// node shape (one narrative line then `-> Continue`), kept short so the golden is
// decoupled from future intro-copy edits.
const _kOvertureYarn = '''
title: DialoguePoint/overture_target_response
---
Envoys await thy word on the overtures laid before the Crown.
-> Continue
===
''';

// Intervention intro fixture: the production `intervention.yarn` requires all
// five nodes to be present at parse time (intro + situation + three reactions)
// and interpolates `{\$var}` faction names, so the fixture mirrors that shape.
// The intro node is intentionally a single line then `-> Continue` so advancing
// once reaches the combined choice step.
const _kInterventionYarn = r'''
title: DialoguePoint/intervention_intro
---
Heavy tidings cross thy desk from distant shores; the Crown looketh to thee.
-> Continue
===

title: DialoguePoint/intervention_situation
---
Word arriveth that {$aggressorName} hath proclaimed open war against {$defenderName}; {$interveningName} cannot feign ignorance.
-> Continue
===

title: DialoguePoint/intervention_reaction_intervene
---
{$aggressorName} rendeth the air with oaths.
-> Continue
===

title: DialoguePoint/intervention_reaction_do_nothing
---
{$aggressorName} smirketh.
-> Continue
===

title: DialoguePoint/intervention_reaction_protest
---
{$aggressorName} returneth a chill note.
-> Continue
===
''';

/// Minimal [Game] with two GPs and one minor nation, sufficient to drive the
/// overture / intervention overlays through their phase-1 Yarn intro.
Game _minimalGame() {
  return Game(
    id: 'combined_golden_game',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false, treasury: 0),
    ],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Powhatan'),
    ],
  );
}

/// Advance the active Yarn line by tapping the single line-step
/// [CtNinePatchButton], settling on the subsequent choice step.
Future<void> _advanceToChoice(WidgetTester tester) async {
  expect(find.byType(CtNinePatchButton), findsOneWidget);
  await tester.tap(find.byType(CtNinePatchButton));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'OVL10001 combined-step golden: intro narrative stays above the "I shall." option (#3628)',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(600, 800));
      const boundaryKey = ValueKey<String>('game_start_intro_combined_golden');

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.editorialMonocle,
          home: RepaintBoundary(
            key: boundaryKey,
            child: GameStartIntroOverlay(
              assetBundle: _StringAssetBundle({
                kDialogueGameIntroAsset: _kIntroYarn,
              }),
              onDismissed: () {},
              child: const ColoredBox(color: Color(0xFF101014)),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Line step: narrative + a single Continue affordance.
      expect(find.textContaining('imperialism'), findsOneWidget);

      await _advanceToChoice(tester);

      // Combined step: narrative remains visible together with the option.
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.textContaining('imperialism'), findsOneWidget);
      expect(find.text('I shall.'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/dialogue_combined_game_start_intro_choice.png'),
      );
    },
  );

  testWidgets(
    'OVL80001 combined-step golden: scout narrative + tribe/capital stay above the Continue option (#3628)',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(600, 800));
      const boundaryKey = ValueKey<String>(
        'tribe_first_contact_combined_golden',
      );

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.editorialMonocle,
          home: RepaintBoundary(
            key: boundaryKey,
            child: TribeFirstContactOverlay(
              tribeName: 'Powhatan',
              capitalName: 'Werowocomoco',
              assetBundle: _StringAssetBundle({
                kDialogueTribeFirstContactAsset: _kHeraldYarn,
              }),
              onDismissed: () {},
              child: const ColoredBox(color: Color(0xFF101014)),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Line step: scout narrative with interpolated names + one Continue.
      expect(find.textContaining('Scouts'), findsOneWidget);
      expect(find.textContaining('Powhatan'), findsOneWidget);

      await _advanceToChoice(tester);

      // Combined step: narrative (with interpolated names) remains visible
      // together with the Continue option button.
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.textContaining('Scouts'), findsOneWidget);
      expect(find.textContaining('Powhatan'), findsOneWidget);
      expect(find.textContaining('Werowocomoco'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/dialogue_combined_tribe_first_contact_choice.png',
        ),
      );
    },
  );

  testWidgets(
    'Overture combined-step golden: intro narrative stays above the Continue option (#3628)',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(600, 800));
      const boundaryKey = ValueKey<String>('overture_intro_combined_golden');

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.editorialMonocle,
          home: RepaintBoundary(
            key: boundaryKey,
            child: OvertureDialogueOverlay(
              game: _minimalGame(),
              pendingOvertures: const [
                OvertureOffer(
                  offererGpId: 'gp2',
                  targetFactionId: 'gp1',
                  stage: OvertureStage.embassy,
                ),
              ],
              assetBundle: _StringAssetBundle({
                kDialogueOvertureAsset: _kOvertureYarn,
              }),
              onDecisions: (_) {},
              child: const ColoredBox(color: Color(0xFF101014)),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Line step: intro narrative + one Continue affordance.
      expect(find.textContaining('Envoys'), findsOneWidget);

      await _advanceToChoice(tester);

      // Combined step: narrative remains visible together with the option.
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.textContaining('Envoys'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/dialogue_combined_overture_intro_choice.png'),
      );
    },
  );

  testWidgets(
    'Intervention combined-step golden: intro narrative stays above the Continue option (#3628)',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(600, 800));
      const boundaryKey = ValueKey<String>('intervention_intro_combined_golden');

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.editorialMonocle,
          home: RepaintBoundary(
            key: boundaryKey,
            child: InterventionDialogueOverlay(
              game: _minimalGame(),
              prompts: const [
                InterventionPrompt(
                  aggressorGpId: 'gp2',
                  defenderMinorOrTribeId: 'minor1',
                  interveningGpId: 'gp1',
                ),
              ],
              assetBundle: _StringAssetBundle({
                kDialogueInterventionAsset: _kInterventionYarn,
              }),
              onDecisions: (_) {},
              child: const ColoredBox(color: Color(0xFF101014)),
            ),
          ),
        ),
      );
      // The intervention flow chains several async setState hops (parse →
      // runner → startDialogue → onLineStart); pump repeatedly until the
      // intro line resolves rather than relying on a single fixed delay.
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        if (find.textContaining('Heavy tidings').evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Line step: intro narrative + one Continue affordance.
      expect(find.textContaining('Heavy tidings'), findsOneWidget);

      await _advanceToChoice(tester);

      // Combined step: narrative remains visible together with the option.
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.textContaining('Heavy tidings'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/dialogue_combined_intervention_intro_choice.png',
        ),
      );
    },
  );
}
