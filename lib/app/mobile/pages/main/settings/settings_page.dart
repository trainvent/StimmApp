import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/profile_page.dart';
import 'package:stimmapp/app/mobile/pages/others/about_page.dart';
import 'package:stimmapp/app/mobile/widgets/selection_notifier_dialog.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/notifiers.dart';
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
  @override
  Widget build(BuildContext context) {
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
                  trailing: const Icon(
                    Icons.arrow_forward_ios_outlined,
                    color: Colors.white38,
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
                onTap: () async {
                  isDarkModeNotifier.value = !isDarkModeNotifier.value;
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setBool('isDarkMode', isDarkModeNotifier.value);
                },
                trailing: ValueListenableBuilder(
                  valueListenable: isDarkModeNotifier,
                  builder: (context, isDarkMode, child) {
                    return Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    );
                  },
                ),
              ),
              ListTile(
                title: Text(context.l10n.changeLanguage),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => SelectionNotifierDialog<Locale>(
                      notifier: appLocale,
                      options: AppLocalizations.supportedLocales,
                      optionLabel: (ctx, locale) {
                        switch (locale.languageCode) {
                          case 'en':
                            return ctx.l10n.english;
                          case 'de':
                            return ctx.l10n.german;
                          default:
                            return locale.languageCode.toUpperCase();
                        }
                      },
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
                title: Text('Show Petition Reason (Experimental)'),
                trailing: ValueListenableBuilder<bool>(
                  valueListenable: showPetitionReasonNotifier,
                  builder: (context, value, child) {
                    return Switch(
                      value: value,
                      onChanged: (newValue) {
                        showPetitionReasonNotifier.value = newValue;
                      },
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
                          S.of(context).publishedUnderTheGnuGeneralPublicLicenseV30,
                          style: AppTextStyles.m,
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () async {
                              // Add your app's license to the registry before showing the page
                          /*    LicenseRegistry.addLicense(() async* {
                                try {
                                  final license = await rootBundle.loadString('LICENSE');
                                  yield LicenseEntryWithLineBreaks(
                                    ['stimmapp'],
                                    license,
                                  );
                                } catch (e) {
                                  debugPrint('Failed to load LICENSE file: $e');
                                }
                              });*/
                              
                              if (!context.mounted) return;
                              showLicensePage(
                                context: context,
                                applicationName: IConst.appName,
                                applicationVersion: '1.0.0', // Or fetch dynamically
                                applicationIcon: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    "assets/images/cropped-LeLogo.png",
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
