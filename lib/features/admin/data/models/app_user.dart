import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { employee, officeBoy, admin }

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String organizationId;
  final DateTime createdAt;
  final bool isActive;
  final String? profilePictureUrl;
  final String? department;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.organizationId,
    required this.createdAt,
    this.isActive = true,
    this.profilePictureUrl,
    this.department,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.employee,
      ),
      organizationId: data['organizationId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      profilePictureUrl: data['profilePictureUrl'],
      department: data['department'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString().split('.').last,
      'organizationId': organizationId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'profilePictureUrl': profilePictureUrl,
      'department': department,
    };
  }
}