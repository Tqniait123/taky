// Language Dropdown - Simplified without loading state
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:taqy/core/preferences/shared_pref.dart';
import 'package:taqy/core/services/di.dart';
import 'package:taqy/core/static/locales.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/main.dart';

class CompactLanguageDropdown extends StatelessWidget {
  const CompactLanguageDropdown({super.key});

  void _changeLanguage(Locale newLocale) async {
    try {
      // Save preference
      await sl<TaQyPreferences>().saveLang(newLocale.languageCode);

      // Use the global navigator key to get a stable context
      final navContext = navigatorKey.currentContext;

      if (navContext != null && navContext.mounted) {
        // Change locale using the navigator context
        await navContext.setLocale(newLocale);
      }
    } catch (e) {
      debugPrint('Error changing language: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;

    return PopupMenuButton<Locale>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentLocale.languageCode == 'en' ? '🇬🇧' : '🇸🇦',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
        ],
      ),
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: Locales.english,
          child: _LanguageItem(
            flag: '🇬🇧',
            name: 'English',
            isSelected: currentLocale.languageCode == 'en',
          ),
        ),
        PopupMenuItem(
          value: Locales.arabic,
          child: _LanguageItem(
            flag: '🇸🇦',
            name: 'العربية',
            isSelected: currentLocale.languageCode == 'ar',
          ),
        ),
      ],
      onSelected: (Locale newLocale) {
        if (newLocale.languageCode != currentLocale.languageCode) {
          _changeLanguage(newLocale);
        }
      },
    );
  }
}

class _LanguageItem extends StatelessWidget {
  final String flag;
  final String name;
  final bool isSelected;

  const _LanguageItem({
    required this.flag,
    required this.name,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(flag, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          name,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// Full LanguageDropdown version
class LanguageDropdown extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets? padding;

  const LanguageDropdown({super.key, this.showLabel = true, this.padding});

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

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            Icon(Icons.language, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Language',
              style: TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
          ],
          DropdownButton<Locale>(
            value: currentLocale,
            underline: const SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
            dropdownColor: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            items: [
              DropdownMenuItem(
                value: Locales.english,
                child: _LanguageItem(
                  flag: '🇬🇧',
                  name: 'English',
                  isSelected: currentLocale.languageCode == 'en',
                ),
              ),
              DropdownMenuItem(
                value: Locales.arabic,
                child: _LanguageItem(
                  flag: '🇸🇦',
                  name: 'العربية',
                  isSelected: currentLocale.languageCode == 'ar',
                ),
              ),
            ],
            onChanged: (Locale? newLocale) {
              if (newLocale != null &&
                  newLocale.languageCode != currentLocale.languageCode) {
                _changeLanguage(newLocale);
              }
            },
          ),
        ],
      ),
    );
  }
}
