import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/mobile/pages/main/admin/admin_dashboard_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/blocked_users_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/group_access_inbox_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/publications_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/profile_settings/change_living_address_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/profile_settings/change_password_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/profile_settings/change_profile_picture_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/profile_settings/update_username_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/user_history_page.dart';
import 'package:stimmapp/app/mobile/pages/others/privacy_page.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_padding_scaffold.dart';
import 'package:stimmapp/app/mobile/widgets/hero_widget.dart';
import 'package:stimmapp/app/mobile/widgets/neon_padding_widget.dart';
import 'package:stimmapp/app/mobile/widgets/pointing_list_tile.dart';
import 'package:stimmapp/app/mobile/widgets/selection_notifier_dialog.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/services/purchases_service.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/notifiers/notifiers.dart';
import '../../../scaffolds/app_bar_scaffold.dart';
import 'delete_account_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _openManageSubscriptions(BuildContext context) async {
    if (kIsWeb) {
      final notifier = ValueNotifier<String?>(null);
      await showDialog(
        context: context,
        builder: (context) => SelectionNotifierDialog<String>(
          notifier: notifier,
          title: 'Select Payment Provider',
          options: const ['Google Play'],
          optionLabel: (context, option) => option,
          onConfirm: (selected) async {
            if (selected == 'Google Play') {
              final uri = Uri.parse(
                'https://play.google.com/store/account/subscriptions',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
        ),
      );
    } else {
      final Uri uri;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        uri = Uri.parse('https://apps.apple.com/account/subscriptions');
      } else {
        uri = Uri.parse('https://play.google.com/store/account/subscriptions');
      }
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        showErrorSnackBar(S.current.error);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await authService.signOut();
      if (!context.mounted) return;
      showSuccessSnackBar(S.of(context).loggedOutSuccessfully);
      AppData.isAuthConnected.value = false;
      AppData.navBarCurrentIndexNotifier.value = 0;
      AppData.onboardingCurrentIndexNotifier.value = 0;
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      if (context.mounted) {
        showErrorSnackBar(e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = authService.currentUser;

    return AppBarScaffold(
      title: context.l10n.myProfile,
      actions: [
        StreamBuilder<List<PollGroupAccessNotification>>(
          stream: currentUser == null
              ? null
              : PollGroupRepository.create().watchNotifications(
                  currentUser.uid,
                ),
          builder: (context, snapshot) {
            final pendingCount =
                (snapshot.data ?? const <PollGroupAccessNotification>[])
                    .where(
                      (item) =>
                          item.status ==
                          PollGroupAccessNotificationStatus.pending,
                    )
                    .length;
            return Badge.count(
              offset: const Offset(-5, 5),
              count: pendingCount,
              isLabelVisible: pendingCount > 0,
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GroupAccessInboxPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none),
              ),
            );
          },
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AppPaddingScaffold(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10.0),
            StreamBuilder<UserProfile?>(
              stream: currentUser != null
                  ? UserRepository.create().watchById(currentUser.uid)
                  : null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: TriangleLoadingIndicator());
                }
                if (snapshot.hasError) {
                  return Text('${context.l10n.error}${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return Text(context.l10n.userNotFound);
                }

                final userProfile = snapshot.data!;
                final dateFormat = DateFormat('yyyy-MM-dd');

                return Column(
                  children: [
                    NeonPaddingWidget(
                      isCentered: true,
                      child: Column(
                        children: [
                          HeroWidget(
                            key: keys.profilePage.heroWidget,
                            nextPage: const ChangeProfilePicturePage(),
                          ),
                          const SizedBox(height: 10),
                          _buildDetailTile(
                            context,
                            context.l10n.surname,
                            userProfile.surname,
                          ),
                          _buildDetailTile(
                            context,
                            context.l10n.givenName,
                            userProfile.givenName,
                          ),
                          _buildDetailTile(
                            context,
                            context.l10n.dateOfBirth,
                            userProfile.dateOfBirth != null
                                ? dateFormat.format(userProfile.dateOfBirth!)
                                : null,
                          ),
                          _buildDetailTile(
                            context,
                            context.l10n.placeOfBirth,
                            userProfile.placeOfBirth,
                          ),
                          _buildDetailTile(
                            context,
                            context.l10n.nationality,
                            userProfile.nationality,
                          ),
                          _buildDetailTile(
                            context,
                            context.l10n.idNumber,
                            userProfile.idNumber,
                          ),
                          _buildDetailTile(
                            context,
                            context.l10n.expiryDate,
                            userProfile.expiryDate != null
                                ? dateFormat.format(userProfile.expiryDate!)
                                : null,
                          ),
                          _buildDetailTile(
                            context,
                            context.l10n.height,
                            userProfile.height,
                          ),
                          _buildDetailTile(
                            context,
                            context.l10n.address,
                            userProfile.address,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChangeLivingAddressPage(),
                                ),
                              );
                            },
                          ),
                          if (userProfile.supportsStateScope)
                            _buildDetailTile(
                              context,
                              context.l10n.state,
                              userProfile.state,
                            ),
                          _buildDetailTile(
                            context,
                            context.l10n.town,
                            userProfile.town,
                          ),
                          _buildDetailTile(
                            key: keys.profilePage.changeEmailListTile,
                            context,
                            context.l10n.email,
                            userProfile.email,
                          ),
                          _buildDetailTile(
                            key: keys.profilePage.changeUserNameListTile,
                            context,
                            context.l10n.nickname,
                            userProfile.displayName,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UpdateUsernamePage(),
                                ),
                              );
                            },
                          ),

                          _buildDetailTile(
                            key: keys.profilePage.manageSubscriptionsListTile,
                            context,
                            context.l10n.proMember,
                            userProfile.isPro == true
                                ? context.l10n.yes
                                : context.l10n.no,
                            onTap: () async {
                              if (userProfile.isPro == true) {
                                await _openManageSubscriptions(context);
                                return;
                              }
                              final uid = authService.currentUser?.uid;
                              await PurchasesService.instance.syncAppUser(uid);
                              await PurchasesService.instance
                                  .refreshCustomerInfo();
                              if (!context.mounted) {
                                return;
                              }
                              await PurchasesService.instance.presentPaywall(
                                context: context,
                              );
                            },
                          ),
                          //TODO: route to verificationPage once Ausweisapp Client is in place
                          if (userProfile.isAdmin) ...[
                            const SizedBox(height: 20.0),
                            PointingListTile(
                              key: keys.profilePage.adminDashboardListTile,
                              leading: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.amber,
                              ),
                              title: Text(context.l10n.adminInterface),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdminDashboardPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20.0),
            // avatar display: use service notifier (updates after upload)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Update username
                  PointingListTile(
                    key: keys.profilePage.userHistoryPageListTile,
                    title: Text(context.l10n.activityHistory),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return const UserHistoryPage();
                          },
                        ),
                      );
                    },
                  ),

                  PointingListTile(
                    key: keys.profilePage.publicationsListTile,
                    title: Text(context.l10n.publications),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PublicationsPage(),
                        ),
                      );
                    },
                  ),
                  PointingListTile(
                    key: keys.profilePage.blockedUsersListTile,
                    title: Text(context.l10n.blockedUsers),
                    onTap: currentUser == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BlockedUsersPage(userId: currentUser.uid),
                              ),
                            );
                          },
                  ),
                  //Change password
                  PointingListTile(
                    key: keys.profilePage.changePasswordListTile,
                    title: Text(context.l10n.changePassword),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return ChangePasswordPage();
                          },
                        ),
                      );
                    },
                  ),
                  // Privacy Settings
                  PointingListTile(
                    title: Text(context.l10n.privacySettings),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPage(),
                        ),
                      );
                    },
                  ),

                  // Logout
                  PointingListTile(
                    key: keys.profilePage.logoutListTile,
                    title: Text(context.l10n.logout, style: AppTextStyles.red),
                    trailing: const SizedBox.shrink(),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: Text(dialogContext.l10n.logout),
                            content: Text(
                              dialogContext.l10n.areYouSureYouWantToLogout,
                              style: AppTextStyles.m,
                            ),
                            actions: [
                              FilledButton(
                                key: keys.profilePage.confirmLogoutButton,
                                onPressed: () {
                                  // Pop the dialog before calling logout.
                                  Navigator.pop(dialogContext);
                                  _logout(context);
                                },
                                child: Text(dialogContext.l10n.logout),
                              ),
                              TextButton(
                                key: keys.profilePage.cancelLogoutButton,
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                child: Text(dialogContext.l10n.cancel),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  // Delete my account
                  PointingListTile(
                    key: keys.profilePage.deleteAccountListTile,
                    title: Text(
                      context.l10n.deleteMyAccount,
                      style: AppTextStyles.red,
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: Text(dialogContext.l10n.deleteAccount),
                            content: Text(
                              dialogContext
                                  .l10n
                                  .areYouSureYouWantToDeleteYourAccount,
                              style: AppTextStyles.m,
                            ),
                            actions: [
                              FilledButton(
                                key: keys.profilePage.confirmDeleteButton,
                                onPressed: () {
                                  // Pop the dialog before calling logout.
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const DeleteAccountPage(),
                                    ),
                                  );
                                },
                                child: Text(dialogContext.l10n.confirm),
                              ),
                              TextButton(
                                key: keys.profilePage.cancelDeleteButton,
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                child: Text(dialogContext.l10n.cancel),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}

Widget _buildDetailTile(
  BuildContext context,
  String label,
  String? value, {
  Key? key,
  VoidCallback? onTap,
}) {
  if (value == null || value.isEmpty) return const SizedBox.shrink();
  return ListTile(
    key: key,
    title: Text(label, style: AppTextStyles.descriptionText),
    subtitle: Text(value, style: AppTextStyles.mBold),
    dense: true,
    onTap: onTap,
    trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
  );
}
