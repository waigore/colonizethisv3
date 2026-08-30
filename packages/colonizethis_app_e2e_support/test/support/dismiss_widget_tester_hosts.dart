import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';

/// [AlertDialog] with labelled [TextButton] actions and per-label tap counters.
Widget labelledActionAlertDialog({
  required String title,
  required List<String> labels,
  required Map<String, int> tapCounts,
}) {
  return Builder(
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        actions: [
          for (final label in labels)
            TextButton(
              onPressed: () {
                tapCounts[label] = (tapCounts[label] ?? 0) + 1;
                Navigator.of(context).pop();
              },
              child: Text(label),
            ),
        ],
      );
    },
  );
}

/// Surfaces a route via `showDialog` once after the first frame so test
/// bodies can assert against a steady dialog without driving `showDialog`
/// from a stateless [Widget.build].
///
/// Used for [AlertDialog] and route-mounted [CtDialogShell] fixtures.
class DismissPostFrameDialogHost extends StatefulWidget {
  const DismissPostFrameDialogHost({
    super.key,
    required this.dialogBuilder,
    this.barrierDismissible = false,
  });

  final WidgetBuilder dialogBuilder;
  final bool barrierDismissible;

  @override
  State<DismissPostFrameDialogHost> createState() =>
      _DismissPostFrameDialogHostState();
}

class _DismissPostFrameDialogHostState
    extends State<DismissPostFrameDialogHost> {
  bool _shown = false;

  void _show(BuildContext context) {
    if (_shown) return;
    _shown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: widget.barrierDismissible,
      builder: widget.dialogBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (innerCtx) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _show(innerCtx));
          return const SizedBox.expand();
        },
      ),
    );
  }
}

/// Surfaces a [SnackBar] once after the first frame via [ScaffoldMessenger].
class DismissSnackBarHost extends StatefulWidget {
  const DismissSnackBarHost({super.key, required this.snackBar});

  final SnackBar snackBar;

  @override
  State<DismissSnackBarHost> createState() => _DismissSnackBarHostState();
}

class _DismissSnackBarHostState extends State<DismissSnackBarHost> {
  bool _shown = false;

  void _show(BuildContext context) {
    if (_shown) return;
    _shown = true;
    ScaffoldMessenger.of(context).showSnackBar(widget.snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (innerCtx) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _show(innerCtx));
          return const SizedBox.expand();
        },
      ),
    );
  }
}

/// Hosts a [CtDialogShell] whose contents receive a [close] callback that
/// unmounts the shell (state flip to [SizedBox.shrink]).
class DismissCtDialogShellHost extends StatefulWidget {
  const DismissCtDialogShellHost({super.key, required this.builder});

  final Widget Function(BuildContext context, VoidCallback close) builder;

  @override
  State<DismissCtDialogShellHost> createState() =>
      _DismissCtDialogShellHostState();
}

class _DismissCtDialogShellHostState extends State<DismissCtDialogShellHost> {
  bool open = true;

  void _close() {
    setState(() => open = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!open) {
      return const SizedBox.shrink();
    }
    return CtDialogShell(child: widget.builder(context, _close));
  }
}

/// Stacks an opaque [AbsorbPointer] fill over [child] so the child remains
/// mounted but non-hit-testable — the hit-testable-filter fixture pattern.
Widget absorbPointerCover({required Widget child}) {
  return Stack(
    children: [
      child,
      const Positioned.fill(
        child: AbsorbPointer(child: ColoredBox(color: Color(0xFFFF0000))),
      ),
    ],
  );
}

/// AlertDialog whose first labelled action is covered (non-hit-testable) and
/// whose second labelled action remains hit-testable.
Widget coveredFirstActionAlertDialog({
  required String firstLabel,
  required String secondLabel,
}) {
  return Builder(
    builder: (context) {
      return AlertDialog(
        title: const Text('covered-first-dialog'),
        actions: [
          SizedBox(
            width: 120,
            height: 48,
            child: absorbPointerCover(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(firstLabel),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(secondLabel),
          ),
        ],
      );
    },
  );
}
