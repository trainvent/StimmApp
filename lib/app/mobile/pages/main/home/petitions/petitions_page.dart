import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/home/base_overview_page.dart';
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
        return InkWell(
          onTap: () {
            Navigator.of(context).pushNamed('/petition/${p.id}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 100),
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            p.imageUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.square(
                                  dimension: 100,
                                  child: Icon(Icons.broken_image),
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 52),
                              child: DiscoveryStatusChips(
                                status: discoveryStatus,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_note, size: 18),
                        const SizedBox(width: 4),
                        Text(p.signatureCount.toString()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
