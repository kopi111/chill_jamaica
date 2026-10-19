import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../domain/entities/customer_profile.dart';
import '../providers/account_providers.dart';

/// Edits the signed-in customer's name, phone and saved addresses.
///
/// The email is fixed at sign-up because it is also the sign-in credential, and
/// the photo is changed by tapping the avatar on the profile screen.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CustomerProfile? profile =
        ref.watch(signedInCustomerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.editProfile)),
      body: profile == null
          ? EmptyView(
              message: AppStrings.signInToCheckoutBody,
              actionLabel: 'Back',
              onAction: context.pop,
            )
          : _EditProfileForm(profile: profile),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile});

  final CustomerProfile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _homeAddress;
  late final TextEditingController _workAddress;

  @override
  void initState() {
    super.initState();
    final CustomerProfile profile = widget.profile;
    _fullName = TextEditingController(text: profile.fullName);
    _phone = TextEditingController(text: Formatters.prettyPhone(profile.phone));
    _homeAddress = TextEditingController(text: profile.homeAddress ?? '');
    _workAddress = TextEditingController(text: profile.workAddress ?? '');
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _homeAddress.dispose();
    _workAddress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _showErrorsAsSnacks();
    final bool isSaving = ref.watch(accountControllerProvider).isLoading;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        children: <Widget>[
          TextFormField(
            controller: _fullName,
            textCapitalization: TextCapitalization.words,
            validator: Validators.fullName,
            decoration: const InputDecoration(
              labelText: AppStrings.fullNameLabel,
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            validator: Validators.jamaicanPhone,
            decoration: const InputDecoration(
              labelText: AppStrings.phoneLabel,
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          TextFormField(
            controller: _homeAddress,
            textCapitalization: TextCapitalization.words,
            validator: Validators.optionalAddress,
            decoration: const InputDecoration(
              labelText: AppStrings.homeAddressLabel,
              hintText: AppStrings.addressHint,
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          TextFormField(
            controller: _workAddress,
            textCapitalization: TextCapitalization.words,
            validator: Validators.optionalAddress,
            decoration: const InputDecoration(
              labelText: AppStrings.workAddressLabel,
              hintText: AppStrings.addressHint,
              prefixIcon: Icon(Icons.work_outline),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXl),
          AppButton(
            label: AppStrings.saveChanges,
            icon: Icons.save_outlined,
            isLoading: isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final bool succeeded = await ref
        .read(accountControllerProvider.notifier)
        .saveProfile(_editedProfile());
    if (!succeeded || !mounted) return;

    context.showSnack(AppStrings.profileSaved);
    context.pop();
  }

  CustomerProfile _editedProfile() => CustomerProfile(
        uid: widget.profile.uid,
        fullName: _fullName.text.trim(),
        email: widget.profile.email,
        phone: Formatters.toE164Jamaican(_phone.text),
        photoUrl: widget.profile.photoUrl,
        homeAddress: _blankToNull(_homeAddress.text),
        workAddress: _blankToNull(_workAddress.text),
      );

  String? _blankToNull(String raw) {
    final String value = raw.trim();
    return value.isEmpty ? null : value;
  }

  void _showErrorsAsSnacks() {
    ref.listen<AsyncValue<void>>(accountControllerProvider,
        (AsyncValue<void>? previous, AsyncValue<void> next) {
      next.whenOrNull(
        error: (Object error, _) => context.showSnack(
          error is Failure ? error.message : AppStrings.genericError,
          isError: true,
        ),
      );
    });
  }
}
