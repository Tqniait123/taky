// lib/core/services/di.dart
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taqy/config/supabase_config.dart';
import 'package:taqy/core/api/dio_client.dart';
import 'package:taqy/core/preferences/shared_pref.dart';
import 'package:taqy/features/all/auth/data/datasources/auth_remote_data_source.dart';
import 'package:taqy/features/all/auth/data/repositories/auth_repo.dart';
import 'package:taqy/features/all/auth/domain/usecases/auth_usecase.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/all/auth/presentation/cubit/user_cubit/user_cubit.dart';

final sl = GetIt.instance;

Future<void> initLocator(SharedPreferences sharedPreferences) async {
  try {
    // Register SharedPreferences first
    sl.registerSingleton<SharedPreferences>(sharedPreferences);

    // Register TaQyPreferences
    sl.registerLazySingleton<TaQyPreferences>(() => TaQyPreferences(sl()));

    // Register DioClient
    sl.registerLazySingleton<DioClient>(() => DioClient(sl()));

    // Register SupabaseClient (Supabase should already be initialized at this point)
    // Use the SupabaseConfig.client getter for consistency
    sl.registerLazySingleton<SupabaseClient>(() => SupabaseConfig.client);

    // Data Sources
    sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));
    // sl.registerLazySingleton<NotificationsRemoteDataSource>(
    //   () => NotificationsRemoteDataSourceImpl(sl<SupabaseClient>()),
    // );
    // sl.registerLazySingleton<ProfileRemoteDataSource>(
    //   () => PagesRemoteDataSourceImpl(sl<SupabaseClient>()),
    // );

    // Repositories
    sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl<SupabaseClient>()));
    // sl.registerLazySingleton<NotificationsRepository>(
    //   () => NotificationsRepoImpl(sl<NotificationsRemoteDataSource>(), sl<TaQyPreferences>()),
    // );
    // sl.registerLazySingleton<ProfileRepository>(
    //   () => PagesRepoImpl(sl<ProfileRemoteDataSource>(), sl<TaQyPreferences>()),
    // );

    // Use Cases
    sl.registerLazySingleton<SignUpUseCase>(() => SignUpUseCase(sl<AuthRepository>()));
    sl.registerLazySingleton<SignInUseCase>(() => SignInUseCase(sl<AuthRepository>()));
    sl.registerLazySingleton<SignOutUseCase>(() => SignOutUseCase(sl<AuthRepository>()));
    sl.registerLazySingleton<ResetPasswordUseCase>(() => ResetPasswordUseCase(sl<AuthRepository>()));
    sl.registerLazySingleton<CheckOrganizationCodeUseCase>(() => CheckOrganizationCodeUseCase(sl<AuthRepository>()));
    sl.registerLazySingleton<GetCurrentUserUseCase>(() => GetCurrentUserUseCase(sl<AuthRepository>()));
    sl.registerLazySingleton<GetAuthStateChangesUseCase>(() => GetAuthStateChangesUseCase(sl<AuthRepository>()));

    // Cubits
    sl.registerFactory<AuthCubit>(
      () => AuthCubit(
        signUpUseCase: sl<SignUpUseCase>(),
        signInUseCase: sl<SignInUseCase>(),
        signOutUseCase: sl<SignOutUseCase>(),
        resetPasswordUseCase: sl<ResetPasswordUseCase>(),
        checkOrganizationCodeUseCase: sl<CheckOrganizationCodeUseCase>(),
        getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
        getAuthStateChangesUseCase: sl<GetAuthStateChangesUseCase>(),
        authRepository: sl<AuthRepository>(),
      ),
    );

    sl.registerFactory<UserCubit>(() => UserCubit());

    print('✅ Dependency injection initialized successfully');
  } catch (e) {
    print('❌ Error initializing dependency injection: $e');
    rethrow;
  }
}
