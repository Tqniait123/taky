import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taqy/core/static/constants.dart';
import 'package:taqy/core/theme/colors.dart';

ThemeData lightTheme(BuildContext context) {
  return ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    primaryColorLight: AppColors.primaryLight,
    primaryColorDark: AppColors.primaryDark,
    //this may be changed in the future
    // useMaterial3: false,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: context.locale.languageCode == "en" ? Constants.fontFamilyEN : Constants.fontFamilyAR,
    colorScheme:  ColorScheme.light(primary: AppColors.primary),

    dividerColor: AppColors.outline,
    dividerTheme: const DividerThemeData(color: AppColors.outline, thickness: 0.1),

    //! AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0.0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.success),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
      ),
    ),

    //! Bottom Navigation Bar Theme
    bottomNavigationBarTheme:  BottomNavigationBarThemeData(
      elevation: 4.0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedIconTheme: IconThemeData(color: AppColors.primary),
      unselectedIconTheme: IconThemeData(color: AppColors.outline),
      selectedLabelStyle: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w400),
      unselectedLabelStyle: TextStyle(fontSize: 12, color: AppColors.outline, fontWeight: FontWeight.w400),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.outline,
      enableFeedback: false,
      landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
    ),

    //! Buttons Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.background, fontSize: 16),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        elevation: 0.0,
        alignment: Alignment.center,
        enableFeedback: false,
        padding: const EdgeInsets.symmetric(vertical: 19),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        elevation: 0.0,
        alignment: Alignment.center,
        enableFeedback: false,
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap, enableFeedback: true, iconSize: 20),
    ),

    checkboxTheme: CheckboxThemeData(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      checkColor: WidgetStateProperty.all(AppColors.primary),
      fillColor: WidgetStateProperty.all(AppColors.primary.withOpacity(0.2)),
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
    ),

    dropdownMenuTheme: const DropdownMenuThemeData(),

    //! Text Theme
    textTheme: textTheme(),
  );
}

TextTheme textTheme() {
  return TextTheme(
    //! BODY
    // bodyLarge: TextStyle(
    //   fontSize: 35.sp,
    //   fontStyle: FontStyle.normal,
    //   fontWeight: FontWeight.w900,
    //   color: AppColors.onSurface,
    // ),
    bodyLarge: TextStyle(
      fontSize: 16.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
    ),
    bodyMedium: TextStyle(
      fontSize: 16.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
    ),
    bodySmall: TextStyle(
      fontSize: 14.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400,
      color: AppColors.onSurface,
    ),
    //! DISPLAY
    displayLarge: TextStyle(
      fontSize: 20.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
    ),
    displayMedium: TextStyle(
      fontSize: 16.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
    ),
    displaySmall: TextStyle(
      fontSize: 14.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400,
      color: AppColors.onSurface,
    ),
    //! HEADLINE
    headlineLarge: TextStyle(
      fontSize: 36.sp,
      // fontSize: 20.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.bold,
      color: AppColors.onSurface,
    ),
    headlineMedium: TextStyle(
      fontSize: 16.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
    ),
    headlineSmall: TextStyle(
      fontSize: 14.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400,
      color: AppColors.onSurface,
    ),
    //! LABEL
    labelLarge: TextStyle(
      fontSize: 16.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w500,
      color: AppColors.primary,
    ),
    labelMedium: TextStyle(
      fontSize: 14.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400,
      color: AppColors.primary,
    ),
    labelSmall: TextStyle(
      fontSize: 12.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w300,
      color: AppColors.primary,
    ),
    titleLarge: TextStyle(
      fontSize: 20.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
    ),

    titleMedium: TextStyle(
      fontSize: 16.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
    ),
    titleSmall: TextStyle(
      fontSize: 14.sp,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400,
      color: AppColors.outline,
    ),
  );
}
