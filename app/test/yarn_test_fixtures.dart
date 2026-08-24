// Shared in-memory Yarn [AssetBundle] fakes and short dialogue snippets for
// dialogue overlay pins (Refs #3952). Lives outside `app/test/support/` so
// Yarn scenario fixtures do not count toward `repo.app_test_support_loc`.
// Re-exported from `app/test/support/yarn_test_fixtures.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [AssetBundle] keyed by asset path → Yarn text.
class YarnStringAssetBundle extends Fake implements AssetBundle {
  YarnStringAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final text = _assets[key];
    if (text == null) throw Exception('missing asset: $key');
    return text;
  }
}

/// [AssetBundle] that returns the same Yarn text for every key.
class YarnInlineAssetBundle extends Fake implements AssetBundle {
  YarnInlineAssetBundle(this._text);

  final String _text;

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future<String>.value(_text);
  }
}

/// [AssetBundle] that fails [loadString] with [error] (default missing asset).
class YarnThrowingAssetBundle extends Fake implements AssetBundle {
  YarnThrowingAssetBundle({Object? error})
    : _error = error ?? Exception('missing asset');

  final Object _error;

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future<String>.error(_error);
  }
}

/// [AssetBundle] whose Yarn lacks the expected intro node title.
class YarnMissingNodeAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future<String>.value(
      'title: not_the_intro\n---\nIrrelevant.\n===\n',
    );
  }
}

/// Short `game_start_intro` node (one narrative line + `-> I shall.`).
const String kYarnGameStartIntroShort = '''
title: game_start_intro
---
The age of imperialism draweth nigh.
-> I shall.
===
''';

/// Short tribe-first-contact herald with `{\$var}` interpolation.
const String kYarnTribeFirstContactShort = '''
title: tribe_first_contact
---
Scouts return with word of the {\$tribeName}, who hold their seat at {\$capitalName}.
-> Continue
===
''';

/// Longer tribe-first-contact herald used by diplomacy / overlay AC pins.
const String kYarnTribeFirstContactHerald = '''
title: tribe_first_contact
---
Scouts return from the New World with word of a people hitherto unknown to thy crown. They name themselves {\$tribeName}, and hold their seat at {\$capitalName}.
-> Continue
===
''';

/// Short overture intro node (one narrative line + `-> Continue`).
const String kYarnOvertureIntroShort = '''
title: DialoguePoint/overture_target_response
---
Envoys await thy word on the overtures laid before the Crown.
-> Continue
===
''';

/// Minimal multi-node intervention yarn (intro collapses to a combined step).
const String kYarnInterventionCombinedShort = r'''
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

/// Minimal intervention yarn for choice-picker Effect pins (Refs #4267).
const String kYarnInterventionMinimal = r'''
title: DialoguePoint/intervention_intro
---
Heavy tidings cross thy desk.
-> Continue
===

title: DialoguePoint/intervention_situation
---
Dispatch from thy minister.
-> Continue
===

title: DialoguePoint/intervention_reaction_intervene
---
Reaction.
-> Continue
===

title: DialoguePoint/intervention_reaction_do_nothing
---
Reaction.
-> Continue
===

title: DialoguePoint/intervention_reaction_protest
---
Reaction.
-> Continue
===
''';

/// Trace / choice-path yarn used by dialogue overlay spec pins.
const String kYarnTraceStory = '''
title: trace_story
---
First line.
-> Continue
-> Stop
===
''';
