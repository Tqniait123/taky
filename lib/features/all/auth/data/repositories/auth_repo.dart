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

// // Extension for UserRole enum
// extension UserRoleExtension on UserRole {
//   String get value {
//     switch (this) {
//       case UserRole.admin:
//         return 'admin';
//       case UserRole.employee:
//         return 'employee';
//       case UserRole.officeBoy:
//         return 'office_boy';
//     }
//   }

//   static UserRole fromString(String value) {
//     switch (value.toLowerCase()) {
//       case 'admin':
//         return UserRole.admin;
//       case 'employee':
//         return UserRole.employee;
//       case 'office_boy':
//         return UserRole.officeBoy;
//       default:
//         return UserRole.employee;
//     }
//   }
// }

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  // Cache for bucket existence to avoid repeated checks
  final Map<String, bool> _bucketExists = {};

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
      // 1. Validate inputs for admin
      if (role == UserRole.admin && (organizationCode == null || organizationName == null)) {
        return Left(DatabaseFailure('Organization code and name are required for admin signup'));
      }

      // 2. Create organization if admin
      String? orgId = organizationId;
      if (role == UserRole.admin) {
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
              'code': organizationCode!,
              'name': organizationName!,
              'logo': organizationLogo,
              'primary_color': primaryColor,
              'secondary_color': secondaryColor,
            })
            .select()
            .single();

        SupabaseLogger.logResponse('INSERT', 'organizations', orgResponse);
        orgId = orgResponse['id'] as String?;

        if (orgId == null || orgId.isEmpty) {
          return Left(DatabaseFailure('Failed to retrieve organization ID after creation'));
        }
      }

      // 3. For employee/office boy, get organization by code
      if (role != UserRole.admin && organizationCode != null) {
        final orgResult = await getOrganizationByCode(organizationCode);
        orgResult.fold((failure) => throw Exception(failure.message), (organization) {
          if (organization == null) {
            throw Exception('Organization not found');
          }
          orgId = organization.id;
        });
      }

      // 4. Validate orgId before proceeding
      if (orgId == null || orgId!.isEmpty) {
        return Left(DatabaseFailure('Organization ID is missing or invalid'));
      }

      // 5. Register user in auth
      SupabaseLogger.logRequest('signUp', 'auth', {'email': email, 'password': password});

      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'role': role.value, // Use role.value instead of role.name for consistency
          'organization_id': orgId,
          'profile_image_url': profileImageUrl,
        },
      );

      SupabaseLogger.logResponse('signUp', 'auth', authResponse);

      if (authResponse.user == null) {
        return Left(AuthFailure('User creation failed'));
      }

      // 6. Create user in users table
      final userModel = UserModel(
        id: authResponse.user!.id,
        email: email,
        name: name,
        phone: phone,
        role: role,
        organizationId: orgId ?? '', // Removed fallback to empty string
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
      final userData = await _client
          .from('users')
          .select('*, organizations(*)')
          .eq('id', response.user!.id)
          .maybeSingle();

      if (userData == null) {
        return Left(DatabaseFailure('User data not found'));
      }

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

      final response = await _client.from('organizations').select().eq('code', code).maybeSingle();

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

      final response = await _client.from('organizations').select('id').eq('code', code).maybeSingle();

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

  // Enhanced file upload with bucket creation
  Future<Either<Failure, String>> _uploadFile(String filePath, String bucketName) async {
    try {
      // Check if bucket exists, create if not
      await _ensureBucketExists(bucketName);

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';

      SupabaseLogger.logRequest('UPLOAD', 'storage/$bucketName', fileName);

      await _client.storage.from(bucketName).upload(fileName, File(filePath));

      final url = _client.storage.from(bucketName).getPublicUrl(fileName);

      SupabaseLogger.logResponse('UPLOAD', 'storage/$bucketName', url);

      return Right(url);
    } on StorageException catch (e) {
      SupabaseLogger.logError('uploadFile', 'storage', e);

      // If bucket not found, try to create it and retry
      if (e.statusCode == 404 && e.message.contains('Bucket not found')) {
        try {
          await _createBucket(bucketName);
          return _uploadFile(filePath, bucketName); // Retry upload
        } catch (createError) {
          return Left(StorageFailure('Failed to create bucket and upload file: ${createError.toString()}'));
        }
      }

      return Left(StorageFailure(e.message));
    } catch (e) {
      SupabaseLogger.logError('uploadFile', 'general', e);
      return Left(GeneralFailure(e.toString()));
    }
  }

  // Ensure bucket exists, create if not
  Future<void> _ensureBucketExists(String bucketName) async {
    // Check cache first
    if (_bucketExists[bucketName] == true) return;

    try {
      // List buckets to check if our bucket exists
      final buckets = await _client.storage.listBuckets();
      final bucketExists = buckets.any((bucket) => bucket.name == bucketName);

      if (!bucketExists) {
        await _createBucket(bucketName);
      }

      _bucketExists[bucketName] = true;
    } catch (e) {
      SupabaseLogger.logError('ensureBucketExists', 'storage', e);
      // Don't throw here, let the upload method handle the error
    }
  }

  // Create storage bucket with appropriate policies
  Future<void> _createBucket(String bucketName) async {
    try {
      SupabaseLogger.logRequest('CREATE_BUCKET', 'storage', bucketName);

      // Create the bucket
      await _client.storage.createBucket(
        bucketName,
        const BucketOptions(
          public: true,
          allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
          fileSizeLimit: "5242880", // 5MB
        ),
      );

      SupabaseLogger.logResponse('CREATE_BUCKET', 'storage', 'Bucket $bucketName created successfully');

      // Set policies for the bucket
      await _setBucketPolicies(bucketName);
    } catch (e) {
      SupabaseLogger.logError('createBucket', 'storage', e);
      throw Exception('Failed to create bucket $bucketName: ${e.toString()}');
    }
  }

  // Set appropriate policies for the bucket
  Future<void> _setBucketPolicies(String bucketName) async {
    try {
      // Note: In a real app, you'd want more restrictive policies
      // This is a basic setup for development

      final policies = [
        {
          'policy_name': '${bucketName}_select_policy',
          'definition':
              'CREATE POLICY "${bucketName}_select_policy" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = \'$bucketName\');',
        },
        {
          'policy_name': '${bucketName}_insert_policy',
          'definition':
              'CREATE POLICY "${bucketName}_insert_policy" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = \'$bucketName\');',
        },
        {
          'policy_name': '${bucketName}_update_policy',
          'definition':
              'CREATE POLICY "${bucketName}_update_policy" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = \'$bucketName\');',
        },
        {
          'policy_name': '${bucketName}_delete_policy',
          'definition':
              'CREATE POLICY "${bucketName}_delete_policy" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = \'$bucketName\');',
        },
      ];

      for (final policy in policies) {
        try {
          await _client.rpc('create_storage_policy', params: policy);
        } catch (e) {
          // Policy might already exist, log but don't fail
          SupabaseLogger.logError('setBucketPolicies', 'storage', 'Policy creation failed: $e');
        }
      }
    } catch (e) {
      SupabaseLogger.logError('setBucketPolicies', 'storage', e);
      // Don't throw here as policies might already exist
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
      role: UserRole.fromStr(user.userMetadata?['role'] ?? 'employee'),
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
