// lib/features/all/auth/domain/repositories/auth_repository.dart
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:taqy/config/supabase_logger.dart';
import 'package:taqy/core/errors/failures.dart';
import 'package:taqy/features/all/auth/data/models/organization_model.dart';
import 'package:taqy/features/all/auth/data/models/user_model.dart';
import 'package:taqy/features/all/auth/domain/entities/organization.dart';
import 'package:taqy/features/all/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? profileImageUrl,
    String? organizationId,
    String? organizationName,
    String? organizationCode,
    String? organizationLogo,
    String? primaryColor,
    String? secondaryColor,
  });

  Future<Either<Failure, User>> signIn({required String email, required String password});

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, void>> resetPassword(String email);

  Future<Either<Failure, Organization?>> getOrganizationByCode(String code);

  Future<Either<Failure, bool>> checkOrganizationCodeExists(String code);

  Future<Either<Failure, String>> uploadProfileImage(String filePath);

  Future<Either<Failure, String>> uploadOrganizationLogo(String filePath);

  Future<Either<Failure, void>> updateFCMToken(String userId, String token);

  User? getCurrentUser();

  Stream<User?> getAuthStateChanges();
}

// Extension for UserRole enum
extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.employee:
        return 'employee';
      case UserRole.officeBoy:
        return 'office_boy';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'employee':
        return UserRole.employee;
      case 'office_boy':
        return UserRole.officeBoy;
      default:
        return UserRole.employee;
    }
  }
}

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  AuthRepositoryImpl(this._client);

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? profileImageUrl,
    String? organizationId,
    String? organizationName,
    String? organizationCode,
    String? organizationLogo,
    String? primaryColor,
    String? secondaryColor,
  }) async {
    try {
      // 1. Create organization if admin
      String? orgId = organizationId;
      if (role == UserRole.admin && organizationCode != null) {
        SupabaseLogger.logRequest('INSERT', 'organizations', {
          'code': organizationCode,
          'name': organizationName,
          'logo': organizationLogo,
          'primary_color': primaryColor,
          'secondary_color': secondaryColor,
        });

        final orgResponse = await _client
            .from('organizations')
            .insert({
              'code': organizationCode,
              'name': organizationName,
              'logo': organizationLogo,
              'primary_color': primaryColor,
              'secondary_color': secondaryColor,
            })
            .select()
            .single();

        SupabaseLogger.logResponse('INSERT', 'organizations', orgResponse);
        orgId = orgResponse['id'] as String;
      }

      // 2. For employee/office boy, get organization by code
      if (role != UserRole.admin && organizationCode != null) {
        final orgResult = await getOrganizationByCode(organizationCode);
        orgResult.fold((failure) => throw Exception(failure.message), (organization) {
          if (organization == null) {
            throw Exception('Organization not found');
          }
          orgId = organization.id;
        });
      }

      // 3. Register user in auth
      SupabaseLogger.logRequest('signUp', 'auth', {'email': email, 'password': password});

      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'role': role.name,
          'organization_id': orgId,
          'profile_image_url': profileImageUrl,
        },
      );

      SupabaseLogger.logResponse('signUp', 'auth', authResponse);

      if (authResponse.user == null) {
        return Left(AuthFailure('User creation failed'));
      }

      // 4. Create user in users table
      final userModel = UserModel(
        id: authResponse.user!.id,
        email: email,
        name: name,
        phone: phone,
        role: role,
        organizationId: orgId!,
        profileImageUrl: profileImageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        isVerified: true,
      );

      SupabaseLogger.logRequest('INSERT', 'users', userModel.toJson());

      await _client.from('users').insert(userModel.toJson());

      return Right(userModel);
    } on AuthException catch (e) {
      SupabaseLogger.logError('signUp', 'auth', e);
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      SupabaseLogger.logError('signUp', 'database', e);
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      SupabaseLogger.logError('signUp', 'general', e);
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signIn({required String email, required String password}) async {
    try {
      SupabaseLogger.logRequest('signIn', 'auth', {'email': email});

      final response = await _client.auth.signInWithPassword(email: email, password: password);

      SupabaseLogger.logResponse('signIn', 'auth', response);

      if (response.user == null) {
        return Left(AuthFailure('Authentication failed'));
      }

      // Get additional user data from users table
      final userData = await _client.from('users').select('*, organizations(*)').eq('id', response.user!.id).single();

      final user = UserModel.fromJson(userData);
      return Right(user);
    } on AuthException catch (e) {
      SupabaseLogger.logError('signIn', 'auth', e);
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      SupabaseLogger.logError('signIn', 'database', e);
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      SupabaseLogger.logError('signIn', 'general', e);
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Right(null);
    } catch (e) {
      SupabaseLogger.logError('signOut', 'auth', e);
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      SupabaseLogger.logError('resetPassword', 'auth', e);
      return Left(AuthFailure(e.message));
    } catch (e) {
      SupabaseLogger.logError('resetPassword', 'general', e);
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Organization?>> getOrganizationByCode(String code) async {
    try {
      SupabaseLogger.logRequest('SELECT', 'organizations', {'code': code});

      final response = await _client
          .from('organizations')
          .select()
          .eq('code', code)
          .eq('is_active', true)
          .maybeSingle();

      SupabaseLogger.logResponse('SELECT', 'organizations', response);

      if (response == null) {
        return const Right(null);
      }

      final organization = OrganizationModel.fromJson(response);
      return Right(organization);
    } on PostgrestException catch (e) {
      SupabaseLogger.logError('getOrganizationByCode', 'database', e);
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      SupabaseLogger.logError('getOrganizationByCode', 'general', e);
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkOrganizationCodeExists(String code) async {
    try {
      SupabaseLogger.logRequest('SELECT', 'organizations', {'code': code});

      final response = await _client
          .from('organizations')
          .select('id')
          .eq('code', code)
          .eq('is_active', true)
          .maybeSingle();

      SupabaseLogger.logResponse('SELECT', 'organizations', response);

      return Right(response != null);
    } on PostgrestException catch (e) {
      SupabaseLogger.logError('checkOrganizationCodeExists', 'database', e);
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      SupabaseLogger.logError('checkOrganizationCodeExists', 'general', e);
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfileImage(String filePath) async {
    return _uploadFile(filePath, 'profile_images');
  }

  @override
  Future<Either<Failure, String>> uploadOrganizationLogo(String filePath) async {
    return _uploadFile(filePath, 'organization_logos');
  }

  Future<Either<Failure, String>> _uploadFile(String filePath, String bucket) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';

      SupabaseLogger.logRequest('UPLOAD', 'storage/$bucket', fileName);

      await _client.storage.from(bucket).upload(fileName, File(filePath));

      final url = _client.storage.from(bucket).getPublicUrl(fileName);

      SupabaseLogger.logResponse('UPLOAD', 'storage/$bucket', url);

      return Right(url);
    } on StorageException catch (e) {
      SupabaseLogger.logError('uploadFile', 'storage', e);
      return Left(StorageFailure(e.message));
    } catch (e) {
      SupabaseLogger.logError('uploadFile', 'general', e);
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateFCMToken(String userId, String token) async {
    try {
      await _client.from('users').update({'fcm_token': token}).eq('id', userId);
      return const Right(null);
    } on PostgrestException catch (e) {
      SupabaseLogger.logError('updateFCMToken', 'database', e);
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      SupabaseLogger.logError('updateFCMToken', 'general', e);
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  User? getCurrentUser() {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] ?? '',
      phone: user.userMetadata?['phone'],
      role: UserRoleExtension.fromString(user.userMetadata?['role'] ?? 'employee'),
      organizationId: user.userMetadata?['organization_id'] ?? '',
      profileImageUrl: user.userMetadata?['profile_image_url'],
      isActive: true,
      isVerified: user.emailConfirmedAt != null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Stream<User?> getAuthStateChanges() {
    return _client.auth.onAuthStateChange.map((authState) {
      final user = authState.session?.user;
      if (user == null) return null;

      return UserModel(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] ?? '',
        phone: user.userMetadata?['phone'],
        role: UserRoleExtension.fromString(user.userMetadata?['role'] ?? 'employee'),
        organizationId: user.userMetadata?['organization_id'] ?? '',
        profileImageUrl: user.userMetadata?['profile_image_url'],
        isActive: true,
        isVerified: user.emailConfirmedAt != null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
  }
}
