import 'package:flutter/material.dart';

class FormListTileWidget extends StatelessWidget {
  const FormListTileWidget({
    super.key,
    required this.title,
    required this.description,
    required this.count,
    required this.countIcon,
    required this.onTap,
    this.thumbnail,
    this.status,
  });

  static const double thumbnailSize = 100;

  final String title;
  final String description;
  final int count;
  final IconData countIcon;
  final VoidCallback onTap;
  final Widget? thumbnail;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: thumbnailSize),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (thumbnail != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox.square(
                      dimension: thumbnailSize,
                      child: thumbnail,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (status != null) Expanded(child: status!),
                          if (status != null) const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(countIcon, size: 18),
                              const SizedBox(width: 4),
                              Text(count.toString()),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
