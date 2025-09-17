// lib/features/all/auth/presentation/pages/forget_password_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/services/di.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/translations/locale_keys.g.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/all/auth/presentation/widgets/animated_button.dart';
import 'package:taqy/features/all/auth/presentation/widgets/auth_text_field.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.onSurface,
                size: 20,
              ),
            ),
          ),
          title: Text(
            LocaleKeys.forgotPassword.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (_isDisposed || !mounted) return;

              state.maybeWhen(
                passwordResetSent: () {
                  showSuccessToast(
                    context,
                    LocaleKeys.passwordResetEmailSent.tr(),
                  );
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(
                  //     content: Text(LocaleKeys.passwordResetEmailSent.tr()),
                  //     backgroundColor: AppColors.success,
                  //     behavior: SnackBarBehavior.floating,
                  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  //   ),
                  // );
                  // Navigate back to login after showing success message
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted && !_isDisposed) {
                      context.go(
                        Routes.checkYourEmail,
                        extra: {
                          'email': _emailController.text,
                          'isPasswordReset': true,
                        },
                      );
                    }
                  });
                },
                error: (failure) {
                  if (mounted && !_isDisposed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(failure),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                orElse: () {},
              );
            },
            builder: (context, state) {
              final isLoading = state.maybeWhen(
                loading: () => true,
                orElse: () => false,
              );

              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),

                            // Header Icon
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.1),
                                      AppColors.secondary.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lock_reset_outlined,
                                  size: 52,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Title
                            Center(
                              child: Text(
                                LocaleKeys.resetPassword.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Subtitle
                            Center(
                              child: Text(
                                LocaleKeys.passwordResetInstructions.tr(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      height: 1.5,
                                    ),
                              ),
                            ),

                            const SizedBox(height: 48),

                            // Form Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Email Field
                                    AuthTextField(
                                      controller: _emailController,
                                      label: LocaleKeys.email.tr(),
                                      hint: LocaleKeys.enterEmail.tr(),
                                      prefixIcon: Assets.imagesSvgsMail,
                                      keyboardType: TextInputType.emailAddress,
                                      focusColor: AppColors.secondary,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return LocaleKeys.pleaseEnterEmail
                                              .tr();
                                        }
                                        if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                        ).hasMatch(value)) {
                                          return LocaleKeys
                                              .pleaseEnterValidEmail
                                              .tr();
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 32),

                                    // Send Reset Email Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: AnimatedButton(
                                        text: LocaleKeys.sendResetEmail.tr(),
                                        onPressed: isLoading
                                            ? null
                                            : () => _handleForgotPassword(
                                                context,
                                              ),
                                        isLoading: isLoading,
                                        backgroundColor: AppColors.primary,
                                        width: double.infinity,
                                        height: 56,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Back to Login Link
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        LocaleKeys.rememberPassword.tr(),
                                        style: TextStyle(
                                          color: AppColors.onSurfaceVariant,
                                          fontSize: 16,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          if (mounted && !_isDisposed) {
                                            context.go(Routes.login);
                                          }
                                        },
                                        child: Text(
                                          LocaleKeys.backToLogin.tr(),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
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
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleForgotPassword(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    try {
      context.read<AuthCubit>().forgotPassword(_emailController.text.trim());
    } catch (e) {
      debugPrint('Forgot password error: $e');
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.passwordResetEmailFailed.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
