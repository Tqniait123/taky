// lib/core/services/firebase_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Current user getter
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ================================
  // AUTHENTICATION METHODS
  // ================================

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmailPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  // ================================
  // FIRESTORE CRUD OPERATIONS
  // ================================

  /// Add document to collection
  Future<DocumentReference> addDocument(String collection, Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    return await _firestore.collection(collection).add(data);
  }

  /// Add document with custom ID
  Future<void> setDocument(String collection, String docId, Map<String, dynamic> data, {bool merge = false}) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(collection).doc(docId).set(data, SetOptions(merge: merge));
  }

  /// Update document
  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(collection).doc(docId).update(data);
  }

  /// Delete document
  Future<void> deleteDocument(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  /// Get document by ID
  Future<DocumentSnapshot> getDocument(String collection, String docId) async {
    return await _firestore.collection(collection).doc(docId).get();
  }

  /// Get collection
  Future<QuerySnapshot> getCollection(String collection) async {
    return await _firestore.collection(collection).get();
  }

  /// Get collection with where clause
  Future<QuerySnapshot> getCollectionWhere(
    String collection,
    String field,
    dynamic value, {
    bool isEqualTo = true,
  }) async {
    Query query = _firestore.collection(collection);

    if (isEqualTo) {
      query = query.where(field, isEqualTo: value);
    } else {
      query = query.where(field, isNotEqualTo: value);
    }

    return await query.get();
  }

  /// Get collection with multiple conditions
  Future<QuerySnapshot> getCollectionWhereMultiple(
    String collection,
    Map<String, dynamic> conditions,
  ) async {
    Query query = _firestore.collection(collection);

    conditions.forEach((field, value) {
      query = query.where(field, isEqualTo: value);
    });

    return await query.get();
  }

  /// Get collection with ordering
  Future<QuerySnapshot> getCollectionOrdered(
    String collection,
    String orderBy, {
    bool descending = false,
    int? limit,
  }) async {
    Query query = _firestore.collection(collection).orderBy(orderBy, descending: descending);

    if (limit != null) {
      query = query.limit(limit);
    }

    return await query.get();
  }

  /// Search documents by field (case-insensitive)
  Future<QuerySnapshot> searchDocuments(
    String collection,
    String field,
    String searchTerm,
  ) async {
    return await _firestore
        .collection(collection)
        .where(field, isGreaterThanOrEqualTo: searchTerm.toLowerCase())
        .where(field, isLessThanOrEqualTo: '${searchTerm.toLowerCase()}\uf8ff')
        .get();
  }

  /// Get collection with pagination
  Future<QuerySnapshot> getCollectionPaginated(
    String collection, {
    DocumentSnapshot? startAfter,
    int limit = 20,
    String? orderBy,
    bool descending = false,
  }) async {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return await query.limit(limit).get();
  }

  // ================================
  // REAL-TIME STREAMS
  // ================================

  /// Stream collection
  Stream<QuerySnapshot> streamCollection(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  /// Stream document
  Stream<DocumentSnapshot> streamDocument(String collection, String docId) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  /// Stream collection with where clause
  Stream<QuerySnapshot> streamCollectionWhere(
    String collection,
    String field,
    dynamic value,
  ) {
    return _firestore.collection(collection).where(field, isEqualTo: value).snapshots();
  }

  /// Stream collection with multiple conditions
  Stream<QuerySnapshot> streamCollectionWhereMultiple(
    String collection,
    Map<String, dynamic> conditions,
  ) {
    Query query = _firestore.collection(collection);

    conditions.forEach((field, value) {
      query = query.where(field, isEqualTo: value);
    });

    return query.snapshots();
  }

  /// Stream collection ordered
  Stream<QuerySnapshot> streamCollectionOrdered(
    String collection,
    String orderBy, {
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection).orderBy(orderBy, descending: descending);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  // ================================
  // ORGANIZATION-SCOPED OPERATIONS
  // ================================

  /// Get organization documents (scoped by organization ID)
  Future<QuerySnapshot> getOrganizationDocuments(
    String collection,
    String organizationId,
  ) async {
    return await _firestore
        .collection(collection)
        .where('organizationId', isEqualTo: organizationId)
        .get();
  }

  /// Stream organization documents
  Stream<QuerySnapshot> streamOrganizationDocuments(
    String collection,
    String organizationId,
  ) {
    return _firestore
        .collection(collection)
        .where('organizationId', isEqualTo: organizationId)
        .snapshots();
  }

  /// Add document with organization scope
  Future<DocumentReference> addOrganizationDocument(
    String collection,
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    data['organizationId'] = organizationId;
    return await addDocument(collection, data);
  }

  // ================================
  // STORAGE OPERATIONS
  // ================================

  /// Upload file from path
  Future<String> uploadFile(String filePath, String storagePath) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  /// Upload file from bytes
  Future<String> uploadFileFromBytes(Uint8List bytes, String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  /// Delete file
  Future<void> deleteFile(String storagePath) async {
    try {
      await _storage.ref().child(storagePath).delete();
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }

  /// Upload profile image
  Future<String> uploadProfileImage(String userId, String filePath) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
    final storagePath = 'profile_images/$userId/$fileName';
    return await uploadFile(filePath, storagePath);
  }

  /// Upload organization logo
  Future<String> uploadOrganizationLogo(String organizationId, String filePath) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
    final storagePath = 'organization_logos/$organizationId/$fileName';
    return await uploadFile(filePath, storagePath);
  }

  // ================================
  // FCM OPERATIONS
  // ================================

  /// Get FCM token
  Future<String?> getFCMToken() async {
    return await _messaging.getToken();
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Request notification permissions
  Future<NotificationSettings> requestPermission() async {
    return await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  // ================================
  // BATCH OPERATIONS
  // ================================

  /// Batch write operations
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    final batch = _firestore.batch();

    for (final operation in operations) {
      final type = operation['type'] as String;
      final collection = operation['collection'] as String;
      final docId = operation['docId'] as String?;
      final data = operation['data'] as Map<String, dynamic>?;

      switch (type) {
        case 'add':
          if (docId != null && data != null) {
            batch.set(_firestore.collection(collection).doc(docId), {
              ...data,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          break;
        case 'update':
          if (docId != null && data != null) {
            batch.update(_firestore.collection(collection).doc(docId), {
              ...data,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          break;
        case 'delete':
          if (docId != null) {
            batch.delete(_firestore.collection(collection).doc(docId));
          }
          break;
      }
    }

    await batch.commit();
  }

  // ================================
  // UTILITY METHODS
  // ================================

  /// Check if document exists
  Future<bool> documentExists(String collection, String docId) async {
    final doc = await _firestore.collection(collection).doc(docId).get();
    return doc.exists;
  }

  /// Count documents in collection
  Future<int> countDocuments(String collection) async {
    final snapshot = await _firestore.collection(collection).count().get();
    return snapshot.count ?? 0;
  }

  /// Generate unique ID
  String generateId() {
    return _firestore.collection('temp').doc().id;
  }

  /// Convert Timestamp to DateTime
  DateTime? timestampToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }

  // ================================
  // ERROR HANDLING
  // ================================

  String _handleAuthException(FirebaseAuthException e) {
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
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }

  // ================================
  // TRANSACTION SUPPORT
  // ================================

  /// Run transaction
  Future<T> runTransaction<T>(Future<T> Function(Transaction) updateFunction) async {
    return await _firestore.runTransaction(updateFunction);
  }

  // ================================
  // QUERY BUILDERS
  // ================================

  /// Build complex query
  Query buildQuery(
    String collection, {
    List<Map<String, dynamic>>? whereConditions,
    String? orderBy,
    bool descending = false,
    int? limit,
    DocumentSnapshot? startAfter,
    DocumentSnapshot? endBefore,
  }) {
    Query query = _firestore.collection(collection);

    // Add where conditions
    if (whereConditions != null) {
      for (final condition in whereConditions) {
        final field = condition['field'] as String;
        final operator = condition['operator'] as String? ?? '==';
        final value = condition['value'];

        switch (operator) {
          case '==':
            query = query.where(field, isEqualTo: value);
            break;
          case '!=':
            query = query.where(field, isNotEqualTo: value);
            break;
          case '>':
            query = query.where(field, isGreaterThan: value);
            break;
          case '>=':
            query = query.where(field, isGreaterThanOrEqualTo: value);
            break;
          case '<':
            query = query.where(field, isLessThan: value);
            break;
          case '<=':
            query = query.where(field, isLessThanOrEqualTo: value);
            break;
          case 'array-contains':
            query = query.where(field, arrayContains: value);
            break;
          case 'array-contains-any':
            query = query.where(field, arrayContainsAny: value);
            break;
          case 'in':
            query = query.where(field, whereIn: value);
            break;
          case 'not-in':
            query = query.where(field, whereNotIn: value);
            break;
        }
      }
    }

    // Add ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Add pagination
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    if (endBefore != null) {
      query = query.endBeforeDocument(endBefore);
    }

    // Add limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query;
  }
}
