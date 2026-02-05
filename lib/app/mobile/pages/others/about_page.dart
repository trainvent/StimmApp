import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_bar_scaffold.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_padding_scaffold.dart';
import 'package:stimmapp/app/mobile/widgets/neon_padding_widget.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:stimmapp/generated/l10n.dart';

class Contributor {
  final String name;
  final String role;
  final String? email;
  final String? github;
  final String? linkedin;

  const Contributor({
    required this.name,
    required this.role,
    this.email,
    this.github,
    this.linkedin,
  });
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final contributors = [
      const Contributor(
        name: 'Team LeEd',
        role: 'Core Development',
        email: 'contact@stimmapp.org',
      ),
      const Contributor(
        name: 'Yannic',
        role: 'Lead Developer',
        github: 'https://github.com/yannic',
      ),
      const Contributor(
        name: 'Seva',
        role: 'Intern',
        email: 'vyslezhivayu@gmail.com',
      ),
    ];

    return AppBarScaffold(
      title: context.l10n.aboutThisApp,
      child: AppPaddingScaffold(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Center(child:Image.asset("assets/images/cropped-LeLogo.png")),
          const SizedBox(height: 10),
          Center(
            child: Text(context.l10n.stimmapp, style: AppTextStyles.xxlBold),
          ),
          const SizedBox(height: 40),
          NeonPaddingWidget(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    S.of(context).thisAppWasDevelopedBy + ' ' + "Team Vogelcode",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.m,
                  ),
                ),
                const Divider(),
                ...contributors.map((c) => _buildContributorTile(context, c)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                    style: AppTextStyles.descriptionText,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildContributorTile(BuildContext context, Contributor contributor) {
    return ListTile(
      title: Text(contributor.name, style: AppTextStyles.mBold),
      subtitle: Text(contributor.role, style: AppTextStyles.descriptionText),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (contributor.email != null)
            IconButton(
              icon: const Icon(Icons.email_outlined),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: contributor.email!));
                showSuccessSnackBar(S.of(context).emailCopiedToClipboard);
              },
            ),
          if (contributor.github != null)
            IconButton(
              icon: const Icon(Icons.code),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: contributor.github!));
                showSuccessSnackBar(S.of(context).githubLinkCopiedToClipboard);
              },
            ),
          if (contributor.linkedin != null)
            IconButton(
              icon: const Icon(Icons.business),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: contributor.linkedin!));
                showSuccessSnackBar(S.of(context).linkedinLinkCopiedToClipboard);
              },
            ),
        ],
      ),
    );
  }
}
