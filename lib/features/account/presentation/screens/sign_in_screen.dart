import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/account_providers.dart';

/// Email + password sign-in for returning customers.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _showErrorsAsSnacks();
    final bool isSubmitting =
        ref.watch(accountControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.signIn)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const _WelcomeHeader(),
                    const SizedBox(height: AppDimensions.spaceXl),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const <String>[AutofillHints.email],
                      validator: Validators.email,
                      decoration: const InputDecoration(
                        labelText: AppStrings.emailLabel,
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      autofillHints: const <String>[AutofillHints.password],
                      validator: Validators.password,
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(
                        labelText: AppStrings.passwordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: 'Show password',
                          onPressed: _togglePasswordVisibility,
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: const Text(AppStrings.forgotPassword),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    AppButton(
                      label: AppStrings.signIn,
                      icon: Icons.login,
                      isLoading: isSubmitting,
                      onPressed: _signIn,
                    ),
                    const SizedBox(height: AppDimensions.spaceLg),
                    _SignUpPrompt(onTap: () => context.push(AppRoutes.signUp)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _togglePasswordVisibility() =>
      setState(() => _obscurePassword = !_obscurePassword);

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final bool succeeded =
        await ref.read(accountControllerProvider.notifier).signIn(
              email: _email.text,
              password: _password.text,
            );
    if (succeeded && mounted) _leaveSignIn();
  }

  Future<void> _resetPassword() async {
    if (Validators.email(_email.text) != null) {
      context.showSnack('Enter yuh email first, then tap reset.', isError: true);
      return;
    }
    final String message = await ref
        .read(accountControllerProvider.notifier)
        .sendPasswordReset(_email.text);
    if (mounted) context.showSnack(message);
  }

  /// Returns where the customer came from, or the menu on a cold deep link.
  void _leaveSignIn() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.menu);
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

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text('🥥', style: TextStyle(fontSize: 56)),
        const SizedBox(height: AppDimensions.spaceSm),
        Text(
          AppStrings.welcomeBack,
          style: context.textStyles.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        Text(
          AppStrings.signInSubtitle,
          textAlign: TextAlign.center,
          style: context.textStyles.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SignUpPrompt extends StatelessWidget {
  const _SignUpPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          AppStrings.noAccountPrompt,
          style: context.textStyles.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        TextButton(onPressed: onTap, child: const Text(AppStrings.createAccount)),
      ],
    );
  }
}
