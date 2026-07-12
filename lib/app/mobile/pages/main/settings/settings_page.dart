import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/profile_page.dart';
import 'package:stimmapp/app/mobile/pages/others/about_page.dart';
import 'package:stimmapp/app/mobile/widgets/selection_notifier_dialog.dart';
import 'package:stimmapp/core/constants/app_assets.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/providers/app_preferences_provider.dart';
import 'package:stimmapp/core/theme/app_color_scheme.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  TextEditingController controller = TextEditingController();
  bool isChecked = false;
  bool isSwitched = false;
  double sliderValue = 0.0;
  String? menuItem = 'e1';

  String _languageLabel(BuildContext context, Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return context.l10n.english;
      case 'de':
        return context.l10n.german;
      default:
        return locale.languageCode.toUpperCase();
    }
  }

  String _languageFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return '🇬🇧';
      case 'de':
        return '🇩🇪';
      default:
        return '🌐';
    }
  }

  String _themeModeLabel(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  String _themeSchemeLabel(BuildContext context, AppColorTheme theme) {
    switch (theme) {
      case AppColorTheme.forest:
        return context.l10n.themePaletteForest;
      case AppColorTheme.ocean:
        return context.l10n.themePaletteOcean;
      case AppColorTheme.sunset:
        return context.l10n.themePaletteSunset;
      case AppColorTheme.rose:
        return context.l10n.themePaletteRose;
      case AppColorTheme.amber:
        return context.l10n.themePaletteAmber;
      case AppColorTheme.plum:
        return context.l10n.themePalettePlum;
      case AppColorTheme.slate:
        return context.l10n.themePaletteSlate;
      case AppColorTheme.mint:
        return context.l10n.themePaletteMint;
      case AppColorTheme.sky:
        return context.l10n.themePaletteSky;
      case AppColorTheme.trainvent:
        return context.l10n.themePaletteTrainvent;
    }
  }

  Widget _themePreview(
    AppColorTheme theme, {
    double size = 14,
    double spacing = 6,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: theme.data.previewColors.map((color) {
        final isLast = color == theme.data.previewColors.last;
        return Padding(
          padding: EdgeInsets.only(right: isLast ? 0 : spacing),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(size * 0.35),
              border: Border.all(color: Colors.black12),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl = authService.currentUser?.photoURL;
    final themeMode = ref.watch(themeModeProvider);
    final themeScheme = ref.watch(themeSchemeProvider);
    final locale = ref.watch(appLocaleProvider);
    final showPetitionReason = ref.watch(showPetitionReasonProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Material(
                type: MaterialType.transparency,
                child: ListTile(
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.transparent,
                        backgroundImage: const AssetImage(
                          AppAssets.defaultAvatar,
                        ),
                        foregroundImage:
                            currentUrl != null && currentUrl.isNotEmpty
                            ? NetworkImage(currentUrl)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_ios_outlined),
                    ],
                  ),
                  title: Text(context.l10n.myProfile),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const ProfilePage(settingsRouteIsBelow: true);
                        },
                      ),
                    );
                  },
                ),
              ),
              ListTile(
                title: Text(context.l10n.colorTheme),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => SelectionNotifierDialog<ThemeMode>(
                      notifier: ValueNotifier<ThemeMode?>(themeMode),
                      options: ThemeMode.values,
                      optionLabel: _themeModeLabel,
                      title: context.l10n.colorTheme,
                      confirmLabel: context.l10n.confirm,
                      cancelLabel: context.l10n.cancel,
                      onConfirm: (ThemeMode? selected) {
                        if (selected == null) return;
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(selected);
                      },
                    ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_themeModeLabel(context, themeMode)),
                    const SizedBox(width: 8),
                    Icon(switch (themeMode) {
                      ThemeMode.system => Icons.brightness_auto,
                      ThemeMode.light => Icons.light_mode,
                      ThemeMode.dark => Icons.dark_mode,
                    }),
                  ],
                ),
              ),
              ListTile(
                title: Text(context.l10n.accentPallette),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        SelectionNotifierDialog<AppColorTheme>(
                          notifier: ValueNotifier<AppColorTheme?>(
                            themeScheme ?? AppColorTheme.trainvent,
                          ),
                          options: AppColorTheme.values,
                          optionLabel: _themeSchemeLabel,
                          optionLeading: (ctx, theme) => _themePreview(theme),
                          title: context.l10n.accentPallette,
                          confirmLabel: context.l10n.confirm,
                          cancelLabel: context.l10n.cancel,
                          onConfirm: (AppColorTheme? selected) {
                            if (selected == null) return;
                            ref
                                .read(themeSchemeProvider.notifier)
                                .setThemeScheme(selected);
                          },
                        ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _themeSchemeLabel(
                        context,
                        themeScheme ?? AppColorTheme.trainvent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _themePreview(
                      themeScheme ?? AppColorTheme.trainvent,
                      size: 12,
                      spacing: 4,
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text(context.l10n.changeLanguage),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _languageFlag(locale ?? Localizations.localeOf(context)),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _languageLabel(
                        context,
                        locale ?? Localizations.localeOf(context),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => SelectionNotifierDialog<Locale>(
                      notifier: ValueNotifier<Locale?>(locale),
                      options: AppLocalizations.supportedLocales,
                      optionLabel: _languageLabel,
                      optionLeading: (ctx, locale) => Text(
                        _languageFlag(locale),
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: context.l10n.language,
                      confirmLabel: context.l10n.confirm,
                      cancelLabel: context.l10n.cancel,
                      onConfirm: (Locale? selected) {
                        ref
                            .read(appLocaleProvider.notifier)
                            .setLocale(selected);
                      },
                    ),
                  );
                },
              ),
              ListTile(
                title: Text(S.of(context).signatureReasoning),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(S.of(context).signatureReasoning),
                            content: Text(context.l10n.signatureReasoningInfo),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(context.l10n.close),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Switch(
                      value: showPetitionReason,
                      onChanged: (newValue) {
                        ref
                            .read(showPetitionReasonProvider.notifier)
                            .setEnabled(newValue);
                      },
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text(context.l10n.aboutThisApp),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return AboutPage();
                      },
                    ),
                  );
                },
              ),
              ListTile(
                title: Text(context.l10n.licenses),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(S.of(context).licenses),
                        content: Text(
                          S
                              .of(context)
                              .publishedUnderTheGnuGeneralPublicLicenseV30,
                          style: AppTextStyles.m,
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () async {
                              if (!context.mounted) return;
                              showLicensePage(
                                context: context,
                                applicationName: context.localizedAppName,
                                applicationVersion:
                                    '1.0.0', // Or fetch dynamically
                                applicationIcon: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    "assets/images/LeLogo.png",
                                    width: 48,
                                    height: 48,
                                  ),
                                ),
                              );
                            },
                            child: Text(context.l10n.viewLicenses),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(context.l10n.close),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              Divider(
                color: Theme.of(context).colorScheme.primary,
                thickness: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
