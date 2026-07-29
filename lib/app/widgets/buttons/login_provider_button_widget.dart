import 'package:flutter/material.dart';
import 'package:stimmapp/core/constants/app_assets.dart';
import 'package:stimmapp/core/constants/dimension_constants.dart';

enum LoginProvider { google, apple }

class LoginProviderButtonWidget extends StatelessWidget {
  const LoginProviderButtonWidget({
    super.key,
    required this.provider,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.isLoading = false,
  });

  final LoginProvider provider;
  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = isDark ? Colors.white : const Color(0xFF202124);
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : colors.surface;
    final borderColor = isDark
        ? const Color(0xFF5F6368)
        : const Color(0xFFDADCE0);

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            disabledBackgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            disabledForegroundColor: foregroundColor.withValues(alpha: 0.5),
            side: BorderSide(color: borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: isLoading
              ? SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: foregroundColor,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ProviderIcon(provider: provider),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProviderIcon extends StatelessWidget {
  const _ProviderIcon({required this.provider});

  final LoginProvider provider;

  @override
  Widget build(BuildContext context) {
    return switch (provider) {
      LoginProvider.google => Image.asset(
        AppAssets.googleLogo,
        width: 22,
        height: 22,
      ),
      LoginProvider.apple => const Icon(Icons.apple, size: 24),
    };
  }
}
