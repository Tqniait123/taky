// lib/features/all/auth/presentation/cubit/auth_state.dart
part of 'auth_cubit.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(User user) = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.error(Failure failure) = AuthError;
  const factory AuthState.checkingOrganizationCode() = AuthCheckingOrganizationCode;
  const factory AuthState.organizationCodeChecked(bool exists) = AuthOrganizationCodeChecked;
  const factory AuthState.passwordResetSent() = AuthPasswordResetSent;
}
