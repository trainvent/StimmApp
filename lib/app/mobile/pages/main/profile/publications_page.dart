import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/form_export_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/running_forms_page.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_bar_scaffold.dart';
import 'package:stimmapp/app/mobile/widgets/pointing_list_tile.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/generated/l10n.dart';

class PublicationsPage extends StatelessWidget {
  const PublicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBarScaffold(
      title: context.l10n.publications,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PointingListTile(
              title: Text(S.of(context).runningForms),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RunningFormsPage(),
                  ),
                );
              },
            ),
            PointingListTile(
              title: Text(context.l10n.finishedForms),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FormExportPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
