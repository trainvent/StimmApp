import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

enum AppSlidableActionStyle { primary, secondary, destructive }

class AppSlidableAction {
  const AppSlidableAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.style = AppSlidableActionStyle.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final AppSlidableActionStyle style;
}

class AppSlidable extends StatelessWidget {
  const AppSlidable({
    super.key,
    required this.child,
    this.startAction,
    this.endAction,
    this.enabled = true,
    this.confirmStartDismiss,
    this.confirmEndDismiss,
  });

  final Widget child;
  final AppSlidableAction? startAction;
  final AppSlidableAction? endAction;
  final bool enabled;
  final Future<bool> Function()? confirmStartDismiss;
  final Future<bool> Function()? confirmEndDismiss;

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

  ActionPane? _pane(
    BuildContext context,
    AppSlidableAction? action, {
    Future<bool> Function()? confirmDismiss,
  }) {
    if (action == null) {
      return null;
    }
    final (backgroundColor, foregroundColor) = _colors(
      Theme.of(context).colorScheme,
      action.style,
    );
    return ActionPane(
      motion: const StretchMotion(),
      dismissible: confirmDismiss == null
          ? null
          : DismissiblePane(
              dismissThreshold: 0.3,
              confirmDismiss: confirmDismiss,
              closeOnCancel: true,
              onDismissed: () {},
            ),
      children: [
        SlidableAction(
          onPressed: (_) => action.onPressed(),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          icon: action.icon,
          label: action.label,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: key,
      enabled: enabled,
      startActionPane: _pane(
        context,
        startAction,
        confirmDismiss: confirmStartDismiss,
      ),
      endActionPane: _pane(
        context,
        endAction,
        confirmDismiss: confirmEndDismiss,
      ),
      child: child,
    );
  }
}
