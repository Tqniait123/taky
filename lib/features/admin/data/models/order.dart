import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, inProgress, completed, cancelled }
enum OrderType { internal, external }

class Order {
  final String id;
  final String employeeId;
  final String employeeName;
  final String officeBoyId;
  final String officeBoyName;
  final String item;
  final String description;
  final OrderType type;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? price;
  final String organizationId;
  final String? notes;

  Order({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.officeBoyId,
    required this.officeBoyName,
    required this.item,
    required this.description,
    required this.type,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.price,
    required this.organizationId,
    this.notes,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      officeBoyId: data['officeBoyId'] ?? '',
      officeBoyName: data['officeBoyName'] ?? '',
      item: data['item'] ?? '',
      description: data['description'] ?? '',
      type: OrderType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => OrderType.internal,
      ),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      price: data['price']?.toDouble(),
      organizationId: data['organizationId'] ?? '',
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'officeBoyId': officeBoyId,
      'officeBoyName': officeBoyName,
      'item': item,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'price': price,
      'organizationId': organizationId,
      'notes': notes,
    };
  }
}