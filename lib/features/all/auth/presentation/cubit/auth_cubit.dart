// lib/features/all/auth/presentation/cubit/auth_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:taqy/core/errors/failures.dart';
import 'package:taqy/features/all/auth/data/repositories/auth_repo.dart';
import 'package:taqy/features/all/auth/domain/entities/user.dart' as entities;
import 'package:taqy/features/all/auth/domain/entities/user.dart';
import 'package:taqy/features/all/auth/domain/usecases/auth_usecase.dart';

part 'auth_cubit.freezed.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignUpUseCase _signUpUseCase;
  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final CheckOrganizationCodeUseCase _checkOrganizationCodeUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final GetAuthStateChangesUseCase _getAuthStateChangesUseCase;
  final AuthRepository _authRepository;

  AuthCubit({
    required SignUpUseCase signUpUseCase,
    required SignInUseCase signInUseCase,
    required SignOutUseCase signOutUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required CheckOrganizationCodeUseCase checkOrganizationCodeUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required GetAuthStateChangesUseCase getAuthStateChangesUseCase,
    required AuthRepository authRepository,
  }) : _signUpUseCase = signUpUseCase,
       _signInUseCase = signInUseCase,
       _signOutUseCase = signOutUseCase,
       _resetPasswordUseCase = resetPasswordUseCase,
       _checkOrganizationCodeUseCase = checkOrganizationCodeUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _getAuthStateChangesUseCase = getAuthStateChangesUseCase,
       _authRepository = authRepository,
       super(const AuthState.initial());

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required entities.UserRole role,
    String? phone,
    XFile? profileImage,
    String? organizationName,
    String? organizationCode,
    XFile? organizationLogo,
    String? primaryColor,
    String? secondaryColor,
  }) async {
    emit(const AuthState.loading());

    try {
      // Upload profile image if provided
      String? profileImageUrl;
      if (profileImage != null) {
        final uploadResult = await _authRepository.uploadProfileImage(profileImage.path);
        uploadResult.fold((failure) => emit(AuthState.error(failure)), (url) => profileImageUrl = url);
        if (profileImageUrl == null) return;
      }

      // Upload organization logo if admin and logo provided
      String? orgLogoUrl;
      if (role == entities.UserRole.admin && organizationLogo != null) {
        final uploadResult = await _authRepository.uploadOrganizationLogo(organizationLogo.path);
        uploadResult.fold((failure) => emit(AuthState.error(failure)), (url) => orgLogoUrl = url);
        if (orgLogoUrl == null) return;
      }

      // For employee/office boy, check if organization exists
      if (role != entities.UserRole.admin && organizationCode != null) {
        final checkResult = await _checkOrganizationCodeUseCase(organizationCode);
        checkResult.fold((failure) => emit(AuthState.error(failure)), (exists) {
          if (!exists) {
            emit(const AuthState.error(DatabaseFailure('Organization code not found')));
            return;
          }
        });
        if (state is AuthError) return;
      }

      // Register user
      final result = await _signUpUseCase(
        SignUpParams(
          email: email,
          password: password,
          name: name,
          role: role,
          phone: phone,
          profileImageUrl: profileImageUrl,
          organizationName: organizationName,
          organizationCode: organizationCode,
          organizationLogo: orgLogoUrl,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
        ),
      );

      result.fold((failure) => emit(AuthState.error(failure)), (user) => emit(AuthState.authenticated(user)));
    } catch (e) {
      emit(AuthState.error(GeneralFailure(e.toString())));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthState.loading());

    final result = await _signInUseCase(SignInParams(email: email, password: password));

    result.fold((failure) => emit(AuthState.error(failure)), (user) => emit(AuthState.authenticated(user)));
  }

  Future<void> signOut() async {
    emit(const AuthState.loading());

    final result = await _signOutUseCase();

    result.fold((failure) => emit(AuthState.error(failure)), (_) => emit(const AuthState.unauthenticated()));
  }

  Future<void> resetPassword(String email) async {
    emit(const AuthState.loading());

    final result = await _resetPasswordUseCase(email);

    result.fold((failure) => emit(AuthState.error(failure)), (_) => emit(const AuthState.passwordResetSent()));
  }

  Future<void> checkOrganizationCode(String code) async {
    emit(const AuthState.checkingOrganizationCode());

    final result = await _checkOrganizationCodeUseCase(code);

    result.fold(
      (failure) => emit(AuthState.error(failure)),
      (exists) => emit(AuthState.organizationCodeChecked(exists)),
    );
  }

  void initializeAuthStream() {
    _getAuthStateChangesUseCase().listen((user) {
      if (user == null) {
        emit(const AuthState.unauthenticated());
      } else {
        emit(AuthState.authenticated(user));
      }
    });
  }

  entities.User? get currentUser => _getCurrentUserUseCase();
}
