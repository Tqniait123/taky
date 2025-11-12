// // lib/features/all/auth/presentation/pages/forget_password_screen.dart
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:taqy/config/routes/routes.dart';
// import 'package:taqy/core/services/di.dart';
// import 'package:taqy/core/theme/colors.dart';
// import 'package:taqy/core/translations/locale_keys.g.dart';
// import 'package:taqy/core/utils/dialogs/error_toast.dart';
// import 'package:taqy/core/utils/widgets/app_images.dart';
// import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
// import 'package:taqy/features/all/auth/presentation/widgets/animated_button.dart';
// import 'package:taqy/features/all/auth/presentation/widgets/auth_text_field.dart';

// class ForgetPasswordScreen extends StatefulWidget {
//   const ForgetPasswordScreen({super.key});

//   @override
//   State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
// }

// class _ForgetPasswordScreenState extends State<ForgetPasswordScreen>
//     with TickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();

//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   bool _isDisposed = false;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );

//     _slideAnimation =
//         Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
//           CurvedAnimation(
//             parent: _animationController,
//             curve: Curves.easeOutCubic,
//           ),
//         );

//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _isDisposed = true;
//     _emailController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => sl<AuthCubit>(),
//       child: Scaffold(
//         backgroundColor: AppColors.background,
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           leading: IconButton(
//             onPressed: () => context.pop(),
//             icon: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: AppColors.surface,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Icon(
//                 Icons.arrow_back_ios_new,
//                 color: AppColors.onSurface,
//                 size: 20,
//               ),
//             ),
//           ),
//           title: Text(
//             LocaleKeys.forgotPassword.tr(),
//             style: Theme.of(context).textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.w600,
//               color: AppColors.onSurface,
//             ),
//           ),
//           centerTitle: true,
//         ),
//         body: SafeArea(
//           child: BlocConsumer<AuthCubit, AuthState>(
//             listener: (context, state) {
//               if (_isDisposed || !mounted) return;

//               state.maybeWhen(
//                 passwordResetSent: () {
//                   showSuccessToast(
//                     context,
//                     LocaleKeys.passwordResetEmailSent.tr(),
//                   );
//                   // ScaffoldMessenger.of(context).showSnackBar(
//                   //   SnackBar(
//                   //     content: Text(LocaleKeys.passwordResetEmailSent.tr()),
//                   //     backgroundColor: AppColors.success,
//                   //     behavior: SnackBarBehavior.floating,
//                   //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   //   ),
//                   // );
//                   // Navigate back to login after showing success message
//                   Future.delayed(const Duration(seconds: 2), () {
//                     if (mounted && !_isDisposed) {
//                       context.go(
//                         Routes.checkYourEmail,
//                         extra: {
//                           'email': _emailController.text,
//                           'isPasswordReset': true,
//                         },
//                       );
//                     }
//                   });
//                 },
//                 error: (failure) {
//                   if (mounted && !_isDisposed) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text(failure),
//                         backgroundColor: AppColors.error,
//                         behavior: SnackBarBehavior.floating,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     );
//                   }
//                 },
//                 orElse: () {},
//               );
//             },
//             builder: (context, state) {
//               final isLoading = state.maybeWhen(
//                 loading: () => true,
//                 orElse: () => false,
//               );

//               return AnimatedBuilder(
//                 animation: _animationController,
//                 builder: (context, child) {
//                   return FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: SlideTransition(
//                       position: _slideAnimation,
//                       child: SingleChildScrollView(
//                         padding: const EdgeInsets.all(24.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const SizedBox(height: 40),

//                             // Header Icon
//                             Center(
//                               child: Container(
//                                 padding: const EdgeInsets.all(24),
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: [
//                                       AppColors.primary.withOpacity(0.1),
//                                       AppColors.secondary.withOpacity(0.1),
//                                     ],
//                                     begin: Alignment.topLeft,
//                                     end: Alignment.bottomRight,
//                                   ),
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Icon(
//                                   Icons.lock_reset_outlined,
//                                   size: 52,
//                                   color: AppColors.primary,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 32),

//                             // Title
//                             Center(
//                               child: Text(
//                                 LocaleKeys.resetPassword.tr(),
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .headlineMedium
//                                     ?.copyWith(
//                                       fontWeight: FontWeight.bold,
//                                       color: AppColors.primary,
//                                     ),
//                               ),
//                             ),
//                             const SizedBox(height: 12),

//                             // Subtitle
//                             Center(
//                               child: Text(
//                                 LocaleKeys.passwordResetInstructions.tr(),
//                                 textAlign: TextAlign.center,
//                                 style: Theme.of(context).textTheme.bodyLarge
//                                     ?.copyWith(
//                                       color: AppColors.onSurfaceVariant,
//                                       height: 1.5,
//                                     ),
//                               ),
//                             ),

//                             const SizedBox(height: 48),

//                             // Form Card
//                             Container(
//                               padding: const EdgeInsets.all(24),
//                               decoration: BoxDecoration(
//                                 color: AppColors.surface,
//                                 borderRadius: BorderRadius.circular(20),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.black.withOpacity(0.08),
//                                     blurRadius: 20,
//                                     offset: const Offset(0, 8),
//                                   ),
//                                 ],
//                               ),
//                               child: Form(
//                                 key: _formKey,
//                                 child: Column(
//                                   children: [
//                                     // Email Field
//                                     AuthTextField(
//                                       controller: _emailController,
//                                       label: LocaleKeys.email.tr(),
//                                       hint: LocaleKeys.enterEmail.tr(),
//                                       prefixIcon: Assets.imagesSvgsMail,
//                                       keyboardType: TextInputType.emailAddress,
//                                       focusColor: AppColors.secondary,
//                                       validator: (value) {
//                                         if (value == null || value.isEmpty) {
//                                           return LocaleKeys.pleaseEnterEmail
//                                               .tr();
//                                         }
//                                         if (!RegExp(
//                                           r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                                         ).hasMatch(value)) {
//                                           return LocaleKeys
//                                               .pleaseEnterValidEmail
//                                               .tr();
//                                         }
//                                         return null;
//                                       },
//                                     ),

//                                     const SizedBox(height: 32),

//                                     // Send Reset Email Button
//                                     SizedBox(
//                                       width: double.infinity,
//                                       child: AnimatedButton(
//                                         text: LocaleKeys.sendResetEmail.tr(),
//                                         onPressed: isLoading
//                                             ? null
//                                             : () => _handleForgotPassword(
//                                                 context,
//                                               ),
//                                         isLoading: isLoading,
//                                         backgroundColor: AppColors.primary,
//                                         width: double.infinity,
//                                         height: 56,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),

//                             const SizedBox(height: 32),

//                             // Back to Login Link
//                             Center(
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Column(
//                                     children: [
//                                       Text(
//                                         LocaleKeys.rememberPassword.tr(),
//                                         style: TextStyle(
//                                           color: AppColors.onSurfaceVariant,
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                                       TextButton(
//                                         onPressed: () {
//                                           if (mounted && !_isDisposed) {
//                                             context.go(Routes.login);
//                                           }
//                                         },
//                                         child: Text(
//                                           LocaleKeys.backToLogin.tr(),
//                                           style:  TextStyle(
//                                             color: AppColors.primary,
//                                             fontWeight: FontWeight.w600,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   void _handleForgotPassword(BuildContext context) {
//     if (!_formKey.currentState!.validate()) return;

//     try {
//       context.read<AuthCubit>().forgotPassword(_emailController.text.trim());
//     } catch (e) {
//       debugPrint('Forgot password error: $e');
//       if (mounted && !_isDisposed) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(LocaleKeys.passwordResetEmailFailed.tr()),
//             backgroundColor: AppColors.error,
//           ),
//         );
//       }
//     }
//   }
// }

// lib/features/all/auth/presentation/pages/forget_password_screen.dart
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
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

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

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

  bool _isDisposed = false;

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
                builder: (context, child) => CustomPaint(
                  painter: _ForgetPasswordBackgroundPainter(
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
                      showSuccessToast(
                        context,
                        LocaleKeys.passwordResetEmailSent.tr(),
                      );
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with Back Button and Language
                                  _buildHeaderSection(locale, context),

                                  const SizedBox(height: 24),

                                  // Animated Header Content
                                  _buildAnimatedHeader(),

                                  const SizedBox(height: 24),

                                  // Glass Form Card
                                  _buildGlassForm(isLoading, context),

                                  const SizedBox(height: 24),

                                  // Back to Login with glass effect
                                  _buildGlassLoginSection(context),
                                  const SizedBox(height: 32),
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
                  onPressed: () => context.pop(),
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

  Widget _buildAnimatedHeader() {
    return Center(
      child: Column(
        children: [
          // Animated Lock Icon Container
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) => Transform.rotate(
                  angle: _rotationAnimation.value * 0.1,
                  child: Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(24),
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
                    child: Icon(
                      Icons.lock_reset_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Animated Text
          TweenAnimationBuilder<double>(
            tween: Tween(begin: -30.0, end: 0.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, value),
              child: Text(
                LocaleKeys.resetPassword.tr(),
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
                LocaleKeys.passwordResetInstructions.tr(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 8),
                  // Email Field
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
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return LocaleKeys.pleaseEnterValidEmail.tr();
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  // Send Reset Email Button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedButton(
                      text: LocaleKeys.sendResetEmail.tr(),
                      onPressed: isLoading
                          ? null
                          : () => _handleForgotPassword(context),
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
        style: TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SvgPicture.asset(
              prefixIcon,
              color: Colors.white.withOpacity(0.7),
              height: 20,
              width: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      ),
    );
  }

  Widget _buildGlassLoginSection(BuildContext context) {
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
              child: Column(
                children: [
                  Text(
                    LocaleKeys.rememberPassword.tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      if (mounted && !_isDisposed) {
                        context.go(Routes.login);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        LocaleKeys.backToLogin.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
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

  void _handleForgotPassword(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    try {
      context.read<AuthCubit>().forgotPassword(_emailController.text.trim());
    } catch (e) {
      debugPrint('Forgot password error: $e');
      if (mounted && !_isDisposed) {
        showErrorToast(context, LocaleKeys.passwordResetEmailFailed.tr());
      }
    }
  }
}

class _ForgetPasswordBackgroundPainter extends CustomPainter {
  final double animationValue;
  final double rotationValue;

  _ForgetPasswordBackgroundPainter(this.animationValue, this.rotationValue);

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

    for (int i = 0; i < 18; i++) {
      final x =
          (size.width * 0.1) +
          (i * size.width * 0.05) +
          (math.sin(animationValue * 2 * math.pi + i) * 35);
      final y =
          (size.height * 0.2) +
          (math.cos(animationValue * 2 * math.pi + i * 0.7) * 45);
      final radius = 2 + math.sin(animationValue * 2 * math.pi + i) * 2.5;

      canvas.drawCircle(Offset(x, y), radius.abs(), particlePaint);
    }

    // Flowing gradient lines
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.12),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1.8;

    for (int i = 0; i < 4; i++) {
      final path = Path();
      final startY = size.height * (0.1 + i * 0.25);

      path.moveTo(-50, startY);

      for (double x = -50; x <= size.width + 50; x += 8) {
        final y =
            startY +
            math.sin((x * 0.009) + (animationValue * 2 * math.pi) + (i * 2)) *
                28;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, linePaint);
    }

    // Additional security-themed elements
    final securityPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw some lock-like shapes in background
    for (int i = 0; i < 3; i++) {
      final centerX = size.width * (0.2 + i * 0.3);
      final centerY = size.height * 0.7;
      final lockSize = 40 + math.sin(animationValue * 2 * math.pi + i) * 10;

      // Lock body
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: lockSize * 0.6,
            height: lockSize * 0.8,
          ),
          Radius.circular(8),
        ),
        securityPaint,
      );

      // Lock arc
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX, centerY - lockSize * 0.3),
          width: lockSize * 0.8,
          height: lockSize * 0.4,
        ),
        math.pi,
        math.pi,
        false,
        securityPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
