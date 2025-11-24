import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/extensions/context_extensions.dart';
import 'package:taqy/core/services/di.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/translations/locale_keys.g.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/all/auth/domain/entities/user.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/all/auth/presentation/widgets/animated_button.dart';
import 'package:taqy/features/all/auth/presentation/widgets/language_drop_down.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Animation Controllers
  late AnimationController _backgroundController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  // Animations
  late Animation<double> _backgroundGradient;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  bool _isPasswordVisible = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Background animation controller
    _backgroundController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _backgroundGradient = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut));

    // Slide animation for content
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    // Fade animation
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Scale animation
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));

    // Pulse animation
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Rotation animation
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 20));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _rotationController, curve: Curves.linear));
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
  }

  @override
  void dispose() {
    _isDisposed = true;
    _emailController.dispose();
    _passwordController.dispose();
    _backgroundController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
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
                builder: (context, child) =>
                    CustomPaint(painter: _LoginBackgroundPainter(_backgroundGradient.value, _rotationAnimation.value)),
              ),
            ),

            // Content
            SafeArea(
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (_isDisposed || !mounted) return;

                  state.maybeWhen(
                    authenticated: (user) {
                      switch (user.role) {
                        case UserRole.admin:
                          context.go(Routes.layoutAdmin);
                          break;
                        case UserRole.employee:
                          context.go(Routes.layoutEmployee);
                          break;
                        case UserRole.officeBoy:
                          context.go(Routes.layoutOfficeBoy);
                          break;
                      }
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
                  final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);

                  return AnimatedBuilder(
                    animation: Listenable.merge([
                      _fadeController,
                      _slideController,
                      _scaleController,
                      _pulseController,
                      _rotationController,
                    ]),
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: AlwaysStoppedAnimation(_fadeAnimation.value.clamp(0.0, 1.0)),
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: ScaleTransition(
                            scale: AlwaysStoppedAnimation(_scaleAnimation.value.clamp(0.1, 1.0)),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                              child: SizedBox(
                                height: context.height,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Language Dropdown at the top
                                    // const SizedBox(height: 16),
                                    Align(
                                      alignment: locale == 'ar' ? Alignment.topLeft : Alignment.topRight,
                                      child: _buildGlassLanguageDropdown(),
                                    ),

                                    // Header with enhanced design
                                    const SizedBox(height: 16),
                                    _buildAnimatedHeader(),

                                    const SizedBox(height: 24),

                                    // Glass Form Card
                                    _buildGlassForm(isLoading, context),

                                    const SizedBox(height: 24),

                                    // Sign Up Link with glass effect
                                    _buildGlassSignUpSection(context),

                                    const SizedBox(height: 48),
                                  ],
                                ),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(20), child: const CompactLanguageDropdown()),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Center(
      child: Column(
        children: [
          // Animated Logo Container
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) => Transform.rotate(
                  angle: _rotationAnimation.value * 0.1,
                  child: Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.8), AppColors.secondary.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: Icon(Icons.business_center_rounded, size: 48, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Animated Text
          TweenAnimationBuilder<double>(
            tween: Tween(begin: -30.0, end: 0.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, value),
              child: Text(
                LocaleKeys.welcomeBack.tr(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          TweenAnimationBuilder<double>(
            tween: Tween(begin: 30.0, end: 0.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, value),
              child: Text(
                LocaleKeys.signInToAccount.tr(),
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassForm(bool isLoading, BuildContext context) {
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Email Field
                  SizedBox(height: 8),
                  _buildGlassTextField(
                    controller: _emailController,
                    label: LocaleKeys.email.tr(),
                    hint: LocaleKeys.enterEmail.tr(),
                    prefixIcon: Assets.imagesSvgsMail,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocaleKeys.pleaseEnterEmail.tr();
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return LocaleKeys.pleaseEnterValidEmail.tr();
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Password Field
                  _buildGlassTextField(
                    controller: _passwordController,
                    label: LocaleKeys.password.tr(),
                    hint: LocaleKeys.enterPassword.tr(),
                    prefixIcon: Assets.imagesSvgsLock,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    onTogglePassword: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocaleKeys.pleaseEnterPassword.tr();
                      }
                      if (value.length < 6) {
                        return LocaleKeys.passwordMinLength.tr();
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Forgot Password
                  Container(
                    width: double.infinity,
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => _handleForgotPassword(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          LocaleKeys.forgotPassword.tr(),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedButton(
                      text: LocaleKeys.signIn.tr(),
                      onPressed: isLoading ? null : () => _handleLogin(context),
                      isLoading: isLoading,
                      backgroundColor: AppColors.primary,
                      // textColor: Colors.white,
                      width: double.infinity,
                      height: 56,
                      // borderRadius: 16,
                      // elevation: 0,
                      // glowColor: AppColors.primary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String prefixIcon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && !isPasswordVisible,
        style: TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SvgPicture.asset(prefixIcon, color: Colors.white.withOpacity(0.7), height: 20, width: 20),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      ),
    );
  }

  Widget _buildGlassSignUpSection(BuildContext context) {
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
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    LocaleKeys.dontHaveAccount.tr(),
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (mounted && !_isDisposed) {
                        context.push(Routes.accountTypeSelection);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        LocaleKeys.signUp.tr(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    try {
      context.read<AuthCubit>().signIn(email: _emailController.text.trim(), password: _passwordController.text);
    } catch (e) {
      debugPrint('Login error: $e');
      if (mounted && !_isDisposed) {
        showErrorToast(context, e.toString());
      }
    }
  }

  void _handleForgotPassword(BuildContext context) {
    context.push(Routes.forgetPassword);
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  final double animationValue;
  final double rotationValue;

  _LoginBackgroundPainter(this.animationValue, this.rotationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      colors: [AppColors.primary, AppColors.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final paint = Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Animated particles
    final particlePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = (size.width * 0.1) + (i * size.width * 0.04) + (math.sin(animationValue * 2 * math.pi + i) * 30);
      final y = (size.height * 0.2) + (math.cos(animationValue * 2 * math.pi + i * 0.7) * 40);
      final radius = 2 + math.sin(animationValue * 2 * math.pi + i) * 2;

      canvas.drawCircle(Offset(x, y), radius.abs(), particlePaint);
    }

    // Flowing gradient lines
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1.5;

    for (int i = 0; i < 4; i++) {
      final path = Path();
      final startY = size.height * (0.1 + i * 0.2);

      path.moveTo(-50, startY);

      for (double x = -50; x <= size.width + 50; x += 8) {
        final y = startY + math.sin((x * 0.008) + (animationValue * 2 * math.pi) + (i * 2)) * 25;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
