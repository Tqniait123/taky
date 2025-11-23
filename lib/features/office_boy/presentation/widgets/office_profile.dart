import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/services/firebase_service.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/admin/presentation/widgets/language_layout_drop_down.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/office_boy/data/models/office_organization.dart';
import 'package:taqy/features/office_boy/data/models/office_user_model.dart';

class OfficeBoyProfileBottomSheet extends StatefulWidget {
  final OfficeUserModel user;
  final OfficeOrganization organization;
  final VoidCallback onLogout;
  final Function(OfficeUserModel) onProfileUpdated;

  const OfficeBoyProfileBottomSheet({
    super.key,
    required this.user,
    required this.organization,
    required this.onLogout,
    required this.onProfileUpdated,
  });

  @override
  State<OfficeBoyProfileBottomSheet> createState() =>
      _OfficeBoyProfileBottomSheetState();
}

class _OfficeBoyProfileBottomSheetState
    extends State<OfficeBoyProfileBottomSheet>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isSaving = false;
  bool _hasChanges = false;

  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');

    // Add listeners to track changes
    _nameController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);

    _initializeAnimations();
    _startAnimations();
  }

  void _checkForChanges() {
    final nameChanged = _nameController.text.trim() != widget.user.name;
    final phoneChanged =
        _phoneController.text.trim() != (widget.user.phone ?? '');

    setState(() {
      _hasChanges = nameChanged || phoneChanged;
    });
  }

  void _initializeAnimations() {
    // Slide animation for content entrance
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Scale animation for cards
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Glow animation for interactive elements
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Particle animation for background
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    // Shimmer effect
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  void _startAnimations() {
    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
    _glowController.repeat(reverse: true);
    _particleController.repeat();
    _shimmerController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return AnimatedBuilder(
      animation: Listenable.merge([
        _slideController,
        _fadeController,
        _scaleController,
      ]),
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          MediaQuery.of(context).size.height * 0.1 * _slideAnimation.value,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  // Animated background with particles
                  Positioned.fill(child: _buildAnimatedBackground()),

                  // Glass morphism container
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.25),
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: _buildContent(locale),
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

  Future<void> _updateProfile(String locale) async {
    if (_nameController.text.trim().isEmpty) {
      showErrorToast(
        context,
        locale == 'ar' ? 'لا يمكن ان يكون الاسم فارغ' : 'Name cannot be empty',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firebaseService.updateDocument(
        'users',
        widget.user.id,
        updateData,
      );

      // Get updated user data
      final userDoc = await _firebaseService.getDocument(
        'users',
        widget.user.id,
      );
      final updatedUser = OfficeUserModel.fromFirestore(userDoc);

      widget.onProfileUpdated(updatedUser);

      showSuccessToast(
        context,
        locale == 'ar'
            ? 'تم تحديث الملف الشخصي بنجاح'
            : 'Profile updated successfully!',
      );

      Navigator.pop(context);
    } catch (e) {
      showErrorToast(
        context,
        locale == 'ar'
            ? 'فشل تحديث الملف الشخصي'
            : 'Failed to update profile: $e',
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showLogoutConfirmation(String locale) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildGlassDialog(locale),
    );
  }

  void _showDeleteAccountConfirmation(String locale) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return OfficeBoyDeleteAccountDialog(
          locale: locale,
          user: widget.user,
          firebaseService: _firebaseService,
          glowAnimation: _glowAnimation,
          glowController: _glowController,
        );
      },
    );
  }

  Widget _buildGlassDialog(String locale) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon with pulse animation
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) => Transform.scale(
                    scale: 1.0 + (_glowAnimation.value * 0.1),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.error.withOpacity(0.3),
                            AppColors.error.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withOpacity(
                              _glowAnimation.value * 0.3,
                            ),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Title
                Text(
                  locale == 'ar' ? 'تسجيل الخروج' : 'Confirm Logout',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),

                // Message
                Text(
                  locale == 'ar'
                      ? 'هل أنت متأكد من تسجيل الخروج؟\n سيتم تحويلك إلى صفحة تسجيل الدخول.'
                      : 'Are you sure you want to logout?\nYou will be redirected to the login screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(context),
                            child: Center(
                              child: Text(
                                locale == 'ar' ? 'الغاء' : 'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.error,
                              AppColors.error.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.4),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              Navigator.pop(context);
                              widget.onLogout();
                            },
                            child: Center(
                              child: Text(
                                locale == 'ar' ? 'تسجيل الخروج' : 'Logout',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_particleController, _shimmerController]),
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.organization.primaryColorValue.withOpacity(0.1),
              widget.organization.secondaryColorValue.withOpacity(0.1),
              widget.organization.primaryColorValue.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: CustomPaint(
          painter: ParticlesPainter(
            _particleAnimation.value,
            widget.organization.primaryColorValue,
            widget.organization.secondaryColorValue,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildContent(String locale) {
    return Column(
      children: [
        _buildGlassHeader(locale),
        Expanded(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                _buildProfileAvatar(),
                SizedBox(height: 32),
                _buildUserInfoCard(locale),
                SizedBox(height: 32),

                // Settings Section with Language
                _buildSettingsSection(locale),
                SizedBox(height: 24),

                _buildGlassTextField(
                  controller: _nameController,
                  label: locale == 'ar' ? 'الاسم كامل' : 'Full Name',
                  hint: locale == 'ar'
                      ? 'ادخل الاسم كامل'
                      : 'Enter your full name',
                  icon: Assets.imagesSvgsUser,
                  delay: 0,
                ),
                SizedBox(height: 24),
                _buildGlassTextField(
                  controller: _phoneController,
                  label: locale == 'ar' ? 'رقم الهاتف' : 'Phone Number',
                  hint: locale == 'ar'
                      ? 'ادخل رقم الهاتف'
                      : 'Enter your phone number',
                  icon: Assets.imagesSvgsPhone,
                  delay: 100,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
        _buildGlassBottomActions(locale),
      ],
    );
  }

  // Dedicated Settings Section
  Widget _buildSettingsSection(String locale) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.settings_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          locale == 'ar' ? 'الإعدادات' : 'Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Language Setting Item
                    _buildSettingItem(
                      icon: Icons.language_rounded,
                      title: locale == 'ar' ? 'اللغة' : 'Language',
                      subtitle: locale == 'ar'
                          ? 'تغيير لغة التطبيق'
                          : 'Change app language',
                      child: LanguageLayoutDropdown(
                        primaryColor: widget.organization.primaryColorValue,
                        secondaryColor: widget.organization.secondaryColorValue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Setting Item Builder
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildGlassHeader(String locale) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - value)),
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Handle bar with glow effect
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) => Container(
                    margin: EdgeInsets.only(bottom: 20),
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(
                            0.3 + (_glowAnimation.value * 0.4),
                          ),
                          Colors.white.withOpacity(
                            0.3 + (_glowAnimation.value * 0.4),
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: widget.organization.primaryColorValue
                              .withOpacity(_glowAnimation.value * 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                Row(
                  children: [
                    // Animated title with shimmer effect
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) => Text(
                          locale == 'ar' ? 'الملف الشخصي' : 'Profile',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    // Animated close button
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) => Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withOpacity(
                                        0.2 + (_glowAnimation.value * 0.1),
                                      ),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(
                                        _glowAnimation.value * 0.2,
                                      ),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Center(
            child: Stack(
              children: [
                // Main avatar with glow effect
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) => Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          widget.organization.primaryColorValue,
                          widget.organization.secondaryColorValue,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.organization.primaryColorValue
                              .withOpacity(0.3 + (_glowAnimation.value * 0.3)),
                          blurRadius: 20 + (_glowAnimation.value * 10),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(child: _buildDefaultAvatar()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Text(
          widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'O',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(String locale) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title with gradient
                    Text(
                      locale == 'ar' ? 'معلومات الحساب' : 'Account Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildInfoRow(
                      Assets.imagesSvgsCompany,
                      widget.organization.name,
                      0,
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow(
                      Assets.imagesSvgsCode,
                      widget.organization.code,
                      100,
                    ),
                    SizedBox(height: 16),
                    _buildEmailRow(
                      Assets.imagesSvgsMail,
                      widget.user.email,
                      200,
                      locale,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String icon, String text, int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(
                  icon,
                  color: Colors.white.withOpacity(0.8),
                  height: 20,
                  width: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmailRow(String icon, String email, int delay, String locale) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(
                  icon,
                  color: Colors.white.withOpacity(0.8),
                  height: 20,
                  width: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _showFullEmailDialog(email, locale);
                  },
                  child: Tooltip(
                    message: locale == 'ar'
                        ? 'اظهار البريد الالكتروني الكامل'
                        : 'Tap to view full email',
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getTruncatedEmail(email),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.visibility_outlined,
                            color: Colors.white.withOpacity(0.6),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTruncatedEmail(String email) {
    const int maxLength = 25;

    if (email.length <= maxLength) {
      return email;
    }

    final atIndex = email.indexOf('@');
    if (atIndex == -1) return email;

    final username = email.substring(0, atIndex);
    final domain = email.substring(atIndex);

    if (username.length > 15) {
      return '${username.substring(0, 12)}...$domain';
    } else {
      return email;
    }
  }

  void _showFullEmailDialog(String email, String locale) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Email icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.email_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SizedBox(height: 20),

                // Title
                Text(
                  locale == 'ar' ? 'البريد الالكتروني' : 'Email Address',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),

                // Full email with selection
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: SelectableText(
                    email,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 24),

                // Copy button
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.organization.primaryColorValue,
                        widget.organization.secondaryColorValue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: widget.organization.primaryColorValue
                            .withOpacity(0.4),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _copyToClipboard(email, context, locale);
                        Navigator.pop(context);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            locale == 'ar'
                                ? 'نسخ البريد الالكتروني'
                                : 'Copy Email',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),

                // Close button
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context),
                      child: Center(
                        child: Text(
                          locale == 'ar' ? 'اغلاق' : 'Close',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text, BuildContext context, String locale) {
    Clipboard.setData(ClipboardData(text: text));
    showSuccessToast(
      context,
      locale == 'ar'
          ? 'تم نسخ البريد الالكتروني'
          : 'Email copied to clipboard!',
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String icon,
    required int delay,
    TextInputType? keyboardType,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(100 * (1 - value), 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animated label
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 12),

              // Glass text field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: TextFormField(
                      controller: controller,
                      keyboardType: keyboardType,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            icon,
                            color: Colors.white,
                            fit: BoxFit.scaleDown,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassBottomActions(String locale) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1200),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - value)),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  children: [
                    // Update Profile button with glow effect
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) => Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: _hasChanges && !_isSaving
                              ? LinearGradient(
                                  colors: [
                                    widget.organization.primaryColorValue,
                                    widget.organization.secondaryColorValue,
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.withOpacity(0.6),
                                    Colors.grey.withOpacity(0.4),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _hasChanges && !_isSaving
                              ? [
                                  BoxShadow(
                                    color: widget.organization.primaryColorValue
                                        .withOpacity(
                                          0.4 + (_glowAnimation.value * 0.2),
                                        ),
                                    blurRadius: 15 + (_glowAnimation.value * 5),
                                    spreadRadius: 1,
                                    offset: Offset(0, 6),
                                  ),
                                ]
                              : [],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: (_hasChanges && !_isSaving)
                                ? () => _updateProfile(locale)
                                : null,
                            child: Container(
                              alignment: Alignment.center,
                              child: _isSaving
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          locale == 'ar'
                                              ? 'تحديث...'
                                              : 'Updating...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      locale == 'ar'
                                          ? 'تحديث الملف الشخصي'
                                          : 'Update Profile',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Logout button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade600,
                            Colors.orange.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isSaving
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _showLogoutConfirmation(locale);
                                },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              locale == 'ar' ? 'تسجيل الخروج' : 'Logout',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Delete Account button (NEW)
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade700, Colors.red.shade900],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isSaving
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _showDeleteAccountConfirmation(locale);
                                },
                          child: Container(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_forever_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  locale == 'ar'
                                      ? 'حذف الحساب'
                                      : 'Delete Account',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Separate widget for Office Boy Delete Account Dialog
class OfficeBoyDeleteAccountDialog extends StatefulWidget {
  final String locale;
  final OfficeUserModel user;
  final FirebaseService firebaseService;
  final Animation<double> glowAnimation;
  final AnimationController glowController;

  const OfficeBoyDeleteAccountDialog({
    super.key,
    required this.locale,
    required this.user,
    required this.firebaseService,
    required this.glowAnimation,
    required this.glowController,
  });

  @override
  State<OfficeBoyDeleteAccountDialog> createState() =>
      _OfficeBoyDeleteAccountDialogState();
}

class _OfficeBoyDeleteAccountDialogState
    extends State<OfficeBoyDeleteAccountDialog> {
  late TextEditingController _passwordController;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon
              AnimatedBuilder(
                animation: widget.glowController,
                builder: (context, child) => Transform.scale(
                  scale: 1.0 + (widget.glowAnimation.value * 0.1),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.red.withOpacity(0.3),
                          Colors.red.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(
                            widget.glowAnimation.value * 0.3,
                          ),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.warning_rounded,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Title
              Text(
                widget.locale == 'ar' ? 'حذف الحساب' : 'Delete Account',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),

              // Warning message
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.locale == 'ar'
                          ? '⚠️ تحذير: هذا الإجراء لا يمكن التراجع عنه!'
                          : '⚠️ Warning: This action cannot be undone!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade300,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.locale == 'ar'
                          ? 'سيتم حذف:\n• حسابك بالكامل\n• جميع بياناتك الشخصية\n• جميع طلباتك وسجلاتك\n• جميع الملفات والصور المرتبطة'
                          : 'This will permanently delete:\n• Your entire account\n• All your personal data\n• All your requests and records\n• All associated files and images',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Password confirmation field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: TextFormField(
                      controller: _passwordController,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      obscureText: true,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: widget.locale == 'ar'
                            ? 'أدخل كلمة المرور للتأكيد'
                            : 'Enter your password to confirm',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        prefixIcon: SvgPicture.asset(
                          Assets.imagesSvgsLock,
                          color: Colors.white.withOpacity(0.8),
                          fit: BoxFit.scaleDown,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _isDeleting
                              ? null
                              : () {
                                  Navigator.pop(context);
                                },
                          child: Center(
                            child: Text(
                              widget.locale == 'ar' ? 'إلغاء' : 'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade700, Colors.red.shade900],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _isDeleting
                              ? null
                              : () async {
                                  if (_passwordController.text.trim().isEmpty) {
                                    showErrorToast(
                                      context,
                                      widget.locale == 'ar'
                                          ? 'الرجاء إدخال كلمة المرور'
                                          : 'Please enter your password',
                                    );
                                    return;
                                  }

                                  setState(() {
                                    _isDeleting = true;
                                  });

                                  try {
                                    final currentUser =
                                        widget.firebaseService.currentUser;
                                    if (currentUser == null) {
                                      throw Exception('No user logged in');
                                    }

                                    // Reauthenticate user
                                    await widget.firebaseService
                                        .reauthenticateUser(
                                          currentUser.email!,
                                          _passwordController.text.trim(),
                                        );

                                    // Delete office boy account
                                    await widget.firebaseService
                                        .deleteUserAccount(widget.user.id);

                                    // Sign out and redirect to login
                                    await context.read<AuthCubit>().signOut();

                                    if (context.mounted) {
                                      Navigator.pop(context); // Close dialog
                                      context.go(Routes.login);

                                      showSuccessToast(
                                        context,
                                        widget.locale == 'ar'
                                            ? 'تم حذف الحساب بنجاح'
                                            : 'Account deleted successfully',
                                      );
                                    }
                                  } catch (e) {
                                    setState(() {
                                      _isDeleting = false;
                                    });

                                    showErrorToast(
                                      context,
                                      widget.locale == 'ar'
                                          ? 'فشل حذف الحساب: ${e.toString()}'
                                          : 'Failed to delete account: ${e.toString()}',
                                    );
                                  }
                                },
                          child: Center(
                            child: _isDeleting
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    widget.locale == 'ar'
                                        ? 'حذف نهائياً'
                                        : 'Delete Permanently',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
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
}

// Custom painter for animated particles background
class ParticlesPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;

  ParticlesPainter(this.animationValue, this.primaryColor, this.secondaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final progress = (animationValue + i * 0.1) % 1.0;
      final x =
          (i % 4) * size.width / 4 +
          math.sin(animationValue * 2 * math.pi + i) * 30;
      final y = size.height * progress;
      final opacity = math.sin(progress * math.pi) * 0.3;

      paint.color = (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(
        opacity,
      );

      final radius = 2 + math.sin(animationValue * 4 * math.pi + i) * 1;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw flowing waves
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final waveHeight = 20 + i * 10;
      final waveLength = size.width / 4;
      final waveOffset = animationValue * 2 * math.pi;

      wavePaint.color = (i % 2 == 0 ? primaryColor : secondaryColor)
          .withOpacity(0.1);

      path.moveTo(0, size.height * 0.3 + i * size.height * 0.2);

      for (double x = 0; x <= size.width; x += 5) {
        final y =
            size.height * 0.3 +
            i * size.height * 0.2 +
            math.sin((x / waveLength + waveOffset + i) * 2 * math.pi) *
                waveHeight;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, wavePaint);
    }

    // Draw gradient orbs
    for (int i = 0; i < 5; i++) {
      final centerX = (i + 0.5) * size.width / 5;
      final centerY =
          size.height * 0.5 +
          math.sin(animationValue * 2 * math.pi + i * 1.2) * 100;
      final radius = 40 + math.sin(animationValue * 3 * math.pi + i) * 20;

      final gradient = RadialGradient(
        colors: [
          (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(0.1),
          Colors.transparent,
        ],
      );

      final rect = Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius,
      );
      paint.shader = gradient.createShader(rect);
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
