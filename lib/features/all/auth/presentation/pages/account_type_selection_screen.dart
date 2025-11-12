import 'dart:math' as math;
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/translations/locale_keys.g.dart';
import 'package:taqy/features/all/auth/presentation/widgets/language_drop_down.dart';

class AccountTypeSelectionScreen extends StatefulWidget {
  const AccountTypeSelectionScreen({super.key});

  @override
  State<AccountTypeSelectionScreen> createState() =>
      _AccountTypeSelectionScreenState();
}

class _AccountTypeSelectionScreenState extends State<AccountTypeSelectionScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _staggerController;

  // Animations
  late Animation<double> _backgroundGradient;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  // Staggered animations for items
  late List<Animation<double>> _itemAnimations;

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
      duration: const Duration(milliseconds: 1200),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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

    // Staggered controller for items
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create staggered animations for each item
    _itemAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            index * 0.2,
            0.6 + (index * 0.2),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });
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
    _staggerController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Stack(
        children: [
          // Animated Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) => CustomPaint(
                painter: _AccountTypeBackgroundPainter(
                  _backgroundGradient.value,
                  _rotationAnimation.value,
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: AnimatedBuilder(
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            _buildHeaderSection(locale, context),

                            const SizedBox(height: 24),

                            // Account Types with enhanced animations
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Organization Admin
                                  _buildAnimatedAccountTypeItem(
                                    context: context,
                                    title: LocaleKeys.organizationAdmin.tr(),
                                    icon: Icons.admin_panel_settings_rounded,
                                    color: AppColors.primary,
                                    onTap: () =>
                                        _navigateToRegister(context, 'admin'),
                                    animation: _itemAnimations[0],
                                    index: 0,
                                  ),

                                  // Animated Curved Divider 1
                                  _buildAnimatedCurvedDivider(true, 0),

                                  // Employee
                                  _buildAnimatedAccountTypeItem(
                                    context: context,
                                    title: LocaleKeys.employee.tr(),
                                    icon: Icons.person_rounded,
                                    color: AppColors.secondary,
                                    onTap: () => _navigateToRegister(
                                      context,
                                      'employee',
                                    ),
                                    animation: _itemAnimations[1],
                                    index: 1,
                                    isReversed: true,
                                  ),

                                  // Animated Curved Divider 2
                                  _buildAnimatedCurvedDivider(false, 1),

                                  // Office Boy
                                  _buildAnimatedAccountTypeItem(
                                    context: context,
                                    title: LocaleKeys.officeBoy.tr(),
                                    icon: Icons.delivery_dining_rounded,
                                    color: Colors.teal,
                                    onTap: () => _navigateToRegister(
                                      context,
                                      'office_boy',
                                    ),
                                    animation: _itemAnimations[2],
                                    index: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
            ),

            // Language Dropdown
            _buildGlassLanguageDropdown(),
          ],
        ),
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
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: const CompactLanguageDropdown(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAccountTypeItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Animation<double> animation,
    required int index,
    bool isReversed = false,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset((isReversed ? -50 : 50) * (1 - animation.value), 0),
          child: Opacity(
            opacity: animation.value,
            child: Transform.scale(
              scale: animation.value,
              child: _buildGlassAccountTypeItem(
                context: context,
                title: title,
                icon: icon,
                color: color,
                onTap: onTap,
                isReversed: isReversed,
                index: index,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassAccountTypeItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isReversed,
    required int index,
  }) {
    final avatar = GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) => Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) => Transform.rotate(
                angle: _rotationAnimation.value * 0.1,
                child: Icon(icon, size: 40, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );

    final text = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(25),
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
          borderRadius: BorderRadius.circular(25),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: isReversed ? [text, avatar] : [avatar, text],
    );
  }

  Widget _buildAnimatedCurvedDivider(bool curveRight, int index) {
    return AnimatedBuilder(
      animation: _itemAnimations[index],
      builder: (context, child) => Opacity(
        opacity: _itemAnimations[index].value,
        child: SizedBox(
          height: 60,
          width: double.infinity,
          child: CustomPaint(
            painter: _AnimatedCurvedDividerPainter(
              color: Colors.white.withOpacity(0.3),
              curveRight: curveRight,
              animationValue: _backgroundGradient.value,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToRegister(BuildContext context, String accountType) {
    // Add a little scale animation when navigating
    // _scaleController.reverse().then((_) {
    if (mounted) {
      context.push(Routes.register, extra: accountType);
    }
    // });
  }
}

class _AccountTypeBackgroundPainter extends CustomPainter {
  final double animationValue;
  final double rotationValue;

  _AccountTypeBackgroundPainter(this.animationValue, this.rotationValue);

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
          (math.cos(animationValue * 2 * math.pi + i * 0.5) * 50);
      final radius = 1.5 + math.sin(animationValue * 2 * math.pi + i) * 1.5;

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
      ..strokeWidth = 2;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final startY = size.height * (0.1 + i * 0.15);

      path.moveTo(-50, startY);

      for (double x = -50; x <= size.width + 50; x += 6) {
        final y =
            startY +
            math.sin((x * 0.01) + (animationValue * 2 * math.pi) + (i * 1.5)) *
                30;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, linePaint);
    }

    // Additional decorative circles
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 3; i++) {
      final radius = 80 + i * 60;
      final centerX = size.width * 0.5;
      final centerY = size.height * 0.5;

      canvas.drawCircle(
        Offset(centerX, centerY),
        radius + math.sin(animationValue * 2 * math.pi + i) * 10,
        circlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AnimatedCurvedDividerPainter extends CustomPainter {
  final Color color;
  final bool curveRight;
  final double animationValue;

  _AnimatedCurvedDividerPainter({
    required this.color,
    required this.curveRight,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(
        0.5 + math.sin(animationValue * 2 * math.pi) * 0.3,
      )
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (curveRight) {
      // Start from left, curve to right with animation
      path.moveTo(size.width * 0.2, size.height * 0.2);
      path.quadraticBezierTo(
        size.width * 0.5,
        size.height * (0.8 + math.sin(animationValue * 2 * math.pi) * 0.1),
        size.width * 0.8,
        size.height * (0.4 + math.cos(animationValue * 2 * math.pi) * 0.1),
      );
    } else {
      // Start from right, curve to left with animation
      path.moveTo(size.width * 0.8, size.height * 0.2);
      path.quadraticBezierTo(
        size.width * 0.5,
        size.height * (0.8 + math.cos(animationValue * 2 * math.pi) * 0.1),
        size.width * 0.2,
        size.height * (0.4 + math.sin(animationValue * 2 * math.pi) * 0.1),
      );
    }

    canvas.drawPath(path, paint);

    // Add animated dots along the path
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      final length = pathMetric.length;
      final dotCount = 8;

      for (int i = 0; i < dotCount; i++) {
        final dotPosition = (i / dotCount) * length;
        final tangent = pathMetric.getTangentForOffset(dotPosition);
        if (tangent != null) {
          final dotOffset = tangent.position;
          final dotAlpha =
              0.3 + math.sin(animationValue * 2 * math.pi + i * 0.5) * 0.7;
          dotPaint.color = Colors.white.withOpacity(dotAlpha.clamp(0.0, 1.0));
          canvas.drawCircle(dotOffset, 2, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
