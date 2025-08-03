import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
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

  StreamSubscription<entities.User?>? _authSubscription;

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
       super(const AuthState.initial()) {
    initializeAuthStream();
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

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
    bool skipImageUpload = true,
  }) async {
    if (isClosed) return;
    emit(const AuthState.loading());

    try {
      String? profileImageUrl;
      String? orgLogoUrl;

      if (!skipImageUpload) {
        if (profileImage != null) {
          final uploadResult = await _authRepository.uploadProfileImage(profileImage.path);
          final result = uploadResult.fold((failure) {
            if (!isClosed) emit(AuthState.error(failure));
            return null;
          }, (url) => url);

          if (result == null) return;
          profileImageUrl = result;
        }

        if (role == entities.UserRole.admin && organizationLogo != null) {
          final uploadResult = await _authRepository.uploadOrganizationLogo(organizationLogo.path);
          final result = uploadResult.fold((failure) {
            if (!isClosed) emit(AuthState.error(failure));
            return null;
          }, (url) => url);

          if (result == null) return;
          orgLogoUrl = result;
        }
      } else {
        profileImageUrl = profileImage != null ? 'https://via.placeholder.com/150' : null;
        orgLogoUrl = organizationLogo != null ? 'https://via.placeholder.com/300' : null;
      }

      if (role != entities.UserRole.admin && organizationCode != null) {
        final checkResult = await _checkOrganizationCodeUseCase(organizationCode);
        checkResult.fold(
          (failure) {
            if (!isClosed) emit(AuthState.error(failure));
          },
          (exists) {
            if (!exists && !isClosed) {
              emit(const AuthState.error(DatabaseFailure('Organization code not found')));
            }
          },
        );
        if (state is AuthError) return;
      }

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

      if (!isClosed) {
        result.fold((failure) => emit(AuthState.error(failure)), (user) => emit(AuthState.authenticated(user)));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthState.error(GeneralFailure('Registration failed: ${e.toString()}')));
      }
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    if (isClosed) return;
    emit(const AuthState.loading());

    try {
      final result = await _signInUseCase(SignInParams(email: email, password: password));

      if (!isClosed) {
        result.fold((failure) => emit(AuthState.error(failure)), (user) => emit(AuthState.authenticated(user)));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthState.error(GeneralFailure('Sign in failed: ${e.toString()}')));
      }
    }
  }

  Future<void> signOut() async {
    if (isClosed) return;
    emit(const AuthState.loading());

    try {
      final result = await _signOutUseCase();

      if (!isClosed) {
        result.fold((failure) => emit(AuthState.error(failure)), (_) => emit(const AuthState.unauthenticated()));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthState.error(GeneralFailure('Sign out failed: ${e.toString()}')));
      }
    }
  }

  Future<void> resetPassword(String email) async {
    if (isClosed) return;
    emit(const AuthState.loading());

    try {
      final result = await _resetPasswordUseCase(email);

      if (!isClosed) {
        result.fold((failure) => emit(AuthState.error(failure)), (_) => emit(const AuthState.passwordResetSent()));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthState.error(GeneralFailure('Password reset failed: ${e.toString()}')));
      }
    }
  }

  Future<void> checkOrganizationCode(String code) async {
    if (isClosed) return;
    emit(const AuthState.checkingOrganizationCode());

    try {
      final result = await _checkOrganizationCodeUseCase(code);

      if (!isClosed) {
        result.fold(
          (failure) => emit(AuthState.error(failure)),
          (exists) => emit(AuthState.organizationCodeChecked(exists)),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthState.error(GeneralFailure('Organization check failed: ${e.toString()}')));
      }
    }
  }

  void initializeAuthStream() {
    _authSubscription?.cancel();
    _authSubscription = _getAuthStateChangesUseCase().listen(
      (user) {
        if (!isClosed) {
          if (user == null) {
            emit(const AuthState.unauthenticated());
          } else {
            emit(AuthState.authenticated(user));
          }
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(AuthState.error(GeneralFailure('Auth stream error: ${error.toString()}')));
        }
      },
    );
  }

  entities.User? get currentUser => _getCurrentUserUseCase();
}
