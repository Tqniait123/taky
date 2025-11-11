import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taqy/core/preferences/shared_pref.dart';
import 'package:taqy/core/services/di.dart';
import 'package:taqy/core/static/locales.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/main.dart';

class LanguageLayoutDropdown extends StatefulWidget {
  final Color? primaryColor;
  final Color? secondaryColor;

  const LanguageLayoutDropdown({
    super.key,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<LanguageLayoutDropdown> createState() => _LanguageLayoutDropdownState();
}

class _LanguageLayoutDropdownState extends State<LanguageLayoutDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  Color get primaryColor => widget.primaryColor ?? AppColors.primary;
  Color get secondaryColor => widget.secondaryColor ?? AppColors.secondary;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _changeLanguage(Locale newLocale) async {
    try {
      await sl<TaQyPreferences>().saveLang(newLocale.languageCode);
      final navContext = navigatorKey.currentContext;

      if (navContext != null && navContext.mounted) {
        await navContext.setLocale(newLocale);
      }
    } catch (e) {
      debugPrint('Error changing language: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;
    final isArabic = currentLocale.languageCode == 'ar';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(
                  _isHovered ? 0.3 + (_glowAnimation.value * 0.2) : 0.1,
                ),
                blurRadius: _isHovered ? 15 + (_glowAnimation.value * 5) : 10,
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(_isHovered ? 0.25 : 0.15),
                      Colors.white.withOpacity(_isHovered ? 0.15 : 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(_isHovered ? 0.3 : 0.2),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    splashColor: primaryColor.withOpacity(0.3),
                    highlightColor: primaryColor.withOpacity(0.1),
                    onTap: () {
                      // Trigger popup menu
                      final RenderBox button =
                          context.findRenderObject() as RenderBox;
                      final RenderBox overlay =
                          Overlay.of(context).context.findRenderObject()
                              as RenderBox;
                      final RelativeRect position = RelativeRect.fromRect(
                        Rect.fromPoints(
                          button.localToGlobal(Offset.zero, ancestor: overlay),
                          button.localToGlobal(
                            button.size.bottomRight(Offset.zero),
                            ancestor: overlay,
                          ),
                        ),
                        Offset.zero & overlay.size,
                      );

                      showMenu<Locale>(
                        context: context,
                        position: position,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.transparent,
                        elevation: 0,
                        items: [
                          _buildGlassMenuItem(
                            locale: Locales.english,
                            flag: '🇬🇧',
                            name: 'English',
                            isSelected: currentLocale.languageCode == 'en',
                          ),
                          _buildGlassMenuItem(
                            locale: Locales.arabic,
                            flag: '🇸🇦',
                            name: 'العربية',
                            isSelected: currentLocale.languageCode == 'ar',
                          ),
                        ],
                      ).then((Locale? newLocale) {
                        if (newLocale != null &&
                            newLocale.languageCode !=
                                currentLocale.languageCode) {
                          _changeLanguage(newLocale);
                        }
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArabic ? '🇸🇦' : '🇬🇧',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isArabic ? 'العربية' : 'English',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<Locale> _buildGlassMenuItem({
    required Locale locale,
    required String flag,
    required String name,
    required bool isSelected,
  }) {
    return PopupMenuItem(
      value: locale,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                splashColor: primaryColor.withOpacity(0.3),
                highlightColor: primaryColor.withOpacity(0.1),
                onTap: () => Navigator.pop(context, locale),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(isSelected ? 0.3 : 0.15),
                        Colors.white.withOpacity(isSelected ? 0.2 : 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor.withOpacity(0.5)
                          : Colors.white.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(
                        name,
                        style: TextStyle(
                          color: isSelected ? primaryColor : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        SvgPicture.asset(
                          Assets.imagesSvgsComplete,
                          height: 18,
                          color: primaryColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Compact version for smaller spaces
class CompactGlassLanguageDropdown extends StatefulWidget {
  final Color? primaryColor;
  final Color? secondaryColor;

  const CompactGlassLanguageDropdown({
    super.key,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<CompactGlassLanguageDropdown> createState() =>
      _CompactGlassLanguageDropdownState();
}

class _CompactGlassLanguageDropdownState
    extends State<CompactGlassLanguageDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  Color get primaryColor => widget.primaryColor ?? AppColors.primary;
  Color get secondaryColor => widget.secondaryColor ?? AppColors.secondary;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _changeLanguage(Locale newLocale) async {
    try {
      await sl<TaQyPreferences>().saveLang(newLocale.languageCode);
      final navContext = navigatorKey.currentContext;

      if (navContext != null && navContext.mounted) {
        await navContext.setLocale(newLocale);
      }
    } catch (e) {
      debugPrint('Error changing language: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;
    final isArabic = currentLocale.languageCode == 'ar';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(
                  _isHovered ? 0.2 + (_glowAnimation.value * 0.15) : 0.05,
                ),
                blurRadius: _isHovered ? 12 + (_glowAnimation.value * 3) : 8,
                spreadRadius: _isHovered ? 1 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(_isHovered ? 0.25 : 0.15),
                      Colors.white.withOpacity(_isHovered ? 0.15 : 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(_isHovered ? 0.3 : 0.2),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    splashColor: primaryColor.withOpacity(0.3),
                    highlightColor: primaryColor.withOpacity(0.1),
                    onTap: () {
                      final RenderBox button =
                          context.findRenderObject() as RenderBox;
                      final RenderBox overlay =
                          Overlay.of(context).context.findRenderObject()
                              as RenderBox;
                      final RelativeRect position = RelativeRect.fromRect(
                        Rect.fromPoints(
                          button.localToGlobal(Offset.zero, ancestor: overlay),
                          button.localToGlobal(
                            button.size.bottomRight(Offset.zero),
                            ancestor: overlay,
                          ),
                        ),
                        Offset.zero & overlay.size,
                      );

                      showMenu<Locale>(
                        context: context,
                        position: position,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.transparent,
                        elevation: 0,
                        items: [
                          _buildGlassMenuItem(
                            locale: Locales.english,
                            flag: '🇬🇧',
                            name: 'English',
                            isSelected: currentLocale.languageCode == 'en',
                          ),
                          _buildGlassMenuItem(
                            locale: Locales.arabic,
                            flag: '🇸🇦',
                            name: 'العربية',
                            isSelected: currentLocale.languageCode == 'ar',
                          ),
                        ],
                      ).then((Locale? newLocale) {
                        if (newLocale != null &&
                            newLocale.languageCode !=
                                currentLocale.languageCode) {
                          _changeLanguage(newLocale);
                        }
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArabic ? '🇸🇦' : '🇬🇧',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<Locale> _buildGlassMenuItem({
    required Locale locale,
    required String flag,
    required String name,
    required bool isSelected,
  }) {
    return PopupMenuItem(
      value: locale,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              splashColor: primaryColor.withOpacity(0.3),
              highlightColor: primaryColor.withOpacity(0.1),
              onTap: () => Navigator.pop(context, locale),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(isSelected ? 0.3 : 0.15),
                      Colors.white.withOpacity(isSelected ? 0.2 : 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor.withOpacity(0.5)
                        : Colors.white.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(
                      name,
                      style: TextStyle(
                        color: isSelected ? primaryColor : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      Icon(
                        Icons.check_circle_rounded,
                        color: primaryColor,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
