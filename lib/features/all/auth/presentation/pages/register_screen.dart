// lib/features/auth/presentation/screens/register_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/translations/locale_keys.g.dart';

import '../widgets/animated_button.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  final String accountType;

  const RegisterScreen({super.key, required this.accountType});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _orgCodeController = TextEditingController();
  final _orgNameController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _orgCodeController.dispose();
    _orgNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value.dy * MediaQuery.of(context).size.height),
                child: child,
              ),
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const SizedBox(height: 20),
                _buildHeader(context),
                const SizedBox(height: 32),

                // Form Card
                _buildFormCard(context),
                const SizedBox(height: 32),

                // Sign In Link
                _buildSignInLink(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Icon(Icons.arrow_back_ios, color: AppColors.onSurfaceVariant, size: 20),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  LocaleKeys.createAccount.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getAccountTypeTitle(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Name Field
            AuthTextField(
              controller: _nameController,
              label: LocaleKeys.fullName.tr(),
              hint: LocaleKeys.enterFullName.tr(),
              prefixIcon: Icons.person_outline,
              focusColor: _getAccountTypeColor(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return LocaleKeys.pleaseEnterName.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Email Field
            AuthTextField(
              controller: _emailController,
              label: LocaleKeys.email.tr(),
              hint: LocaleKeys.enterEmail.tr(),
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              focusColor: _getAccountTypeColor(),
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

            // Phone Field
            AuthTextField(
              controller: _phoneController,
              label: LocaleKeys.phoneNumber.tr(),
              hint: LocaleKeys.enterPhoneNumber.tr(),
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              focusColor: _getAccountTypeColor(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return LocaleKeys.pleaseEnterPhoneNumber.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Organization fields - Fixed conditional rendering
            ..._buildOrganizationFields(),

            // Password Field
            AuthTextField(
              controller: _passwordController,
              label: LocaleKeys.password.tr(),
              hint: LocaleKeys.createPassword.tr(),
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              isPasswordVisible: _isPasswordVisible,
              focusColor: _getAccountTypeColor(),
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
            const SizedBox(height: 24),

            // Confirm Password Field
            AuthTextField(
              controller: _confirmPasswordController,
              label: LocaleKeys.confirmPassword.tr(),
              hint: LocaleKeys.confirmYourPassword.tr(),
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              isPasswordVisible: _isConfirmPasswordVisible,
              focusColor: _getAccountTypeColor(),
              onTogglePassword: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return LocaleKeys.pleaseConfirmPassword.tr();
                }
                if (value != _passwordController.text) {
                  return LocaleKeys.passwordsDoNotMatch.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Register Button
            AnimatedButton(
              text: LocaleKeys.createAccount.tr(),
              onPressed: _isLoading ? null : _handleRegister,
              isLoading: _isLoading,
              backgroundColor: _getAccountTypeColor(),
              width: double.infinity,
              height: 56,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrganizationFields() {
    List<Widget> fields = [];

    if (widget.accountType != 'admin') {
      // Organization code for Employee and Office Boy
      fields.addAll([
        AuthTextField(
          controller: _orgCodeController,
          label: LocaleKeys.organizationCode.tr(),
          hint: LocaleKeys.enterOrganizationCode.tr(),
          prefixIcon: Icons.business_outlined,
          focusColor: _getAccountTypeColor(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return LocaleKeys.pleaseEnterOrganizationCode.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
      ]);
    } else {
      // Organization name for Admin
      fields.addAll([
        AuthTextField(
          controller: _orgNameController,
          label: LocaleKeys.organizationName.tr(),
          hint: LocaleKeys.enterOrganizationName.tr(),
          prefixIcon: Icons.business_outlined,
          focusColor: _getAccountTypeColor(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return LocaleKeys.pleaseEnterOrganizationName.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
      ]);
    }

    return fields;
  }

  Widget _buildSignInLink(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(LocaleKeys.alreadyHaveAccount.tr(), style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.go(Routes.login),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: _getAccountTypeColor(), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  LocaleKeys.signIn.tr(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAccountTypeTitle() {
    switch (widget.accountType) {
      case 'admin':
        return LocaleKeys.organizationAdministrator.tr();
      case 'employee':
        return LocaleKeys.employeeAccount.tr();
      case 'office_boy':
        return LocaleKeys.officeBoyAccount.tr();
      default:
        return LocaleKeys.createAccount.tr();
    }
  }

  Color _getAccountTypeColor() {
    switch (widget.accountType) {
      case 'admin':
        return AppColors.primary;
      case 'employee':
        return AppColors.secondary;
      case 'office_boy':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Implement registration logic with Supabase
      await Future.delayed(const Duration(seconds: 2)); // Simulate network call

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleKeys.accountCreatedSuccessfully.tr()), backgroundColor: AppColors.success),
        );

        // Navigate to login or dashboard
        if (widget.accountType == 'admin') {
          context.go(Routes.login);
        } else {
          context.go(Routes.login);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(LocaleKeys.registrationFailed.tr()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
