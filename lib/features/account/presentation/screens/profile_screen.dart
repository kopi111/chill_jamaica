import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../domain/entities/customer_profile.dart';
import '../../domain/entities/profile_photo.dart';
import '../../domain/entities/saved_address.dart';
import '../providers/account_providers.dart';
import '../widgets/profile_photo_picker.dart';

/// The signed-in customer's profile: photo, details, saved addresses, sign-out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CustomerProfile?> customer =
        ref.watch(signedInCustomerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myProfile),
        actions: <Widget>[
          if (customer.valueOrNull != null)
            IconButton(
              tooltip: AppStrings.editProfile,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(AppRoutes.editProfile),
            ),
        ],
      ),
      body: customer.when(
        loading: () => const LoadingIndicator(),
        error: (Object error, _) => EmptyView(
          message: AppStrings.genericError,
          actionLabel: 'Try Again',
          onAction: () => ref.invalidate(signedInCustomerProvider),
        ),
        data: (CustomerProfile? profile) => profile == null
            ? _SignedOutView(onSignIn: () => context.push(AppRoutes.signIn))
            : _ProfileView(profile: profile),
      ),
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => EmptyView(
        message: AppStrings.signInToCheckoutBody,
        actionLabel: AppStrings.signIn,
        onAction: onSignIn,
      );
}

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.profile});

  final CustomerProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      children: <Widget>[
        Center(
          child: ProfilePhotoPicker(
            initials: profile.initials,
            existingPhotoUrl: profile.photoUrl,
            onPhotoPicked: (ProfilePhoto photo) =>
                _changePhoto(context, ref, photo),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Center(
          child: Text(
            profile.fullName,
            style: context.textStyles.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        _DetailTile(
          icon: Icons.mail_outline,
          label: AppStrings.emailLabel,
          value: profile.email,
        ),
        _DetailTile(
          icon: Icons.phone_outlined,
          label: AppStrings.phoneLabel,
          value: Formatters.prettyPhone(profile.phone),
        ),
        ..._addressTiles(),
        const SizedBox(height: AppDimensions.spaceLg),
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text(AppStrings.myOrdersTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.myOrders),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.urgentRed),
          title: const Text(
            AppStrings.logout,
            style: TextStyle(color: AppColors.urgentRed),
          ),
          onTap: () => _confirmSignOut(context, ref),
        ),
      ],
    );
  }

  List<Widget> _addressTiles() {
    final List<SavedAddress> addresses = profile.deliverableAddresses;
    if (addresses.isEmpty) {
      return const <Widget>[
        _DetailTile(
          icon: Icons.location_off_outlined,
          label: 'Saved addresses',
          value: 'None yet — add one so checkout goes faster.',
        ),
      ];
    }
    return addresses
        .map(
          (SavedAddress address) => _DetailTile(
            icon: address.label.icon,
            label: address.label.label,
            value: address.line,
          ),
        )
        .toList();
  }

  Future<void> _changePhoto(
    BuildContext context,
    WidgetRef ref,
    ProfilePhoto photo,
  ) async {
    final bool succeeded = await ref
        .read(accountControllerProvider.notifier)
        .changePhoto(profile: profile, photo: photo);
    if (!context.mounted) return;
    context.showSnack(
      succeeded ? AppStrings.profileSaved : AppStrings.genericError,
      isError: !succeeded,
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.signOutConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(accountControllerProvider.notifier).signOut();
    if (context.mounted) context.go(AppRoutes.menu);
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.primaryGreen),
        title: Text(
          label,
          style: context.textStyles.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        subtitle: Text(value, style: context.textStyles.bodyLarge),
      );
}
