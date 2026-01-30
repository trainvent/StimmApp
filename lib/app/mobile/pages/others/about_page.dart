import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_bar_scaffold.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_padding_scaffold.dart';
import 'package:stimmapp/app/mobile/widgets/neon_padding_widget.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';

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
          const Center(child: Text('🔐', style: AppTextStyles.icons)),
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
                    context.l10n.devContactInformation,
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
            child: Text('Version 1.0.0', style: AppTextStyles.descriptionText),
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
                // TODO: Implement email launch (e.g. using url_launcher)
              },
            ),
          if (contributor.github != null)
            IconButton(
              icon: const Icon(Icons.code),
              onPressed: () {
                // TODO: Implement URL launch
              },
            ),
          if (contributor.linkedin != null)
            IconButton(
              icon: const Icon(Icons.business),
              onPressed: () {
                // TODO: Implement URL launch
              },
            ),
        ],
      ),
    );
  }
}
