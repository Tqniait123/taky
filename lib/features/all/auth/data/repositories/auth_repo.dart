// lib/features/all/auth/data/repositories/firebase_auth_repo.dart
import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:taqy/core/errors/failures.dart';
import 'package:taqy/core/services/firebase_service.dart';
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

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseService _firebaseService;

  // Firestore collections
  static const String usersCollection = 'users';
  static const String organizationsCollection = 'organizations';

  AuthRepositoryImpl(this._firebaseService);

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
        orgId = _firebaseService.generateId();

        final orgData = {
          'id': orgId,
          'code': organizationCode!,
          'name': organizationName!,
          'description': null,
          'address': null,
          'phone': null,
          'email': null,
          'logo': organizationLogo,
          'primaryColor': primaryColor,
          'secondaryColor': secondaryColor,
          'isActive': true,
        };

        await _firebaseService.setDocument(organizationsCollection, orgId, orgData);
        log('Organization created with ID: $orgId');
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

      // 5. Create user in Firebase Auth
      final authResult = await _firebaseService.signUpWithEmailPassword(email, password);

      if (authResult.user == null) {
        return Left(AuthFailure('User creation failed'));
      }

      final userId = authResult.user!.uid;

      // 6. Create user document in Firestore
      final userData = {
        'id': userId,
        'email': email,
        'passwordHash': null, // Don't store password hash in Firestore
        'name': name,
        'phone': phone,
        'role': role.name,
        'organizationId': orgId,
        'locale': null,
        'profileImageUrl': profileImageUrl,
        'isActive': true,
        'isVerified': authResult.user!.emailVerified,
        'fcmToken': null,
      };

      await _firebaseService.setDocument(usersCollection, userId, userData);

      // 7. Create and return User entity
      final user = UserModel(
        id: userId,
        email: email,
        passwordHash: null,
        name: name,
        phone: phone,
        role: role,
        organizationId: orgId!,
        locale: null,
        profileImageUrl: profileImageUrl,
        isActive: true,
        isVerified: authResult.user!.emailVerified,
        fcmToken: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return Right(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      log('Firebase Auth Error: ${e.code} - ${e.message}');
      return Left(AuthFailure(_handleAuthException(e)));
    } on FirebaseException catch (e) {
      log('Firestore Error: ${e.code} - ${e.message}');
      return Left(DatabaseFailure(e.message ?? 'Database error occurred'));
    } catch (e) {
      log('General Error: $e');
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signIn({required String email, required String password}) async {
    try {
      // 1. Sign in with Firebase Auth
      final authResult = await _firebaseService.signInWithEmailPassword(email, password);

      if (authResult.user == null) {
        return Left(AuthFailure('Authentication failed'));
      }

      final userId = authResult.user!.uid;

      // 2. Get user document from Firestore
      final userDoc = await _firebaseService.getDocument(usersCollection, userId);

      if (!userDoc.exists) {
        return Left(DatabaseFailure('User data not found'));
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // 3. Convert Firestore data to UserModel
      final user = UserModel.fromJson({
        ...userData,
        'createdAt':
            _firebaseService.timestampToDateTime(userData['createdAt'])?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'updatedAt':
            _firebaseService.timestampToDateTime(userData['updatedAt'])?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'role': userData['role'], // Keep as string for UserRoleExtension.fromString
      });

      return Right(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      log('Firebase Auth Error: ${e.code} - ${e.message}');
      return Left(AuthFailure(_handleAuthException(e)));
    } on FirebaseException catch (e) {
      log('Firestore Error: ${e.code} - ${e.message}');
      return Left(DatabaseFailure(e.message ?? 'Database error occurred'));
    } catch (e) {
      log('General Error: $e');
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _firebaseService.signOut();
      return const Right(null);
    } catch (e) {
      log('Sign out error: $e');
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _firebaseService.sendPasswordResetEmail(email);
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      log('Password reset error: ${e.code} - ${e.message}');
      return Left(AuthFailure(_handleAuthException(e)));
    } catch (e) {
      log('General Error: $e');
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Organization?>> getOrganizationByCode(String code) async {
    try {
      final querySnapshot = await _firebaseService.getCollectionWhere(organizationsCollection, 'code', code);

      if (querySnapshot.docs.isEmpty) {
        return const Right(null);
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>? ?? {}; // Ensure non-null Map

      final organization = OrganizationModel.fromJson({
        ...data, // Now safe to spread since we ensured it's a non-null Map
        'createdAt':
            _firebaseService.timestampToDateTime(data['createdAt'])?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'updatedAt':
            _firebaseService.timestampToDateTime(data['updatedAt'])?.toIso8601String() ??
            DateTime.now().toIso8601String(),
      }).toEntity();

      return Right(organization);
    } on FirebaseException catch (e) {
      log('Get organization error: ${e.code} - ${e.message}');
      return Left(DatabaseFailure(e.message ?? 'Database error occurred'));
    } catch (e) {
      log('General Error: $e');
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkOrganizationCodeExists(String code) async {
    try {
      final querySnapshot = await _firebaseService.getCollectionWhere(organizationsCollection, 'code', code);

      log('DEBUG: Organization query response: ${querySnapshot.docs.length} documents found');
      log('DEBUG: Searching for code: "$code"');

      return Right(querySnapshot.docs.isNotEmpty);
    } on FirebaseException catch (e) {
      log('Check organization code error: ${e.code} - ${e.message}');
      return Left(DatabaseFailure(e.message ?? 'Database error occurred'));
    } catch (e) {
      log('General Error: $e');
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfileImage(String filePath) async {
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        return Left(AuthFailure('User not authenticated'));
      }

      final url = await _firebaseService.uploadProfileImage(currentUser.uid, filePath);
      return Right(url);
    } catch (e) {
      log('Profile image upload error: $e');
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadOrganizationLogo(String filePath) async {
    try {
      // Generate a unique organization ID for the upload path
      final orgId = _firebaseService.generateId();
      final url = await _firebaseService.uploadOrganizationLogo(orgId, filePath);
      return Right(url);
    } catch (e) {
      log('Organization logo upload error: $e');
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateFCMToken(String userId, String token) async {
    try {
      await _firebaseService.updateDocument(usersCollection, userId, {'fcmToken': token});
      return const Right(null);
    } on FirebaseException catch (e) {
      log('FCM token update error: ${e.code} - ${e.message}');
      return Left(DatabaseFailure(e.message ?? 'Database error occurred'));
    } catch (e) {
      log('General Error: $e');
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  User? getCurrentUser() {
    final firebaseUser = _firebaseService.currentUser;
    if (firebaseUser == null) return null;

    // Note: This is a simplified version. In a real app, you'd want to
    // fetch the complete user data from Firestore
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      phone: firebaseUser.phoneNumber,
      role: UserRole.employee, // Default role, should be fetched from Firestore
      organizationId: '', // Should be fetched from Firestore
      profileImageUrl: firebaseUser.photoURL,
      isActive: true,
      isVerified: firebaseUser.emailVerified,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Stream<User?> getAuthStateChanges() {
    return _firebaseService.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        // Fetch complete user data from Firestore
        final userDoc = await _firebaseService.getDocument(usersCollection, firebaseUser.uid);

        if (!userDoc.exists) return null;

        final userData = userDoc.data() as Map<String, dynamic>;

        return UserModel.fromJson({
          ...userData,
          'createdAt':
              _firebaseService.timestampToDateTime(userData['createdAt'])?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'updatedAt':
              _firebaseService.timestampToDateTime(userData['updatedAt'])?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'role': userData['role'],
        });
      } catch (e) {
        log('Error fetching user data in auth stream: $e');
        return null;
      }
    });
  }

  // ================================
  // HELPER METHODS
  // ================================

  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'invalid-credential':
        return 'The supplied auth credential is malformed or has expired.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      default:
        return e.message ?? 'An unknown authentication error occurred.';
    }
  }
}
