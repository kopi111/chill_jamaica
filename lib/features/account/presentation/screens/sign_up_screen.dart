import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/profile_photo.dart';
import '../../domain/entities/sign_up_request.dart';
import '../providers/account_providers.dart';
import '../widgets/profile_photo_picker.dart';

/// Registration form: photo, name, email, phone, password and saved addresses.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _SignUpFields _fields = _SignUpFields();
  ProfilePhoto? _photo;

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _showErrorsAsSnacks();
    final bool isSubmitting = ref.watch(accountControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.createAccount)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: _SignUpForm(
            fields: _fields,
            photo: _photo,
            onPhotoPicked: (ProfilePhoto picked) =>
                setState(() => _photo = picked),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppDimensions.spaceMd),
        child: AppButton(
          label: AppStrings.createAccount,
          icon: Icons.person_add_alt,
          isLoading: isSubmitting,
          onPressed: _submit,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final bool succeeded = await ref
        .read(accountControllerProvider.notifier)
        .signUp(_buildRequest());
    if (!succeeded || !mounted) return;

    context.showSnack(AppStrings.accountCreated);
    context.go(AppRoutes.menu);
  }

  SignUpRequest _buildRequest() => SignUpRequest(
        fullName: _fields.fullName.text,
        email: _fields.email.text,
        password: _fields.password.text,
        phone: Formatters.toE164Jamaican(_fields.phone.text),
        photo: _photo,
        homeAddress: _fields.homeAddress.trimmedOrNull,
        workAddress: _fields.workAddress.trimmedOrNull,
      );

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

/// The sign-up form's text controllers, grouped so the screen owns one object
/// instead of seven.
class _SignUpFields {
  final TextEditingController fullName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phone =
      TextEditingController(text: '+1 (876) ');
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  final TextEditingController homeAddress = TextEditingController();
  final TextEditingController workAddress = TextEditingController();

  void dispose() {
    fullName.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    confirmPassword.dispose();
    homeAddress.dispose();
    workAddress.dispose();
  }
}

extension on TextEditingController {
  /// The typed value, or null when the customer left the field blank.
  String? get trimmedOrNull {
    final String value = text.trim();
    return value.isEmpty ? null : value;
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({
    required this.fields,
    required this.photo,
    required this.onPhotoPicked,
  });

  final _SignUpFields fields;
  final ProfilePhoto? photo;
  final ValueChanged<ProfilePhoto> onPhotoPicked;

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  bool _obscurePasswords = true;

  @override
  Widget build(BuildContext context) {
    final _SignUpFields fields = widget.fields;
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      children: <Widget>[
        Center(
          child: ProfilePhotoPicker(
            initials: '🥥',
            pendingPhoto: widget.photo,
            onPhotoPicked: widget.onPhotoPicked,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        Center(
          child: Text(
            AppStrings.addPhotoPrompt,
            style: context.textStyles.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        TextFormField(
          controller: fields.fullName,
          textCapitalization: TextCapitalization.words,
          autofillHints: const <String>[AutofillHints.name],
          validator: Validators.fullName,
          decoration: const InputDecoration(
            labelText: AppStrings.fullNameLabel,
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        TextFormField(
          controller: fields.email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const <String>[AutofillHints.email],
          validator: Validators.email,
          decoration: const InputDecoration(
            labelText: AppStrings.emailLabel,
            helperText: 'Yuh use dis to sign in.',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        TextFormField(
          controller: fields.phone,
          keyboardType: TextInputType.phone,
          validator: Validators.jamaicanPhone,
          decoration: const InputDecoration(
            labelText: AppStrings.phoneLabel,
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        TextFormField(
          controller: fields.password,
          obscureText: _obscurePasswords,
          autofillHints: const <String>[AutofillHints.newPassword],
          validator: Validators.password,
          decoration: InputDecoration(
            labelText: AppStrings.passwordLabel,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: 'Show password',
              onPressed: _togglePasswordVisibility,
              icon: Icon(
                _obscurePasswords
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        TextFormField(
          controller: fields.confirmPassword,
          obscureText: _obscurePasswords,
          validator: (String? value) =>
              Validators.passwordMatching(value, fields.password.text),
          decoration: const InputDecoration(
            labelText: AppStrings.confirmPasswordLabel,
            prefixIcon: Icon(Icons.lock_reset_outlined),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        Text(
          'Where wi delivering?',
          style: context.textStyles.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        TextFormField(
          controller: fields.homeAddress,
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
          controller: fields.workAddress,
          textCapitalization: TextCapitalization.words,
          validator: Validators.optionalAddress,
          decoration: const InputDecoration(
            labelText: AppStrings.workAddressLabel,
            hintText: AppStrings.addressHint,
            prefixIcon: Icon(Icons.work_outline),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXl),
      ],
    );
  }

  void _togglePasswordVisibility() =>
      setState(() => _obscurePasswords = !_obscurePasswords);
}
