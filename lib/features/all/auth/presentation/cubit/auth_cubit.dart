import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taqy/features/all/auth/data/repositories/auth_repo.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;
  AuthCubit(this._repo) : super(AuthInitial());

  static AuthCubit get(context) => BlocProvider.of<AuthCubit>(context);

  /// Get the current user if already authenticated
  User? get currentUser => _repo.currentUser;

  /// Stream of authentication state changes
  Stream<AuthState> get authStateChanges => _repo.authStateChanges.map((authState) {
    if (authState.event == AuthChangeEvent.signedIn) {
      return AuthSuccess(authState.session!.user);
    } else if (authState.event == AuthChangeEvent.signedOut) {
      return AuthInitial();
    }
    return AuthInitial();
  });

  /// Auto login - checks if user is already authenticated
  Future<void> autoLogin() async {
    try {
      emit(AuthLoading());
      final user = _repo.currentUser;
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Email and password login
  Future<void> login({required String email, required String password}) async {
    try {
      emit(AuthLoading());
      final response = await _repo.signIn(email: email, password: password);
      emit(AuthSuccess(response.user ?? User(id: '', appMetadata: {}, userMetadata: {}, aud: '', createdAt: '')));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Registration with email and password
  Future<void> register({required String email, required String password, Map<String, dynamic>? userData}) async {
    try {
      emit(AuthLoading());
      final response = await _repo.signUp(email: email, password: password, userData: userData);
      emit(RegisterSuccess());
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Sign out
  Future<void> logout() async {
    try {
      emit(AuthLoading());
      await _repo.signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Note: The following methods would need additional Supabase configuration
  // They're included here for interface consistency but would need implementation

  /// Google OAuth login
  Future<void> loginWithGoogle() async {
    try {
      emit(AuthLoading());
      // Implement Google OAuth with Supabase
      // final response = await _repo.signInWithGoogle();
      // emit(AuthSuccess(response.user));
      emit(AuthError("Google login not implemented"));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Apple OAuth login
  Future<void> loginWithApple() async {
    try {
      emit(AuthLoading());
      // Implement Apple OAuth with Supabase
      // final response = await _repo.signInWithApple();
      // emit(AuthSuccess(response.user));
      emit(AuthError("Apple login not implemented"));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Password reset request
  Future<void> forgetPassword(String email) async {
    try {
      emit(ForgetPasswordLoading());
      // Implement password reset with Supabase
      // await _repo.resetPasswordForEmail(email);
      emit(ForgetPasswordSentOTP());
    } catch (e) {
      emit(ForgetPasswordError(e.toString()));
    }
  }
}
