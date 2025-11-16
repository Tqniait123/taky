// lib/features/all/auth/presentation/cubit/_auth_cubit.dart
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taqy/core/notifications/notification_service.dart';
import 'package:taqy/core/translations/locale_keys.g.dart';
import 'package:taqy/features/all/auth/data/repositories/auth_repo.dart';
import 'package:taqy/features/all/auth/domain/entities/user.dart';

part 'auth_cubit.freezed.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authSubscription;

  AuthCubit(this._authRepository) : super(const AuthState.initial()) {
    initializeAuthStream();
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  // ================================
  // AUTHENTICATION METHODS
  // ================================

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    XFile? profileImage,
    String? organizationName,
    String? organizationCode,
    XFile? organizationLogo,
    String? primaryColor,
    String? secondaryColor,
    bool skipImageUpload = true,
    String? jobTitle ,
  }) async {
    if (isClosed) return;
    emit(const AuthState.loading());

    try {
      String? profileImageUrl;
      String? orgLogoUrl;

      // Handle image uploads if not skipping
      if (!skipImageUpload) {
        if (profileImage != null) {
          final uploadResult = await _authRepository.uploadProfileImage(
            profileImage.path,
          );
          final result = uploadResult.fold((failure) {
            if (!isClosed) emit(AuthState.error(failure.message));
            return null;
          }, (url) => url);

          if (result == null) return;
          profileImageUrl = result;
        }

        if (role == UserRole.admin && organizationLogo != null) {
          final uploadResult = await _authRepository.uploadOrganizationLogo(
            organizationLogo.path,
          );
          final result = uploadResult.fold((failure) {
            if (!isClosed) emit(AuthState.error(failure.message));
            return null;
          }, (url) => url);

          if (result == null) return;
          orgLogoUrl = result;
        }
      } else {
        // Use placeholder URLs for testing
        profileImageUrl = profileImage != null
            ? 'https://via.placeholder.com/150'
            : null;
        orgLogoUrl = organizationLogo != null
            ? 'https://via.placeholder.com/300'
            : null;
      }

      // For non-admin users, verify organization code exists
      if (role != UserRole.admin && organizationCode != null) {
        final checkResult = await _authRepository.checkOrganizationCodeExists(
          organizationCode,
        );
        checkResult.fold(
          (failure) {
            if (!isClosed) emit(AuthState.error(failure.message));
          },
          (exists) {
            if (!exists && !isClosed) {
              emit(AuthState.error(LocaleKeys.organizationCodeNotFound.tr()));
            }
          },
        );
        if (state is AuthError) return;
      }

      // Perform sign up
      final result = await _authRepository.signUp(
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
        jobTitle: jobTitle,
      );

      if (!isClosed) {
        result.fold(
          (failure) => emit(AuthState.error(failure.message)),
          (user) => emit(AuthState.authenticated(user)),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthState.error(LocaleKeys.registrationFailed.tr()));
      }
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    if (isClosed) return;
    emit(const AuthState.loading());

    try {
      final result = await _authRepository.signIn(
        email: email,
        password: password,
      );

      if (!isClosed) {
        result.fold((failure) => emit(AuthState.error(failure.message)), (
          user,
        ) async {
          await NotificationService().initialize(
            userId: user.id,
            organizationId: user.organizationId,
            role: user.role,
          );
          emit(AuthState.authenticated(user));
        });
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthState.error(LocaleKeys.errors_signInFailed.tr()));
      }
    }
  }

  Future<void> signOut() async {
    if (isClosed) return;
    emit(const AuthState.loading());

    try {
      final result = await _authRepository.signOut();

      if (!isClosed) {
        result.fold((failure) => emit(AuthState.error(failure.message)), (
          _,
        ) async {
          await NotificationService().cleanup();
          emit(const AuthState.unauthenticated());
        });
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthState.error(LocaleKeys.errors_signOutFailed.tr()));
      }
    }
  }

  Future<void> forgotPassword(String email) async {
    if (isClosed) return;
    emit(const AuthState.loading());

    try {
      final result = await _authRepository.resetPassword(email);

      if (!isClosed) {
        result.fold(
          (failure) => emit(AuthState.error(failure.message)),
          (_) => emit(const AuthState.passwordResetSent()),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthState.error(LocaleKeys.passwordResetEmailFailed.tr()));
      }
    }
  }

  Future<void> resetPassword(String email) async {
    if (isClosed) return;
    emit(const AuthState.loading());

    try {
      final result = await _authRepository.resetPassword(email);

      if (!isClosed) {
        result.fold(
          (failure) => emit(AuthState.error(failure.message)),
          (_) => emit(const AuthState.passwordResetSent()),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthState.error(LocaleKeys.passwordResetEmailFailed.tr()));
      }
    }
  }

  Future<void> checkOrganizationCode(String code) async {
    if (isClosed) return;
    emit(const AuthState.checkingOrganizationCode());

    try {
      final result = await _authRepository.checkOrganizationCodeExists(code);

      if (!isClosed) {
        result.fold(
          (failure) => emit(AuthState.error(failure.message)),
          (exists) => emit(AuthState.organizationCodeChecked(exists)),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthState.error(LocaleKeys.errors_organizationCheckFailed.tr()));
      }
    }
  }

  // ================================
  // UTILITY METHODS
  // ================================

  void initializeAuthStream() {
    _authSubscription?.cancel();
    _authSubscription = _authRepository.getAuthStateChanges().listen(
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
          emit(AuthState.error(LocaleKeys.errors_authStreamError.tr()));
        }
      },
    );
  }

  User? get currentUser => _authRepository.getCurrentUser();

  bool get isAuthenticated => currentUser != null;

  UserRole? get currentUserRole => currentUser?.role;

  String? get currentOrganizationId => currentUser?.organizationId;
}
