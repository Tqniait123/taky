// lib/features/all/auth/presentation/pages/check_your_email_screen.dart
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/services/di.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/translations/locale_keys.g.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/all/auth/presentation/widgets/animated_button.dart';
import 'package:taqy/features/all/auth/presentation/widgets/language_drop_down.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckYourEmailScreen extends StatefulWidget {
  final String email;
  final bool isPasswordReset;

  const CheckYourEmailScreen({
    super.key,
    required this.email,
    this.isPasswordReset = false,
  });

  @override
  State<CheckYourEmailScreen> createState() => _CheckYourEmailScreenState();
}

class _CheckYourEmailScreenState extends State<CheckYourEmailScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _successController;

  // Animations
  late Animation<double> _backgroundGradient;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _successAnimation;

  bool _isDisposed = false;
  bool _hasAnimatedSuccess = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Background animation controller
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _backgroundGradient = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Slide animation for content
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotation animation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Success checkmark animation
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() {
    // Start continuous animations
    _backgroundController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();

    // Start entrance animations
    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();

    // Start success animation after a delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!_isDisposed) {
        _successController.forward();
        _hasAnimatedSuccess = true;
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _backgroundController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return BlocProvider(
      create: (context) => sl<AuthCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Animated Background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) => CustomPaint(
                  painter: _CheckEmailBackgroundPainter(
                    _backgroundGradient.value,
                    _rotationAnimation.value,
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (_isDisposed || !mounted) return;

                  state.maybeWhen(
                    passwordResetSent: () {
                      if (!_hasAnimatedSuccess) {
                        _successController.forward();
                        _hasAnimatedSuccess = true;
                      }
                      showSuccessToast(
                        context,
                        LocaleKeys.passwordResetEmailSent.tr(),
                      );
                    },
                    error: (failure) {
                      if (mounted && !_isDisposed) {
                        showErrorToast(context, failure);
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
                    animation: Listenable.merge([
                      _fadeController,
                      _slideController,
                      _scaleController,
                      _pulseController,
                      _rotationController,
                      _successController,
                    ]),
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: AlwaysStoppedAnimation(
                          _fadeAnimation.value.clamp(0.0, 1.0),
                        ),
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: ScaleTransition(
                            scale: AlwaysStoppedAnimation(
                              _scaleAnimation.value.clamp(0.1, 1.0),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 16,
                              ),
                              child: Column(
                                children: [
                                  // Header with Back Button and Language
                                  _buildHeaderSection(locale, context),

                                  const SizedBox(height: 40),

                                  // Animated Content
                                  _buildAnimatedContent(context, isLoading),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(String locale, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button with glass effect
        AnimatedBuilder(
          animation: _scaleController,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              // padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassStroke, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: IconButton(
                  onPressed: () => context.go(Routes.login),
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Language Dropdown
        _buildGlassLanguageDropdown(),
      ],
    );
  }

  Widget _buildGlassLanguageDropdown() {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassStroke, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const CompactLanguageDropdown(),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedContent(BuildContext context, bool isLoading) {
    return Column(
      children: [
        // Animated Email Icon
        _buildAnimatedEmailIcon(),

        const SizedBox(height: 32),

        // Title
        TweenAnimationBuilder<double>(
          tween: Tween(begin: -30.0, end: 0.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.translate(
            offset: Offset(0, value),
            child: Text(
              LocaleKeys.checkYourEmail.tr(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Subtitle
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 30.0, end: 0.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.translate(
            offset: Offset(0, value),
            child: Text(
              widget.isPasswordReset
                  ? LocaleKeys.passwordResetEmailSentDescription.tr()
                  : LocaleKeys.verificationEmailSentDescription.tr(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Email Display with Glass Effect
        AnimatedBuilder(
          animation: _scaleController,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassStroke, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      Assets.imagesSvgsMail,
                      color: Colors.white.withOpacity(0.8),
                      height: 20,
                      width: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.email,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 48),

        // Action Buttons with Glass Effect
        _buildGlassActionButtons(context, isLoading),

        const SizedBox(height: 32),

        // // Resend Email Section (for verification)
        if (!widget.isPasswordReset) ...[
          _buildGlassResendSection(context, isLoading),
          const SizedBox(height: 24),
        ],

        // Help Text
        _buildGlassHelpText(context),
      ],
    );
  }

  Widget _buildAnimatedEmailIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Circle with Pulse
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) => Transform.scale(
            scale: _pulseAnimation.value,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) => Transform.rotate(
                angle: _rotationAnimation.value * 0.1,
                child: Container(
                  width: 160,
                  height: 160,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.secondary.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),

        // Email Icon with Success Animation
        AnimatedBuilder(
          animation: _successController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Email Icon
                Opacity(
                  opacity: 1.0 - _successAnimation.value,
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: 48,
                    color: Colors.white,
                  ),
                ),

                // Success Checkmark
                Opacity(
                  opacity: _successAnimation.value,
                  child: Transform.scale(
                    scale: _successAnimation.value,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(Icons.check, size: 32, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildGlassActionButtons(BuildContext context, bool isLoading) {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassStroke, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
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
                  ),
                ),

                const SizedBox(height: 16),

                // Skip or Back to Login Button
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
                    backgroundColor: AppColors.secondary,
                    // borderColor: Colors.white.withOpacity(0.3),
                    // textColor: Colors.white,
                    width: double.infinity,
                    height: 56,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassResendSection(BuildContext context, bool isLoading) {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassStroke, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Text(
                  LocaleKeys.didntReceiveEmail.tr(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
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
    );
  }

  Widget _buildGlassHelpText(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassStroke, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: LocaleKeys.didntReceiveEmailCheck.tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: ' ${LocaleKeys.tryAnotherEmailAddress.tr()}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
        ),
      ),
    );
  }

  void _openEmailApp() async {
    try {
      final emailApps = [
        'mailto:',
        'googlegmail://',
        'ms-outlook://',
        'ymail://',
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
        showErrorToast(context, LocaleKeys.noEmailAppFound.tr());
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        showErrorToast(context, LocaleKeys.errorOpeningEmailApp.tr());
      }
    }
  }

  void _resendEmail(BuildContext context) {
    try {
      showSuccessToast(context, LocaleKeys.verificationEmailResent.tr());
    } catch (e) {
      if (mounted && !_isDisposed) {
        showErrorToast(context, LocaleKeys.errorResendingEmail.tr());
      }
    }
  }
}

class _CheckEmailBackgroundPainter extends CustomPainter {
  final double animationValue;
  final double rotationValue;

  _CheckEmailBackgroundPainter(this.animationValue, this.rotationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      colors: [AppColors.primary, AppColors.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Animated particles
    final particlePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 22; i++) {
      final x =
          (size.width * 0.1) +
          (i * size.width * 0.04) +
          (math.sin(animationValue * 2 * math.pi + i) * 32);
      final y =
          (size.height * 0.2) +
          (math.cos(animationValue * 2 * math.pi + i * 0.7) * 42);
      final radius = 2 + math.sin(animationValue * 2 * math.pi + i) * 2.2;

      canvas.drawCircle(Offset(x, y), radius.abs(), particlePaint);
    }

    // Flowing gradient lines
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1.6;

    for (int i = 0; i < 4; i++) {
      final path = Path();
      final startY = size.height * (0.1 + i * 0.2);

      path.moveTo(-50, startY);

      for (double x = -50; x <= size.width + 50; x += 8) {
        final y =
            startY +
            math.sin((x * 0.008) + (animationValue * 2 * math.pi) + (i * 2)) *
                26;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, linePaint);
    }

    // Email-themed background elements
    final emailPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw some envelope-like shapes
    for (int i = 0; i < 2; i++) {
      final centerX = size.width * (0.3 + i * 0.4);
      final centerY = size.height * 0.8;
      final envelopeSize = 60 + math.sin(animationValue * 2 * math.pi + i) * 15;

      // Envelope shape
      final path = Path()
        ..moveTo(centerX - envelopeSize * 0.5, centerY - envelopeSize * 0.3)
        ..lineTo(centerX, centerY - envelopeSize * 0.1)
        ..lineTo(centerX + envelopeSize * 0.5, centerY - envelopeSize * 0.3)
        ..lineTo(centerX + envelopeSize * 0.5, centerY + envelopeSize * 0.3)
        ..lineTo(centerX - envelopeSize * 0.5, centerY + envelopeSize * 0.3)
        ..close();

      canvas.drawPath(path, emailPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
