// Marionette discoverability for editorial-monocle Ct-* controls (Refs #4199 WS1).

import 'package:flutter/material.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import '../widgets/ct_action_text_button.dart';
import '../widgets/ct_back_button.dart';
import '../widgets/ct_circular_locate_button.dart';
import '../widgets/ct_danger_text_button.dart';
import '../widgets/ct_dropdown.dart';
import '../widgets/ct_icon_action.dart';
import '../widgets/ct_nine_patch_button.dart';
import '../widgets/ct_slider.dart';
import '../widgets/ct_toggle_switch.dart';

/// Canonical Marionette configuration for ColonizeThis debug agent playtests.
///
/// Marks primary Ct-* chrome as interactive and extracts player-visible labels
/// so Marionette `get_interactive_elements` / `tap(text: …)` work without
/// reading app source for keys.
const MarionetteConfiguration colonizethisMarionetteConfiguration =
    MarionetteConfiguration(
  isInteractiveWidget: colonizethisCtWidgetIsInteractive,
  shouldStopTraversal: colonizethisCtWidgetStopsTraversal,
  extractText: colonizethisExtractCtWidgetText,
);

/// Non-generic Ct-* widget types treated as Marionette interaction targets.
const Set<Type> colonizethisCtInteractiveWidgetTypes = {
  CtNinePatchButton,
  CtIconAction,
  CtActionTextButton,
  CtDangerTextButton,
  CtBackButton,
  CtCircularLocateButton,
  CtToggleSwitch,
  CtSlider,
};

/// Whether [type] is a ColonizeThis Ct-* control Marionette should list.
@visibleForTesting
bool colonizethisCtWidgetIsInteractive(Type type) {
  if (colonizethisCtInteractiveWidgetTypes.contains(type)) {
    return true;
  }
  return _isCtDropdownType(type);
}

/// Whether Marionette should stop descending past [type] (one element per
/// control with aggregated label text).
@visibleForTesting
bool colonizethisCtWidgetStopsTraversal(Type type) {
  return colonizethisCtWidgetIsInteractive(type);
}

/// Extracts player-visible text from a Ct-* widget [element], if any.
@visibleForTesting
String? colonizethisExtractCtWidgetText(Element element) {
  final Widget widget = element.widget;

  if (widget is CtActionTextButton) {
    return widget.semanticLabel ?? widget.tooltip ?? widget.label;
  }
  if (widget is CtDangerTextButton) {
    return widget.semanticLabel ?? widget.tooltip ?? widget.label;
  }
  if (widget is CtBackButton) {
    return widget.semanticLabel;
  }
  if (widget is CtIconAction) {
    return widget.semanticLabel ?? widget.tooltip;
  }
  if (widget is CtCircularLocateButton) {
    return widget.semanticLabel ?? widget.tooltip;
  }
  if (widget is CtNinePatchButton) {
    return _collectDescendantPlainText(element);
  }
  if (widget is CtDropdown) {
    return widget.marionetteVisibleLabel;
  }

  return null;
}

bool _isCtDropdownType(Type type) {
  final String name = type.toString();
  return name == 'CtDropdown' || name.startsWith('CtDropdown<');
}

String? _collectDescendantPlainText(Element root) {
  final StringBuffer buffer = StringBuffer();
  _appendPlainText(root, buffer);
  final String result = buffer.toString().trim();
  return result.isEmpty ? null : result;
}

void _appendPlainText(Element element, StringBuffer buffer) {
  final Widget widget = element.widget;
  if (widget is Text) {
    final String? data = widget.data ?? widget.textSpan?.toPlainText();
    if (data != null && data.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write(data);
    }
    return;
  }
  if (widget is RichText) {
    final String plain = widget.text.toPlainText().trim();
    if (plain.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write(plain);
    }
    return;
  }
  element.visitChildren((Element child) => _appendPlainText(child, buffer));
}
