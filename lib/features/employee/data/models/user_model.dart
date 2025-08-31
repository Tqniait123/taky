
// User Model (based on your provided structure)
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, employee, officeBoy }

class EmployeeUserModel {
  final String id;
  final String email;
  final String? passwordHash;
  final String name;
  final String? phone;
  final UserRole role;
  final String organizationId;
  final String? locale;
  final String? profileImageUrl;
  final bool isActive;
  final bool isVerified;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmployeeUserModel({
    required this.id,
    required this.email,
    this.passwordHash,
    required this.name,
    this.phone,
    required this.role,
    required this.organizationId,
    this.locale,
    this.profileImageUrl,
    required this.isActive,
    required this.isVerified,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmployeeUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmployeeUserModel(
      id: doc.id,
      email: data['email'] ?? '',
      passwordHash: data['passwordHash'],
      name: data['name'] ?? '',
      phone: data['phone'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.employee,
      ),
      organizationId: data['organizationId'] ?? '',
      locale: data['locale'],
      profileImageUrl: data['profileImageUrl'],
      isActive: data['isActive'] ?? true,
      isVerified: data['isVerified'] ?? false,
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'passwordHash': passwordHash,
      'name': name,
      'phone': phone,
      'role': role.toString().split('.').last,
      'organizationId': organizationId,
      'locale': locale,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'isVerified': isVerified,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
