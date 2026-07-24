import 'package:flutter/material.dart';
import 'package:stimmapp/app/pages/main/home/base_overview_page.dart';
import 'package:stimmapp/app/widgets/form_list_tile_widget.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';

class PetitionsPage extends StatelessWidget {
  const PetitionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PetitionRepository.create();
    return BaseOverviewPage<Petition>(
      streamProvider: (query, status) =>
          repo.list(query: query, status: status),
      participatedIdsStreamProvider: repo.watchSignedPetitionIds,
      itemBuilder: (context, p, discoveryStatus) {
        return FormListTileWidget(
          title: p.title,
          description: p.description,
          count: p.signatureCount,
          countIcon: Icons.edit_note,
          status: DiscoveryStatusChips(status: discoveryStatus),
          thumbnail: p.imageUrl == null
              ? null
              : Image.network(
                  p.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
          onTap: () {
            Navigator.of(context).pushNamed('/petition/${p.id}');
          },
        );
      },
    );
  }
}
