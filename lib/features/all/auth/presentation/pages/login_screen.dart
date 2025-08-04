// lib/features/all/auth/presentation/pages/login_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/services/di.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/translations/locale_keys.g.dart';
import 'package:taqy/features/all/auth/domain/entities/user.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/all/auth/presentation/widgets/animated_button.dart';
import 'package:taqy/features/all/auth/presentation/widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (_isDisposed || !mounted) return;

              state.maybeWhen(
                authenticated: (user) {
                  // Navigate to dashboard based on user role
                  switch (user.role) {
                    case UserRole.admin:
                      // context.go(Routes.adminDashboard);
                      context.go(Routes.layoutAdmin); // Fallback
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(failure), backgroundColor: AppColors.error));
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
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            const SizedBox(height: 40),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.business_center_outlined, size: 52, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 32),

                            Center(
                              child: ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [AppColors.primary, AppColors.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  LocaleKeys.welcomeBack.tr(),
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                LocaleKeys.signInToAccount.tr(),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
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
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      focusColor: AppColors.primary,
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

                                    const SizedBox(height: 24),

                                    // Password Field
                                    AuthTextField(
                                      controller: _passwordController,
                                      label: LocaleKeys.password.tr(),
                                      hint: LocaleKeys.enterPassword.tr(),
                                      prefixIcon: Icons.lock_outline,
                                      isPassword: true,
                                      isPasswordVisible: _isPasswordVisible,
                                      focusColor: AppColors.primary,
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
                                        child: Text(
                                          LocaleKeys.forgotPassword.tr(),
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    // Login Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: AnimatedButton(
                                        text: LocaleKeys.signIn.tr(),
                                        onPressed: isLoading ? null : () => _handleLogin(context),
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

                            // Divider
                            Row(
                              children: [
                                Expanded(child: Container(height: 1, color: AppColors.outline)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    LocaleKeys.or.tr(),
                                    style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(child: Container(height: 1, color: AppColors.outline)),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // Sign Up Link
                            Center(
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
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      LocaleKeys.dontHaveAccount.tr(),
                                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16),
                                    ),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () {
                                        if (mounted && !_isDisposed) {
                                          context.push(Routes.accountTypeSelection);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [AppColors.primary, AppColors.secondary],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          LocaleKeys.signUp.tr(),
                                          style: const TextStyle(
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

  void _handleLogin(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    try {
      context.read<AuthCubit>().signIn(email: _emailController.text.trim(), password: _passwordController.text);
    } catch (e) {
      debugPrint('Login error: $e');
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _handleForgotPassword(BuildContext context) {
    // context.push(Routes.forgotPassword);
    debugPrint('Forgot password tapped');
  }
}
