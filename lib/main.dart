// lib/main.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taqy/app.dart';
import 'package:taqy/config/supabase_config.dart';
import 'package:taqy/core/observers/bloc_observer.dart';
import 'package:taqy/core/services/di.dart';
import 'package:taqy/core/static/locales.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/translations/codegen_loader.g.dart';
import 'package:taqy/firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// @pragma('vm:entry-point')
// Future<void> fcmBackgroundHandler(RemoteMessage message) async {
//   // Initialize Firebase in the background isolate
//   // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   // Check if the service is already registered
//   if (!sl.isRegistered<FcmService>()) {
//     // Initialize the dependency injection only if not already registered
//     await initLocator();
//   }
//   // FirebaseMessaging.instance
//   //     .getInitialMessage()
//   //     .then((RemoteMessage? message) {
//   //   if (message != null) {

//   //     Navigator.of(context).pushNamed('/call');
//   //   }
//   // });

//   log('Message received in background: ${message.toMap()}', name: 'FcmService');
//   log('Notification: ${message.notification?.toMap()}', name: 'FcmService');
//   log('Data: ${message.data}', name: 'FcmService');
//   if (Platform.isAndroid) {
//     sl<FcmService>().showNotification(message);
//   }
//   // Use FcmService to show the notification

//   // sl<FcmService>().showNotification(message);
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // 1. Initialize Supabase FIRST
  await SupabaseConfig.initialize();

  // 2. Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // 3. Initialize the dependency injection container AFTER Supabase
  await initLocator(sharedPreferences);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FCM
  // FcmService fcmService = FcmService(preferences: sl());
  // await fcmService.initNotifications();
  // FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

  await ColorManager().initialize();

  Bloc.observer = MyBlocObserver();

  // Set status bar color globally
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Change to your primary color
      statusBarIconBrightness:
          Brightness.light, // Light icons for dark background
    ),
  );

  // Get the language code from TaQyPreferences
  // final codeLang = sl<TaQyPreferences>().getLang();
  runApp(
    EasyLocalization(
      path: 'assets/translations',
      supportedLocales: const [
        // Locales.arabic,
        Locales.english,
        // Locales.french,
        // Locales.dutch,
      ],
      startLocale: Locales.english,
      fallbackLocale: Locales.english,
      useOnlyLangCode: true,
      assetLoader: const CodegenLoader(),
      child: TaQy(),
    ),
  );
}
