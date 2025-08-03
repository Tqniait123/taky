// lib/features/all/auth/domain/usecases/sign_up_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:taqy/core/errors/failures.dart';
import 'package:taqy/features/all/auth/data/repositories/auth_repo.dart';
import 'package:taqy/features/all/auth/domain/entities/user.dart';

class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  Future<Either<Failure, User>> call(SignUpParams params) async {
    return await _repository.signUp(
      email: params.email,
      password: params.password,
      name: params.name,
      role: params.role,
      phone: params.phone,
      profileImageUrl: params.profileImageUrl,
      organizationId: params.organizationId,
      organizationName: params.organizationName,
      organizationCode: params.organizationCode,
      organizationLogo: params.organizationLogo,
      primaryColor: params.primaryColor,
      secondaryColor: params.secondaryColor,
    );
  }
}

class SignUpParams {
  final String email;
  final String password;
  final String name;
  final UserRole role;
  final String? phone;
  final String? profileImageUrl;
  final String? organizationId;
  final String? organizationName;
  final String? organizationCode;
  final String? organizationLogo;
  final String? primaryColor;
  final String? secondaryColor;

  SignUpParams({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.phone,
    this.profileImageUrl,
    this.organizationId,
    this.organizationName,
    this.organizationCode,
    this.organizationLogo,
    this.primaryColor,
    this.secondaryColor,
  });
}

// lib/features/all/auth/domain/usecases/sign_in_usecase.dart
class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  Future<Either<Failure, User>> call(SignInParams params) async {
    return await _repository.signIn(email: params.email, password: params.password);
  }
}

class SignInParams {
  final String email;
  final String password;

  SignInParams({required this.email, required this.password});
}

// lib/features/all/auth/domain/usecases/sign_out_usecase.dart
class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  Future<Either<Failure, void>> call() async {
    return await _repository.signOut();
  }
}

// lib/features/all/auth/domain/usecases/reset_password_usecase.dart
class ResetPasswordUseCase {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  Future<Either<Failure, void>> call(String email) async {
    return await _repository.resetPassword(email);
  }
}

// lib/features/all/auth/domain/usecases/check_organization_code_usecase.dart
class CheckOrganizationCodeUseCase {
  final AuthRepository _repository;

  CheckOrganizationCodeUseCase(this._repository);

  Future<Either<Failure, bool>> call(String code) async {
    return await _repository.checkOrganizationCodeExists(code);
  }
}

// lib/features/all/auth/domain/usecases/get_current_user_usecase.dart
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  User? call() {
    return _repository.getCurrentUser();
  }
}

// lib/features/all/auth/domain/usecases/get_auth_state_changes_usecase.dart
class GetAuthStateChangesUseCase {
  final AuthRepository _repository;

  GetAuthStateChangesUseCase(this._repository);

  Stream<User?> call() {
    return _repository.getAuthStateChanges();
  }
}
