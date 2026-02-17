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
      itemBuilder: (context, p) {
        return ListTile(
          leading: p.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    p.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                  ),
                )
              : null,
          title: Text(p.title),
          subtitle: Text(
            p.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_note, size: 18),
              const SizedBox(width: 4),
              Text(p.signatureCount.toString()),
            ],
          ),
          onTap: () {
            Navigator.of(context).pushNamed('/petition/${p.id}');
          },
        );
      },
    );
  }
}
