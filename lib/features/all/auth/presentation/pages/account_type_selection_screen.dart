// lib/features/auth/presentation/screens/account_type_selection_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/translations/locale_keys.g.dart';

class AccountTypeSelectionScreen extends StatefulWidget {
  const AccountTypeSelectionScreen({super.key});

  @override
  State<AccountTypeSelectionScreen> createState() =>
      _AccountTypeSelectionScreenState();
}

class _AccountTypeSelectionScreenState extends State<AccountTypeSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create staggered animations for each item
    _itemAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.2,
            0.6 + (index * 0.2),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Header
              Text(
                LocaleKeys.welcomeToTaQy.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                LocaleKeys.chooseAccountType.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Account Types
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Organization Admin
                    AnimatedBuilder(
                      animation: _itemAnimations[0],
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            50 * (1 - _itemAnimations[0].value),
                            0,
                          ),
                          child: Opacity(
                            opacity: _itemAnimations[0].value,
                            child: _buildAccountTypeItem(
                              context: context,
                              title: LocaleKeys.organizationAdmin.tr(),
                              icon: Icons.admin_panel_settings_outlined,
                              color: AppColors.primary,
                              onTap: () =>
                                  _navigateToRegister(context, 'admin'),
                            ),
                          ),
                        );
                      },
                    ),

                    // Curved Divider 1
                    _buildCurvedDivider(true),

                    // Employee
                    AnimatedBuilder(
                      animation: _itemAnimations[1],
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            -50 * (1 - _itemAnimations[1].value),
                            0,
                          ),
                          child: Opacity(
                            opacity: _itemAnimations[1].value,
                            child: _buildAccountTypeItem(
                              context: context,
                              title: LocaleKeys.employee.tr(),
                              icon: Icons.person_outline,
                              color: AppColors.secondary,
                              onTap: () =>
                                  _navigateToRegister(context, 'employee'),
                              isReversed: true,
                            ),
                          ),
                        );
                      },
                    ),

                    // Curved Divider 2
                    _buildCurvedDivider(false),

                    // Office Boy
                    AnimatedBuilder(
                      animation: _itemAnimations[2],
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            50 * (1 - _itemAnimations[2].value),
                            0,
                          ),
                          child: Opacity(
                            opacity: _itemAnimations[2].value,
                            child: _buildAccountTypeItem(
                              context: context,
                              title: LocaleKeys.officeBoy.tr(),
                              icon: Icons.delivery_dining_outlined,
                              color: Colors.teal,
                              onTap: () =>
                                  _navigateToRegister(context, 'office_boy'),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    LocaleKeys.alreadyHaveAccount.tr(),
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      LocaleKeys.signIn.tr(),
                      style: TextStyle(
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
      ),
    );
  }

  Widget _buildAccountTypeItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isReversed = false,
  }) {
    final avatar = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Icon(icon, size: 40, color: color),
      ),
    );

    final text = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: isReversed ? [text, avatar] : [avatar, text],
    );
  }

  Widget _buildCurvedDivider(bool curveRight) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: CustomPaint(
        painter: CurvedDividerPainter(
          color: AppColors.onSurfaceVariant.withOpacity(0.2),
          curveRight: curveRight,
        ),
      ),
    );
  }

  void _navigateToRegister(BuildContext context, String accountType) {
    context.push(Routes.register, extra: accountType);
  }
}

class CurvedDividerPainter extends CustomPainter {
  final Color color;
  final bool curveRight;

  CurvedDividerPainter({required this.color, required this.curveRight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (curveRight) {
      // Start from left, curve to right
      path.moveTo(size.width * 0.2, size.height * 0.2);
      path.quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.8,
        size.width * 0.8,
        size.height * 0.4,
      );
    } else {
      // Start from right, curve to left
      path.moveTo(size.width * 0.8, size.height * 0.2);
      path.quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.8,
        size.width * 0.2,
        size.height * 0.4,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
