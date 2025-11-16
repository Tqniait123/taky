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
import 'package:taqy/features/all/auth/domain/entities/user.dart' as entities;
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/all/auth/presentation/widgets/animated_button.dart';
import 'package:taqy/features/all/auth/presentation/widgets/color_picker_widget.dart';
import 'package:taqy/features/all/auth/presentation/widgets/language_drop_down.dart';

class RegisterScreen extends StatefulWidget {
  final String accountType;

  const RegisterScreen({super.key, required this.accountType});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _orgCodeController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _jobTitleController = TextEditingController();

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
  bool _isConfirmPasswordVisible = false;
  bool _isDisposed = false;

  // Color selection for admin
  Color _selectedPrimaryColor = AppColors.primary;
  Color _selectedSecondaryColor = AppColors.secondary;

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _orgCodeController.dispose();
    _orgNameController.dispose();
    _jobTitleController.dispose();
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
                  painter: _RegisterBackgroundPainter(
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

                  state.whenOrNull(
                    authenticated: (user) {
                      showSuccessToast(
                        context,
                        LocaleKeys.accountCreatedSuccessfully.tr(),
                      );
                      context.go(Routes.login);
                    },
                    error: (failure) {
                      if (mounted && !_isDisposed) {
                        showErrorToast(context, failure);
                      }
                    },
                    organizationCodeChecked: (exists) {
                      if (!exists && !_isDisposed && mounted) {
                        showErrorToast(
                          context,
                          LocaleKeys.organizationCodeNotFound.tr(),
                        );
                      }
                    },
                  );
                },
                builder: (context, state) {
                  final isLoading = state.maybeWhen(
                    loading: () => true,
                    checkingOrganizationCode: () => true,
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

                                  // Glass Form Card
                                  _buildGlassForm(isLoading, context, locale),

                                  const SizedBox(height: 24),

                                  // Sign In Link with glass effect
                                  _buildGlassSignInSection(context),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Button and Language Dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button with glass effect
            AnimatedBuilder(
              animation: _scaleController,
              builder: (context, child) => Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
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
        ),

        const SizedBox(height: 24),

        // Animated Header
        _buildAnimatedHeader(context),
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

  Widget _buildAnimatedHeader(BuildContext context) {
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getAccountTypeColor().withOpacity(0.8),
                          _getAccountTypeColor().withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getAccountTypeColor().withOpacity(0.3),
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
                      _getAccountTypeIcon(),
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Animated Text
          TweenAnimationBuilder<double>(
            tween: Tween(begin: -30.0, end: 0.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, value),
              child: Text(
                LocaleKeys.createAccount.tr(),
                style: TextStyle(
                  fontSize: 28,
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
          const SizedBox(height: 8),

          TweenAnimationBuilder<double>(
            tween: Tween(begin: 30.0, end: 0.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, value),
              child: Text(
                _getAccountTypeTitle(),
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

  Widget _buildGlassForm(bool isLoading, BuildContext context, String locale) {
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
                  const SizedBox(height: 8),
                  // Name Field
                  _buildGlassTextField(
                    controller: _nameController,
                    label: LocaleKeys.fullName.tr(),
                    hint: LocaleKeys.enterFullName.tr(),
                    prefixIcon: Assets.imagesSvgsUser,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocaleKeys.pleaseEnterName.tr();
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

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

                  const SizedBox(height: 20),

                  // Phone Field
                  _buildGlassTextField(
                    controller: _phoneController,
                    label: LocaleKeys.phoneNumber.tr(),
                    hint: LocaleKeys.enterPhoneNumber.tr(),
                    prefixIcon: Assets.imagesSvgsPhone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return LocaleKeys.pleaseEnterPhoneNumber.tr();
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Organization Fields
                  ..._buildOrganizationFields(locale),

                  const SizedBox(height: 20),

                  // Password Field
                  _buildGlassTextField(
                    controller: _passwordController,
                    label: LocaleKeys.password.tr(),
                    hint: LocaleKeys.createPassword.tr(),
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

                  // Confirm Password Field
                  _buildGlassTextField(
                    controller: _confirmPasswordController,
                    label: LocaleKeys.confirmPassword.tr(),
                    hint: LocaleKeys.confirmYourPassword.tr(),
                    prefixIcon: Assets.imagesSvgsLock,
                    isPassword: true,
                    isPasswordVisible: _isConfirmPasswordVisible,
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

                  const SizedBox(height: 28),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedButton(
                      text: LocaleKeys.createAccount.tr(),
                      onPressed: isLoading
                          ? null
                          : () => _handleRegister(context),
                      isLoading: isLoading,
                      backgroundColor: _getAccountTypeColor(),
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

  List<Widget> _buildOrganizationFields(String locale) {
    List<Widget> fields = [];

    if (widget.accountType != 'admin') {
      // Organization code for Employee and Office Boy
      fields.addAll([
        _buildGlassTextField(
          controller: _orgCodeController,
          label: LocaleKeys.organizationCode.tr(),
          hint: LocaleKeys.enterOrganizationCode.tr(),
          prefixIcon: Assets.imagesSvgsCode,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return LocaleKeys.pleaseEnterOrganizationCode.tr();
            }
            return null;
          },
        ),
        // const SizedBox(height: 20),
      ]);

      if (widget.accountType == 'employee') {
        fields.add(const SizedBox(height: 20));
        fields.add(
          _buildGlassTextField(
            controller: _jobTitleController,
            label: locale == 'ar' ? 'المسمى الوظيفي' : 'Job Title',
            hint: locale == 'ar'
                ? 'أدخل المسمى الوظيفي'
                : 'Enter your job title',
            prefixIcon: Assets.imagesSvgsUser, // You'll need to add this icon
            validator: (value) {
              if (value == null || value.isEmpty) {
                return locale == 'ar'
                    ? 'الرجاء إدخال المسمى الوظيفي'
                    : 'Please enter your job title';
              }
              return null;
            },
          ),
        );
      }
    } else {
      // Organization name and color selection for Admin
      fields.addAll([
        _buildGlassTextField(
          controller: _orgCodeController,
          label: LocaleKeys.organizationCode.tr(),
          hint: LocaleKeys.enterOrganizationCode.tr(),
          prefixIcon: Assets.imagesSvgsCode,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return LocaleKeys.pleaseEnterOrganizationCode.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildGlassTextField(
          controller: _orgNameController,
          label: LocaleKeys.organizationName.tr(),
          hint: LocaleKeys.enterOrganizationName.tr(),
          prefixIcon: Assets.imagesSvgsCompany,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return LocaleKeys.pleaseEnterOrganizationName.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Glass Color Pickers
        _buildGlassColorPicker(
          label: LocaleKeys.primary_color.tr(),
          selectedColor: _selectedPrimaryColor,
          onColorSelected: (color) {
            setState(() {
              _selectedPrimaryColor = color;
            });
          },
        ),
        const SizedBox(height: 20),

        _buildGlassColorPicker(
          label: LocaleKeys.secondary_color.tr(),
          selectedColor: _selectedSecondaryColor,
          onColorSelected: (color) {
            setState(() {
              _selectedSecondaryColor = color;
            });
          },
        ),
        // const SizedBox(height: 20),
      ]);
    }

    return fields;
  }

  Widget _buildGlassColorPicker({
    required String label,
    required Color selectedColor,
    required Function(Color) onColorSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ModernColorPicker(
            selectedColor: selectedColor,
            onColorSelected: onColorSelected,
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildGlassSignInSection(BuildContext context) {
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
                    LocaleKeys.alreadyHaveAccount.tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (mounted && !_isDisposed) {
                        context.go(Routes.login);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
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
                        LocaleKeys.signIn.tr(),
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

  // Helper Methods
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
        return _selectedPrimaryColor;
      case 'employee':
        return AppColors.secondary;
      case 'office_boy':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  IconData _getAccountTypeIcon() {
    switch (widget.accountType) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'employee':
        return Icons.business_center_rounded;
      case 'office_boy':
        return Icons.engineering_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  entities.UserRole _getAccountTypeRole() {
    switch (widget.accountType) {
      case 'admin':
        return entities.UserRole.admin;
      case 'employee':
        return entities.UserRole.employee;
      case 'office_boy':
        return entities.UserRole.officeBoy;
      default:
        return entities.UserRole.employee;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _handleRegister(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    // For non-admin users, check organization code first
    if (widget.accountType != 'admin' && _orgCodeController.text.isNotEmpty) {
      context.read<AuthCubit>().checkOrganizationCode(_orgCodeController.text);

      // Wait for organization code check to complete
      await Future.delayed(const Duration(milliseconds: 500));

      final currentState = context.read<AuthCubit>().state;
      if (currentState is AuthOrganizationCodeChecked && !currentState.exists) {
        return; // Don't proceed if organization code doesn't exist
      }
    }

    // Proceed with registration
    context.read<AuthCubit>().signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      role: _getAccountTypeRole(),
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      organizationName: _orgNameController.text.trim().isNotEmpty
          ? _orgNameController.text.trim()
          : null,
      organizationCode: _orgCodeController.text.trim().isNotEmpty
          ? _orgCodeController.text.trim()
          : null,
      primaryColor: widget.accountType == 'admin'
          ? _colorToHex(_selectedPrimaryColor)
          : null,
      secondaryColor: widget.accountType == 'admin'
          ? _colorToHex(_selectedSecondaryColor)
          : null,
      jobTitle:
          widget.accountType == 'employee' &&
              _jobTitleController.text.trim().isNotEmpty
          ? _jobTitleController.text.trim()
          : null,
    );
  }
}

class _RegisterBackgroundPainter extends CustomPainter {
  final double animationValue;
  final double rotationValue;

  _RegisterBackgroundPainter(this.animationValue, this.rotationValue);

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

    for (int i = 0; i < 25; i++) {
      final x =
          (size.width * 0.1) +
          (i * size.width * 0.03) +
          (math.sin(animationValue * 2 * math.pi + i) * 40);
      final y =
          (size.height * 0.2) +
          (math.cos(animationValue * 2 * math.pi + i * 0.7) * 50);
      final radius = 2 + math.sin(animationValue * 2 * math.pi + i) * 3;

      canvas.drawCircle(Offset(x, y), radius.abs(), particlePaint);
    }

    // Flowing gradient lines
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2.0;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final startY = size.height * (0.1 + i * 0.15);

      path.moveTo(-50, startY);

      for (double x = -50; x <= size.width + 50; x += 8) {
        final y =
            startY +
            math.sin((x * 0.01) + (animationValue * 2 * math.pi) + (i * 2)) *
                30;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
