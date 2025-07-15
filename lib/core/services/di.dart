import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taqy/core/api/dio_client.dart';
import 'package:taqy/core/preferences/shared_pref.dart';
import 'package:taqy/features/all/auth/data/datasources/auth_remote_data_source.dart';
import 'package:taqy/features/all/auth/data/repositories/auth_repo.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/all/auth/presentation/cubit/user_cubit/user_cubit.dart';
import 'package:taqy/features/all/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:taqy/features/all/notifications/data/repositories/notifications_repo.dart';
import 'package:taqy/features/all/profile/data/datasources/cars_remote_data_source.dart';
import 'package:taqy/features/all/profile/data/datasources/profile_remote_data_source.dart';
import 'package:taqy/features/all/profile/data/repositories/cars_repo.dart';
import 'package:taqy/features/all/profile/data/repositories/profile_repo.dart';

final sl = GetIt.instance;
Future initLocator(SharedPreferences sharedPreferences) async {
  // Register SharedPreferences first
  sl.registerSingleton(sharedPreferences);

  // Register TaQyPreferences
  sl.registerLazySingleton(() => TaQyPreferences(sl()));

  // Register DioClient
  sl.registerLazySingleton(() => DioClient(sl()));

  // Register SupabaseClient
  sl.registerLazySingleton(() => Supabase.instance.client);

  //? Cubits
  sl.registerFactory(() => UserCubit());
  sl.registerLazySingleton(() => AuthCubit(sl()));

  //* Repository
  sl.registerLazySingleton(() => AuthRepository(sl())); // Now SupabaseClient is available
  sl.registerLazySingleton(() => NotificationsRepoImpl(sl(), sl()));
  sl.registerLazySingleton(() => PagesRepoImpl(sl(), sl()));
  sl.registerLazySingleton(() => CarRepoImpl(sl(), sl()));

  //* Datasources
  sl.registerLazySingleton(() => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton(() => NotificationsRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton(() => PagesRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton(() => CarRemoteDataSourceImpl(sl()));
}
