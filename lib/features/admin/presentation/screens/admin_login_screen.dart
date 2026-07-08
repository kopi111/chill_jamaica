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
import '../providers/admin_providers.dart';

/// Email/password login for admins, with password reset and remember-me.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _rememberMe = true;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final bool ok = await ref.read(adminLoginControllerProvider.notifier).signIn(
          email: _email.text,
          password: _password.text,
        );
    if (ok && mounted) context.go(AppRoutes.adminDashboard);
  }

  Future<void> _resetPassword() async {
    if (Validators.email(_email.text) != null) {
      context.showSnack('Enter your email first, then tap reset.', isError: true);
      return;
    }
    final String message =
        await ref.read(adminLoginControllerProvider.notifier).sendReset(_email.text);
    if (mounted) context.showSnack(message);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> loginState = ref.watch(adminLoginControllerProvider);
    ref.listen<AsyncValue<void>>(adminLoginControllerProvider,
        (AsyncValue<void>? prev, AsyncValue<void> next) {
      next.whenOrNull(
        error: (Object error, _) => context.showSnack(
          error is Failure ? error.message : AppStrings.genericError,
          isError: true,
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: context.pop,
              )
            : null,
      ),
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
                    const _AdminLogo(),
                    const SizedBox(height: AppDimensions.spaceXl),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.text,
                      autofillHints: const <String>[AutofillHints.username],
                      validator: Validators.username,
                      decoration: const InputDecoration(
                        labelText: AppStrings.usernameLabel,
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      validator: Validators.password,
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(
                        labelText: AppStrings.passwordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceSm),
                    Row(
                      children: <Widget>[
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (bool? v) =>
                              setState(() => _rememberMe = v ?? true),
                        ),
                        const Text(AppStrings.rememberMe),
                        const Spacer(),
                        TextButton(
                          onPressed: _resetPassword,
                          child: const Text(AppStrings.forgotPassword),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    AppButton(
                      label: AppStrings.signIn,
                      isLoading: loginState.isLoading,
                      onPressed: _signIn,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminLogo extends StatelessWidget {
  const _AdminLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          height: 88,
          width: 88,
          decoration: const BoxDecoration(
            gradient: AppColors.tropicalGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.admin_panel_settings_outlined,
              color: AppColors.white, size: 44),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Text(
          AppStrings.adminAppName,
          textAlign: TextAlign.center,
          style: context.textStyles.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
