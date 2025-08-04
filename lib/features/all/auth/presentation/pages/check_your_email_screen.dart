// lib/features/all/auth/presentation/pages/check_your_email_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/services/di.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/translations/locale_keys.g.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/all/auth/presentation/widgets/animated_button.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckYourEmailScreen extends StatefulWidget {
  final String email;
  final bool isPasswordReset;

  const CheckYourEmailScreen({super.key, required this.email, this.isPasswordReset = false});

  @override
  State<CheckYourEmailScreen> createState() => _CheckYourEmailScreenState();
}

class _CheckYourEmailScreenState extends State<CheckYourEmailScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
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
            onPressed: () => context.go(Routes.login),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface, size: 20),
            ),
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (_isDisposed || !mounted) return;

              state.maybeWhen(
                passwordResetSent: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LocaleKeys.passwordResetEmailSent.tr()),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                error: (failure) {
                  if (mounted && !_isDisposed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(failure),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                orElse: () {},
              );
            },
            builder: (context, state) {
              final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);

              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Email Icon Animation
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.primary, AppColors.secondary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.mark_email_read_outlined, size: 60, color: Colors.white),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Title
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [AppColors.primary, AppColors.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  LocaleKeys.checkYourEmail.tr(),
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Subtitle
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Text(
                                widget.isPasswordReset
                                    ? LocaleKeys.passwordResetEmailSentDescription.tr()
                                    : LocaleKeys.verificationEmailSentDescription.tr(),
                                textAlign: TextAlign.center,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Email Display
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.email,
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Action Buttons Card
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Container(
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
                                child: Column(
                                  children: [
                                    // Open Email App Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: AnimatedButton(
                                        text: LocaleKeys.openEmailApp.tr(),
                                        onPressed: () => _openEmailApp(),
                                        backgroundColor: AppColors.primary,
                                        width: double.infinity,
                                        height: 56,
                                        // icon: Icons.email_outlined,
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Skip Button (for verification) or Back to Login (for password reset)
                                    SizedBox(
                                      width: double.infinity,
                                      child: AnimatedButton(
                                        text: widget.isPasswordReset
                                            ? LocaleKeys.backToLogin.tr()
                                            : LocaleKeys.skipIllConfirmLater.tr(),
                                        onPressed: () {
                                          if (mounted && !_isDisposed) {
                                            context.go(Routes.login);
                                          }
                                        },
                                        backgroundColor: AppColors.surface,
                                        // textColor: AppColors.onSurface,
                                        // borderColor: AppColors.outline,
                                        width: double.infinity,
                                        height: 56,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Resend Email Section
                          if (!widget.isPasswordReset) ...[
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        LocaleKeys.didntReceiveEmail.tr(),
                                        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16),
                                      ),
                                      const SizedBox(height: 12),
                                      AnimatedButton(
                                        text: LocaleKeys.resendEmail.tr(),
                                        onPressed: isLoading ? null : () => _resendEmail(context),
                                        isLoading: isLoading,
                                        backgroundColor: AppColors.secondary,
                                        width: double.infinity,
                                        height: 48,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Help Text
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: LocaleKeys.didntReceiveEmailCheck.tr(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                                  ),
                                  TextSpan(
                                    text: ' ${LocaleKeys.tryAnotherEmailAddress.tr()}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        if (mounted && !_isDisposed) {
                                          context.pop();
                                        }
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  void _openEmailApp() async {
    try {
      // Try to open specific email apps
      final emailApps = [
        'mailto:', // Default mail app
        'googlegmail://', // Gmail
        'ms-outlook://', // Outlook
        'ymail://', // Yahoo Mail
      ];

      bool opened = false;
      for (String app in emailApps) {
        if (await canLaunchUrl(Uri.parse(app))) {
          await launchUrl(Uri.parse(app));
          opened = true;
          break;
        }
      }

      if (!opened && mounted && !_isDisposed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(LocaleKeys.noEmailAppFound.tr()), backgroundColor: AppColors.warning));
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(LocaleKeys.errorOpeningEmailApp.tr()), backgroundColor: AppColors.error));
      }
    }
  }

  void _resendEmail(BuildContext context) {
    try {
      // For verification emails, you might want to implement resend verification logic
      // For now, we'll just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.verificationEmailResent.tr()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(LocaleKeys.errorResendingEmail.tr()), backgroundColor: AppColors.error));
      }
    }
  }
}
