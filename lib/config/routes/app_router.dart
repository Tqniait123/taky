// Import necessary packages and files
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/extensions/num_extension.dart';
import 'package:taqy/core/extensions/widget_extensions.dart';
import 'package:taqy/core/observers/router_observer.dart';
import 'package:taqy/core/services/di.dart';
import 'package:taqy/core/utils/widgets/buttons/custom_back_button.dart';
import 'package:taqy/features/all/auth/presentation/pages/account_type_selection_screen.dart';
import 'package:taqy/features/all/auth/presentation/pages/check_your_email_screen.dart';
import 'package:taqy/features/all/auth/presentation/pages/login_screen.dart';
import 'package:taqy/features/all/auth/presentation/pages/register_screen.dart';
import 'package:taqy/features/all/layout/presentation/pages/admin_layout.dart';
import 'package:taqy/features/all/layout/presentation/pages/employee_layout.dart';
import 'package:taqy/features/all/layout/presentation/pages/office_boy_layout.dart';
import 'package:taqy/features/all/notifications/presentation/pages/notifications_screen.dart';
import 'package:taqy/features/all/on_boarding/presentation/pages/on_boarding_screen.dart';
import 'package:taqy/features/all/profile/presentation/cubit/profile_cubit.dart';
import 'package:taqy/features/all/profile/presentation/pages/edit_profile_screen.dart';
import 'package:taqy/features/all/profile/presentation/pages/faq_screen.dart';
import 'package:taqy/features/all/profile/presentation/pages/profile_screen.dart';
import 'package:taqy/features/all/splash/presentation/pages/splash.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// Define the AppRouter class
class AppRouter {
  // Create a GoRouter instance
  final GoRouter router = GoRouter(
    initialLocation: Routes.initialRoute,
    navigatorKey: rootNavigatorKey,
    errorPageBuilder: (context, state) {
      return CustomTransitionPage(
        transitionDuration: const Duration(milliseconds: 200),
        key: state.pageKey,
        child: _unFoundRoute(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    },
    observers: [
      GoRouterObserver(), // Specify your observer here
    ],
    routes: [
      // Define routes using GoRoute
      GoRoute(
        path: Routes.initialRoute,
        builder: (context, state) {
          // Return the SplashScreen widget
          return const SplashScreen();
        },
      ),

      GoRoute(
        path: Routes.onBoarding1,
        builder: (context, state) {
          // Return the SplashScreen widget
          return const OnBoardingScreen();
        },
      ),

      GoRoute(
        path: Routes.login,
        builder: (context, state) {
          // Return the SplashScreen widget
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: Routes.accountTypeSelection,
        builder: (context, state) {
          // Return the AccountTypeSelectionsScreen widget
          return const AccountTypeSelectionScreen();
        },
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) {
          // Return the RegisterScreen widget
          return RegisterScreen(accountType: state.extra as String);
        },
      ),
      // GoRoute(
      //   path: Routes.forgetPassword,
      //   builder: (context, state) {
      //     // Return the ForgetPasswordScreen widget
      //     return const ForgetPasswordScreen();
      //   },
      // ),
      // GoRoute(
      //   path: Routes.otpScreen,
      //   builder: (context, state) {
      //     final extras = state.extra as Map<String, dynamic>;
      //     return OtpScreen(phone: extras['phone'] as String, flow: extras['flow'] as OtpFlow);
      //   },
      // ),
      // GoRoute(
      //   path: Routes.resetPassword,
      //   builder: (context, state) {
      //     // Return the OtpScreen widget
      //     return ResetPasswordScreen(phone: state.extra as String);
      //   },
      // ),

      // GoRoute(
      //   path: Routes.homeUser,
      //   builder: (context, state) {
      //     // Return the HomeUser widget
      //     return const HomeUser();
      //   },
      // ),
      // GoRoute(
      //   path: Routes.registerStepTwo,
      //   builder: (context, state) {
      //     // Return the RegisterStepTwoScreen widget
      //     return const RegisterStepTwoScreen();
      //   },
      // ),
      // GoRoute(
      //   path: Routes.registerStepThree,
      //   builder: (context, state) {
      //     // Return the RegisterStepThreeScreen widget
      //     return const RegisterStepThreeScreen();
      //   },
      // ),
      GoRoute(
        path: Routes.checkYourEmail,
        builder: (context, state) {
          // Return the CheckYourEmailScreen widget
          return CheckYourEmailScreen(email: state.extra as String);
        },
      ),

      GoRoute(
        path: Routes.notifications,
        builder: (context, state) {
          // Return the Routing widget
          return NotificationsScreen();
        },
      ),

      GoRoute(
        path: Routes.profile,
        builder: (context, state) {
          // Return the ProfileScreen widget
          return ProfileScreen();
        },
      ),
      GoRoute(
        path: Routes.editProfile,
        builder: (context, state) {
          // Return the EditProfileScreen widget
          return EditProfileScreen();
        },
      ),
      GoRoute(
        path: Routes.layoutAdmin,
        builder: (context, state) {
          // Return the AdminLayout widget
          return AdminLayout();
        },
      ),
      GoRoute(
        path: Routes.layoutEmployee,
        builder: (context, state) {
          // Return the EmployeeLayout widget
          return EmployeeLayout();
        },
      ),
      GoRoute(
        path: Routes.layoutOfficeBoy,
        builder: (context, state) {
          // Return the OfficeBoyLayout widget
          return OfficeBoyLayout();
        },
      ),

      // GoRoute(
      //   path: Routes.myCars,
      //   builder: (context, state) {
      //     // Return the MyCarsScreen widget
      //     return BlocProvider(create: (BuildContext context) => CarCubit(sl()), child: MyCarsScreen());
      //   },
      // ),
      GoRoute(
        path: Routes.faq,
        builder: (context, state) {
          // Return the FAQscreen widget
          return BlocProvider(create: (BuildContext context) => PagesCubit(sl()), child: FAQScreen());
        },
      ),
      // GoRoute(
      //   path: Routes.termsAndConditions,
      //   builder: (context, state) {
      //     // Return the TermsAnsConditionsScreen widget
      //     return BlocProvider(create: (BuildContext context) => PagesCubit(sl()), child: TermsAndConditionsScreen());
      //   },
      // ),
      // GoRoute(
      //   path: Routes.privacyPolicy,
      //   builder: (context, state) {
      //     // Return the TermsAnsConditionsScreen widget
      //     return BlocProvider(create: (BuildContext context) => PagesCubit(sl()), child: PrivacyPolicyScreen());
      //   },
      // ),
      // GoRoute(
      //   path: Routes.contactUs,
      //   builder: (context, state) {
      //     // Return the TermsAnsConditionsScreen widget
      //     return BlocProvider(create: (BuildContext context) => PagesCubit(sl()), child: ContactUsScreen());
      //   },
      // ),
      // GoRoute(
      //   path: Routes.aboutUs,
      //   builder: (context, state) {
      //     // Return the AboutUsScreen widget
      //     return BlocProvider(create: (BuildContext context) => PagesCubit(sl()), child: AboutUsScreen());
      //   },
      // ),
    ],
  );

  // Define a static method for the "Un Found Route" page
  static Widget _unFoundRoute(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomBackButton(),
            100.gap,
            Center(
              child: Text("Un Found Route", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ).paddingHorizontal(24),
    );
  }

  @override
  List<Object?> get props => [router];
}
