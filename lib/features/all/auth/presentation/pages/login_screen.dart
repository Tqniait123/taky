import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/extensions/num_extension.dart';
import 'package:taqy/core/extensions/text_style_extension.dart';
import 'package:taqy/core/extensions/theme_extension.dart';
import 'package:taqy/core/static/icons.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/translations/locale_keys.g.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/core/utils/widgets/adaptive_layout/custom_layout.dart';
import 'package:taqy/core/utils/widgets/buttons/custom_elevated_button.dart';
import 'package:taqy/core/utils/widgets/inputs/custom_form_field.dart';
import 'package:taqy/core/utils/widgets/logo_widget.dart';
import 'package:taqy/features/all/auth/data/models/login_params.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/all/auth/presentation/cubit/user_cubit/user_cubit.dart';
import 'package:taqy/features/all/auth/presentation/widgets/sign_up_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isRemembered = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==================== BIOMETRIC INITIALIZATION ====================

  // ==================== REGULAR LOGIN ====================

  void _performRegularLogin() {
    if (_formKey.currentState!.validate()) {
      AuthCubit.get(context).login(
        LoginParams(phone: _phoneController.text, password: _passwordController.text, isRemembered: isRemembered),
      );
    }
  }

  // ==================== DIALOGS & BOTTOM SHEETS ====================

  // Updated _showBiometricEnrollmentDialog method for your LoginScreen

  Future<void> _showBiometricEnrollmentDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(Icons.fingerprint, size: 40, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              LocaleKeys.biometric_authentication.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              LocaleKeys.biometric_enrollment_description.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Buttons
            Column(
              children: [
                // Use Device Password Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.lock_outline, size: 20),
                    label: Text(LocaleKeys.use_device_password.tr()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Action buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(LocaleKeys.later.tr()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                        child: Text(LocaleKeys.open_settings.tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UI HELPERS ====================

  void _showError(String message) {
    if (mounted && message.isNotEmpty) {
      showErrorToast(context, message);
      log('Biometric error: $message');
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      showSuccessToast(context, message); // You might want to create a success toast method
      log('Biometric success: $message');
    }
  }

  // ==================== BUILD METHOD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomLayout(
        withPadding: true,
        patternOffset: const Offset(-150, -200),
        spacerHeight: 35,
        topPadding: 70,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        upperContent: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: LogoWidget(type: LogoType.svg)),
              27.gap,
              Text(
                LocaleKeys.login_to_your_account.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        children: [
          30.gap,
          _buildLoginForm(),
          40.gap,
          _buildActionButtons(),
          71.gap,
          _buildDivider(),
          20.gap,
          const SocialMediaButtons(),
          20.gap,
          SignUpButton(isLogin: true, onTap: () => context.push(Routes.register)),
          30.gap,
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Hero(
        tag: "form",
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              CustomTextFormField(
                controller: _phoneController,
                margin: 0,
                hint: LocaleKeys.phone_number.tr(),
                title: LocaleKeys.phone_number.tr(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocaleKeys.please_enter_phone_number.tr();
                  }
                  return null;
                },
              ),
              16.gap,
              CustomTextFormField(
                margin: 0,
                controller: _passwordController,
                hint: LocaleKeys.password.tr(),
                title: LocaleKeys.password.tr(),
                obscureText: true,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocaleKeys.please_enter_password.tr();
                  }
                  return null;
                },
              ),
              19.gap,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          activeColor: AppColors.secondary,
                          checkColor: AppColors.white,
                          value: isRemembered,
                          onChanged: (value) {
                            setState(() {
                              isRemembered = value ?? false;
                            });
                          },
                        ),
                      ),
                      8.gap,
                      Text(LocaleKeys.remember_me.tr(), style: context.bodyMedium.s12.regular),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push(Routes.forgetPassword),
                    child: Text(
                      LocaleKeys.forgot_password.tr(),
                      style: context.bodyMedium.s12.bold.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) async {
              if (state is AuthSuccess) {
                // Handle post-login biometric setup
                UserCubit.get(context).setCurrentUser(state.user);
                context.go(Routes.homeUser);
              } else if (state is AuthError) {
                showErrorToast(context, state.message);
              }
            },
            builder: (context, state) => CustomElevatedButton(
              heroTag: 'button',
              loading: state is AuthLoading,
              title: LocaleKeys.login.tr(),
              onPressed: _performRegularLogin,
            ),
          ),
        ),
        20.gap,
        Expanded(
          child: CustomElevatedButton(
            heroTag: 'faceId',
            icon: AppIcons.faceIdIc,
            title: 'TEST',
            loading: false,
            onPressed: () {},
            backgroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.grey60.withOpacity(0.3), thickness: 1)),
        16.gap,
        Text(LocaleKeys.or_login_with.tr(), style: context.bodyMedium.s12.regular),
        16.gap,
        Expanded(child: Divider(color: AppColors.grey60.withOpacity(0.3), thickness: 1)),
      ],
    );
  }
}

// ==================== BOTTOM SHEET WIDGETS ====================

class _QuickLoginBottomSheet extends StatelessWidget {
  final String biometricType;
  final VoidCallback onUseBiometric;
  final VoidCallback onUsePassword;

  const _QuickLoginBottomSheet({
    required this.biometricType,
    required this.onUseBiometric,
    required this.onUsePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey60.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              24.gap,
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(
                  biometricType == 'Face ID' ? Icons.face : Icons.fingerprint,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              24.gap,
              // Title
              Text(LocaleKeys.quick_login.tr(), style: context.headlineSmall.bold.copyWith(color: AppColors.black)),
              12.gap,
              // Description
              Text(
                LocaleKeys.quick_login_description.tr().replaceAll('{biometricType}', biometricType),
                style: context.bodyMedium.regular.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              32.gap,
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomElevatedButton(
                      heroTag: 'use_password',
                      title: LocaleKeys.use_password.tr(),
                      isBordered: true,
                      backgroundColor: Colors.transparent,
                      textColor: AppColors.primary,
                      onPressed: onUsePassword,
                    ),
                  ),
                  16.gap,
                  Expanded(
                    child: CustomElevatedButton(
                      heroTag: 'use_biometric',
                      title: LocaleKeys.use_biometric.tr().replaceAll('{biometricType}', biometricType),
                      icon: AppIcons.faceIdIc,
                      backgroundColor: AppColors.primary,
                      textColor: Colors.white,
                      onPressed: onUseBiometric,
                    ),
                  ),
                ],
              ),
              16.gap,
            ],
          ),
        ),
      ),
    );
  }
}

class _BiometricSetupBottomSheet extends StatelessWidget {
  final String biometricType;
  final VoidCallback onEnable;
  final VoidCallback onSkip;

  const _BiometricSetupBottomSheet({required this.biometricType, required this.onEnable, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey60.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              24.gap,
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.security, size: 40, color: AppColors.secondary),
              ),
              24.gap,
              // Title
              Text(
                LocaleKeys.enable_biometric_authentication.tr().replaceAll('{biometricType}', biometricType),
                style: context.headlineSmall.bold.copyWith(color: AppColors.black),
                textAlign: TextAlign.center,
              ),
              12.gap,
              // Description
              Text(
                LocaleKeys.enable_biometric_description.tr().replaceAll('{biometricType}', biometricType),
                style: context.bodyMedium.regular.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              24.gap,
              // Features list
              _FeatureItem(
                icon: Icons.speed,
                title: LocaleKeys.quick_access.tr(),
                description: LocaleKeys.quick_access_description.tr().replaceAll(
                  '{action}',
                  biometricType == 'Face ID' ? LocaleKeys.face_action.tr() : LocaleKeys.touch_action.tr(),
                ),
              ),
              12.gap,
              _FeatureItem(
                icon: Icons.shield,
                title: LocaleKeys.enhanced_security.tr(),
                description: LocaleKeys.enhanced_security_description.tr(),
              ),
              12.gap,
              _FeatureItem(
                icon: Icons.lock,
                title: LocaleKeys.privacy_protected.tr(),
                description: LocaleKeys.privacy_protected_description.tr(),
              ),
              32.gap,
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomElevatedButton(
                      heroTag: 'skip_biometric',
                      title: LocaleKeys.skip_for_now.tr(),
                      isBordered: true,
                      backgroundColor: Colors.transparent,
                      textColor: AppColors.grey,
                      onPressed: onSkip,
                    ),
                  ),
                  16.gap,
                  Expanded(
                    child: CustomElevatedButton(
                      heroTag: 'enable_biometric',
                      title: LocaleKeys.enable.tr(),
                      icon: AppIcons.faceIdIc,
                      backgroundColor: AppColors.secondary,
                      textColor: Colors.white,
                      onPressed: onEnable,
                    ),
                  ),
                ],
              ),
              16.gap,
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        16.gap,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.bodyMedium.bold.copyWith(color: AppColors.black)),
              2.gap,
              Text(description, style: context.bodySmall.regular.copyWith(color: AppColors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}

class SocialMediaButtons extends StatelessWidget {
  const SocialMediaButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: CustomElevatedButton(
            heroTag: 'google',
            height: 48,
            icon: AppIcons.google,
            iconColor: null,
            textColor: AppColors.black,
            isBordered: true,
            backgroundColor: AppColors.white,
            title: LocaleKeys.google.tr(),
            onPressed: () {},
          ),
        ),
        20.gap,
        Expanded(
          child: CustomElevatedButton(
            heroTag: 'facebook',
            height: 48,
            isBordered: true,
            icon: AppIcons.facebook,
            iconColor: null,
            textColor: AppColors.black,
            backgroundColor: AppColors.white,
            title: LocaleKeys.facebook.tr(),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
