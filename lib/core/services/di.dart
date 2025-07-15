import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

Future<void> initLocator(SharedPreferences sharedPreferences) async {
  // Register SharedPreferences first
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  // Register TaQyPreferences
  sl.registerLazySingleton(() => TaQyPreferences(sl()));

  // Register DioClient
  sl.registerLazySingleton(() => DioClient(sl()));

  //? Cubits
  sl.registerFactory<UserCubit>(() => UserCubit());
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl()));

  //* Repository
  sl.registerLazySingleton<AuthRepo>(() => AuthRepoImpl(sl(), sl()));
  sl.registerLazySingleton<NotificationsRepo>(() => NotificationsRepoImpl(sl(), sl()));
  sl.registerLazySingleton<PagesRepo>(() => PagesRepoImpl(sl(), sl()));
  sl.registerLazySingleton<CarRepo>(() => CarRepoImpl(sl(), sl()));

  //* Datasources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<NotificationsRemoteDataSource>(() => NotificationsRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<PagesRemoteDataSource>(() => PagesRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<CarRemoteDataSource>(() => CarRemoteDataSourceImpl(sl()));
}
