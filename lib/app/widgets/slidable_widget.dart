import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

const double _swipeActionThreshold = 0.3;

enum AppSlidableActionStyle { primary, secondary, destructive }

class AppSlidableAction {
  const AppSlidableAction({
    required this.icon,
    required this.label,
    this.onPressed,
    this.style = AppSlidableActionStyle.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final AppSlidableActionStyle style;
}

class AppSlidable extends StatefulWidget {
  const AppSlidable({
    super.key,
    required this.child,
    this.startAction,
    this.endAction,
    this.enabled = true,
    this.showSwipeHint = false,
    this.onStartSwipe,
    this.onEndSwipe,
  });

  final Widget child;
  final AppSlidableAction? startAction;
  final AppSlidableAction? endAction;
  final bool enabled;

  /// Reveal both swipe actions once when this tile first appears.
  final bool showSwipeHint;
  final Future<void> Function()? onStartSwipe;
  final Future<void> Function()? onEndSwipe;

  @override
  State<AppSlidable> createState() => _AppSlidableState();
}

class _AppSlidableState extends State<AppSlidable>
    with SingleTickerProviderStateMixin {
  SlidableController? _controller;
  Timer? _hintTimer;
  bool _hintCancelled = false;
  bool _hintRunning = false;
  int? _activePointer;
  Offset? _pointerDownPosition;
  bool _pointerStartedClosed = true;

  @override
  void initState() {
    super.initState();
    _controller = SlidableController(this);
    if (widget.showSwipeHint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            _hintCancelled ||
            MediaQuery.disableAnimationsOf(context)) {
          return;
        }
        _hintTimer = Timer(const Duration(milliseconds: 300), _playSwipeHint);
      });
    }
  }

  @override
  void dispose() {
    _hintCancelled = true;
    _hintTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  bool get _canContinueHint =>
      mounted &&
      !_hintCancelled &&
      widget.enabled &&
      !MediaQuery.disableAnimationsOf(context);

  Future<void> _playSwipeHint() async {
    if (!_canContinueHint) return;
    _hintRunning = true;
    final isLtr = Directionality.of(context) == TextDirection.ltr;
    final leftAction = isLtr ? widget.endAction : widget.startAction;
    final rightAction = isLtr ? widget.startAction : widget.endAction;
    for (final (action, ratio) in [
      (leftAction, isLtr ? -0.125 : 0.125),
      (rightAction, isLtr ? 0.125 : -0.125),
    ]) {
      if (action == null) continue;
      await _slidableController.openTo(
        ratio,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
      );
      if (!_canContinueHint) return;
      await _slidableController.close(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInCubic,
      );
      if (!_canContinueHint) return;
    }
    _hintRunning = false;
  }

  SlidableController get _slidableController =>
      _controller ??= SlidableController(this);

  (Color, Color) _colors(ColorScheme colors, AppSlidableActionStyle style) =>
      switch (style) {
        AppSlidableActionStyle.primary => (
          colors.primaryContainer,
          colors.onPrimaryContainer,
        ),
        AppSlidableActionStyle.secondary => (
          colors.secondaryContainer,
          colors.onSecondaryContainer,
        ),
        AppSlidableActionStyle.destructive => (
          colors.errorContainer,
          colors.onErrorContainer,
        ),
      };

  ActionPane? _pane(BuildContext context, AppSlidableAction? action) {
    if (action == null) {
      return null;
    }
    final (backgroundColor, foregroundColor) = _colors(
      Theme.of(context).colorScheme,
      action.style,
    );
    return ActionPane(
      motion: const StretchMotion(),
      openThreshold: _swipeActionThreshold,
      children: [
        SlidableAction(
          onPressed: action.onPressed == null
              ? null
              : (_) => action.onPressed!(),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          icon: action.icon,
          label: action.label,
        ),
      ],
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled || _activePointer != null) return;
    _hintCancelled = true;
    _hintTimer?.cancel();
    if (_hintRunning) {
      _hintRunning = false;
      unawaited(_slidableController.close(duration: Duration.zero));
    }
    _activePointer = event.pointer;
    _pointerDownPosition = event.localPosition;
    _pointerStartedClosed = _slidableController.ratio.abs() < 0.001;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    _pointerDownPosition = null;
    _pointerStartedClosed = true;
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) return;
    final start = _pointerDownPosition;
    final startedClosed = _pointerStartedClosed;
    _activePointer = null;
    _pointerDownPosition = null;
    _pointerStartedClosed = true;
    unawaited(_slidableController.close());
    if (start == null || !startedClosed) return;

    final delta = event.localPosition - start;
    final width = context.size?.width ?? 0;
    if (width <= 0 || delta.dx.abs() < width * _swipeActionThreshold) return;
    if (delta.dx.abs() <= delta.dy.abs()) return;

    final isLeftToRight = Directionality.of(context) == TextDirection.ltr;
    final revealsStart = isLeftToRight ? delta.dx > 0 : delta.dx < 0;
    final callback = revealsStart ? widget.onStartSwipe : widget.onEndSwipe;
    if (callback != null) unawaited(callback());
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerCancel: _handlePointerCancel,
      onPointerUp: _handlePointerUp,
      child: Slidable(
        controller: _slidableController,
        enabled: widget.enabled,
        startActionPane: _pane(context, widget.startAction),
        endActionPane: _pane(context, widget.endAction),
        child: widget.child,
      ),
    );
  }
}
