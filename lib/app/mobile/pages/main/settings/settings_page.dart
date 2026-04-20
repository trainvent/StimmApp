import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/profile_page.dart';
import 'package:stimmapp/app/mobile/pages/others/about_page.dart';
import 'package:stimmapp/app/mobile/widgets/selection_notifier_dialog.dart';
import 'package:stimmapp/core/constants/app_assets.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/notifiers.dart';
import 'package:stimmapp/core/theme/app_color_scheme.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.title});

  final String title;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
      case AppColorTheme.stimm:
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
                          return ProfilePage();
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
                      notifier: ValueNotifier<ThemeMode?>(
                        themeModeNotifier.value,
                      ),
                      options: ThemeMode.values,
                      optionLabel: _themeModeLabel,
                      title: context.l10n.colorTheme,
                      confirmLabel: context.l10n.confirm,
                      cancelLabel: context.l10n.cancel,
                      onConfirm: (ThemeMode? selected) async {
                        if (selected == null) return;
                        themeModeNotifier.value = selected;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(
                          IConst.themeModeKey,
                          selected.name,
                        );
                      },
                    ),
                  );
                },
                trailing: ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeModeNotifier,
                  builder: (context, mode, child) {
                    IconData icon;
                    switch (mode) {
                      case ThemeMode.system:
                        icon = Icons.brightness_auto;
                        break;
                      case ThemeMode.light:
                        icon = Icons.light_mode;
                        break;
                      case ThemeMode.dark:
                        icon = Icons.dark_mode;
                        break;
                    }
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_themeModeLabel(context, mode)),
                        const SizedBox(width: 8),
                        Icon(icon),
                      ],
                    );
                  },
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
                            themeSchemeNotifier.value ??
                                AppColorTheme.trainvent,
                          ),
                          options: AppColorTheme.values,
                          optionLabel: _themeSchemeLabel,
                          optionLeading: (ctx, theme) => _themePreview(theme),
                          title: context.l10n.accentPallette,
                          confirmLabel: context.l10n.confirm,
                          cancelLabel: context.l10n.cancel,
                          onConfirm: (AppColorTheme? selected) async {
                            if (selected == null) return;
                            themeSchemeNotifier.value = selected;
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString(
                              IConst.themeSchemeKey,
                              selected.data.id,
                            );
                          },
                        ),
                  );
                },
                trailing: ValueListenableBuilder<AppColorTheme?>(
                  valueListenable: themeSchemeNotifier,
                  builder: (context, theme, child) {
                    final selected = theme ?? AppColorTheme.trainvent;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_themeSchemeLabel(context, selected)),
                        const SizedBox(width: 10),
                        _themePreview(selected, size: 12, spacing: 4),
                      ],
                    );
                  },
                ),
              ),
              ListTile(
                title: Text(context.l10n.changeLanguage),
                trailing: ValueListenableBuilder<Locale?>(
                  valueListenable: appLocale,
                  builder: (context, locale, child) {
                    final selectedLocale =
                        locale ?? Localizations.localeOf(context);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _languageFlag(selectedLocale),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(_languageLabel(context, selectedLocale)),
                      ],
                    );
                  },
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => SelectionNotifierDialog<Locale>(
                      notifier: appLocale,
                      options: AppLocalizations.supportedLocales,
                      optionLabel: _languageLabel,
                      optionLeading: (ctx, locale) => Text(
                        _languageFlag(locale),
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: context.l10n.language,
                      confirmLabel: context.l10n.confirm,
                      cancelLabel: context.l10n.cancel,
                      onConfirm: (Locale? selected) async {
                        final prefs = await SharedPreferences.getInstance();
                        String toSave = '';
                        if (selected != null) {
                          toSave =
                              selected.countryCode == null ||
                                  selected.countryCode!.isEmpty
                              ? selected.languageCode
                              : '${selected.languageCode}_${selected.countryCode}';
                        }
                        await prefs.setString(IConst.localeKey, toSave);
                      },
                    ),
                  );
                },
              ),
              ListTile(
                title: Text(S.of(context).signatureReasoning),
                trailing: ValueListenableBuilder<bool>(
                  valueListenable: showPetitionReasonNotifier,
                  builder: (context, value, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(S.of(context).signatureReasoning),
                                content: Text(
                                  context.l10n.signatureReasoningInfo,
                                ),
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
                          value: value,
                          onChanged: (newValue) {
                            showPetitionReasonNotifier.value = newValue;
                          },
                        ),
                      ],
                    );
                  },
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
              Divider(color: Colors.teal, thickness: 5),
            ],
          ),
        ),
      ),
    );
  }
}
