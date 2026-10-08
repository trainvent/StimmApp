import 'package:flutter/material.dart';
import 'package:stimmapp/core/constants/dimension_constants.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';

/// Shared typography and spacing for compact tags.
class TagWrap extends StatelessWidget {
  const TagWrap({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        chipTheme: theme.chipTheme.copyWith(
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(
            horizontal: DConst.tagHorizontalPadding,
          ),
          labelStyle:
              (theme.chipTheme.labelStyle ??
                      theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ))
                  ?.copyWith(fontSize: AppTextStyles.descriptionText.fontSize),
        ),
      ),
      child: Wrap(
        spacing: DConst.minimalPadding,
        runSpacing: DConst.minimalPadding,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}
