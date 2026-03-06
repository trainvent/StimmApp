import 'package:flutter/material.dart';
import 'package:stimmapp/core/constants/app_assets.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';

class HeroWidget extends StatelessWidget {
  const HeroWidget({super.key, this.title, this.nextPage});

  final String? title;
  final Widget? nextPage;

  @override
  Widget build(BuildContext context) {
    final currentUrl = authService.currentUser?.photoURL;
    return GestureDetector(
      onTap: nextPage != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return nextPage!;
                  },
                ),
              );
            }
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate 1/3 of the available width
          final size = constraints.maxWidth / 3;

          return Center(
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Hero(
                    tag: 'profile_picture',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: (currentUrl != null && currentUrl.isNotEmpty)
                          ? Image.network(
                              currentUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  AppAssets.defaultAvatar,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                );
                              },
                            )
                          : Image.asset(
                              AppAssets.defaultAvatar,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    ),
                  ),
                  if (title != null)
                    Text(
                      title!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 50,
                        letterSpacing: 50,
                        color: Colors.white24,
                      ),
                    ),
                  // Edit Icon Overlay
                  if (nextPage != null)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
