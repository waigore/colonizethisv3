// AI dialogue and mood events. SPEC/ai/dialogue-and-mood.md, SPEC/program/ai-events-and-dossier.md.
// Phase 6: emitted by colonizethis_ai; consumed by UI or tooling.
//
// DialogueEvent and PortraitMoodEvent extend AppEvent so they can flow through AppEventBus.

import 'app_events.dart';

/// Emitted when AI should display a dialogue line.
/// UI resolves (leaderId, category, situation, era, mood, variables) to text.
class DialogueEvent extends AppEvent {
  const DialogueEvent({
    required this.leaderId,
    required this.category,
    required this.situation,
    required this.era,
    this.mood,
    this.variables = const {},
  });

  final String leaderId;
  final String category;
  final String situation;
  final String era;
  final String? mood;
  final Map<String, String> variables;

  Map<String, dynamic> toJson() => {
    'leaderId': leaderId,
    'category': category,
    'situation': situation,
    'era': era,
    if (mood != null) 'mood': mood,
    if (variables.isNotEmpty) 'variables': Map<String, String>.from(variables),
  };

  static DialogueEvent fromJson(Map<String, dynamic> json) {
    final vars = json['variables'];
    return DialogueEvent(
      leaderId: json['leaderId'] as String,
      category: json['category'] as String,
      situation: json['situation'] as String,
      era: json['era'] as String,
      mood: json['mood'] as String?,
      variables: vars is Map<dynamic, dynamic>
          ? Map<String, String>.from(
              vars.map((k, v) => MapEntry(k.toString(), v.toString())),
            )
          : const {},
    );
  }
}

/// Emitted when portrait mood should change (e.g. during negotiation).
/// UI uses for portrait/animation choice.
class PortraitMoodEvent extends AppEvent {
  const PortraitMoodEvent({
    required this.leaderId,
    required this.fromMood,
    required this.toMood,
    this.durationMs = 0,
  });

  final String leaderId;
  final String fromMood;
  final String toMood;
  final int durationMs;

  Map<String, dynamic> toJson() => {
    'leaderId': leaderId,
    'fromMood': fromMood,
    'toMood': toMood,
    'durationMs': durationMs,
  };

  static PortraitMoodEvent fromJson(Map<String, dynamic> json) {
    return PortraitMoodEvent(
      leaderId: json['leaderId'] as String,
      fromMood: json['fromMood'] as String,
      toMood: json['toMood'] as String,
      durationMs: json['durationMs'] as int? ?? 0,
    );
  }
}
