import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/home/creator/petition_creator_page.dart';
import 'package:stimmapp/app/mobile/pages/main/home/creator/poll_creator_page.dart';
import 'package:stimmapp/app/mobile/pages/main/home/home_navigation_config.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/profile_page.dart';
import 'package:stimmapp/app/mobile/pages/main/settings/settings_page.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/creation_floating_action_button.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/creation_icon_button.dart';
import 'package:stimmapp/app/mobile/widgets/navbar_widget.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/notifiers.dart';

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUrl = authService.currentUser?.photoURL;

    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        final pages = mainPagesConfig(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(pages[selectedPage].title),
            leading: selectedPage == 0
                ? CreationIconButton(
                    type: CreationType.petition,
                    pageBuilder: (context) => const PetitionCreatorPage(),
                  )
                : selectedPage == 1
                ? CreationIconButton(
                    type: CreationType.poll,
                    pageBuilder: (context) => const PollCreatorPage(),
                  )
                : null,
            actions: [
              IconButton(
                key: keys.widgetTree.profileButton,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                },
                icon: currentUrl != null
                    ? CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.transparent,
                        child: ClipOval(
                          child: Image.network(
                            currentUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, size: 18);
                            },
                          ),
                        ),
                      )
                    : const CircleAvatar(
                        radius: 18,
                        child: Icon(Icons.person, size: 18),
                      ),
                tooltip: context.l10n.myProfile,
              ),
              IconButton(
                key: keys.widgetTree.settingsButton,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SettingsPage(title: context.l10n.settings),
                    ),
                  );
                },
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          body: pages[selectedPage].page,
          bottomNavigationBar: const NavbarWidget(),
        );
      },
    );
  }
}
