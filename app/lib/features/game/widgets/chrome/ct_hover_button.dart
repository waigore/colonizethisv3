// Shared hover/disabled/semantics chrome for the editorial-monocle Ct-* button
// family (Refs #3594 — dedup chrome buttons).
//
// Centralises the hover-state machine and the disabled-gate / interactive /
// semantics / tooltip wrapping that the chrome text/icon buttons all repeat,
// so each concrete button only describes its own painted surface.

import 'package:flutter/material.dart';

/// Mixin providing the canonical hover state machine and output-wrapping chrome
/// shared by the editorial-monocle chrome buttons
/// (`CtActionTextButton`, `CtDangerTextButton`, `CtCircularLocateButton`).
///
/// A concrete button's [State] mixes this in and supplies its painted
/// [buildHoverButton] surface plus the two widget-backed getters
/// ([hoverButtonEnabled], [hoverButtonOnPressed]). The mixin owns:
///
/// - the `_hovered` flag, [isInteractive] derivation, and [setHover] guard;
/// - the disabled gate (`Semantics(enabled:false)` + [IgnorePointer], with an
///   optional [Opacity] fade);
/// - the interactive wrapper (`MouseRegion` + `Material` + `InkWell`); and
/// - the `Semantics(button:true)` + optional [Tooltip] output wrapping.
///
/// No colour or token decisions live here — the surface (gradients, borders,
/// typography) stays with each concrete button so palette fidelity is
/// unchanged.
mixin CtHoverButtonStateMixin<T extends StatefulWidget> on State<T> {
  bool _hovered = false;

  /// Whether a pointer is currently hovering the interactive control.
  bool get hovered => _hovered;

  /// The owning widget's enabled flag.
  bool get hoverButtonEnabled;

  /// The owning widget's tap callback (may be `null`).
  VoidCallback? get hoverButtonOnPressed;

  /// A button is interactive only when enabled and given a tap callback.
  bool get isInteractive => hoverButtonEnabled && hoverButtonOnPressed != null;

  /// Updates the hover flag, ignoring changes while the control is not
  /// interactive or when the value is unchanged.
  void setHover(bool value) {
    if (!isInteractive) return;
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  /// Wraps a painted [surface] with the shared hover/disabled/semantics chrome.
  ///
  /// - [semanticLabel] is the resolved accessibility label (callers decide the
  ///   fallback, e.g. `semanticLabel ?? label` or `semanticLabel ?? tooltip`).
  /// - [tooltip] adds a pointer [Tooltip] when non-null.
  /// - [inkShape] makes the `Material`/`InkWell` non-rectangular (e.g. a
  ///   [CircleBorder] for the circular locate pill); when null the default
  ///   rectangular Material chrome is used.
  /// - [disabledOpacity] fades the disabled surface; pass null when the surface
  ///   already bakes in its disabled opacity.
  Widget buildHoverButton({
    required Widget surface,
    required String? semanticLabel,
    String? tooltip,
    ShapeBorder? inkShape,
    double? disabledOpacity,
  }) {
    if (!hoverButtonEnabled) {
      final Widget gated = disabledOpacity == null
          ? surface
          : Opacity(opacity: disabledOpacity, child: surface);
      return Semantics(
        button: true,
        enabled: false,
        label: semanticLabel,
        child: IgnorePointer(child: gated),
      );
    }

    final Widget interactive = MouseRegion(
      onEnter: (_) => setHover(true),
      onExit: (_) => setHover(false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        shape: inkShape,
        clipBehavior: inkShape == null ? Clip.none : Clip.antiAlias,
        child: InkWell(
          onTap: hoverButtonOnPressed,
          customBorder: inkShape,
          child: surface,
        ),
      ),
    );

    Widget wrapped = Semantics(
      button: true,
      enabled: true,
      label: semanticLabel,
      child: interactive,
    );

    if (tooltip != null) {
      wrapped = Tooltip(message: tooltip, child: wrapped);
    }
    return wrapped;
  }
}
