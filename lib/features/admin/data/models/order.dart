import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, inProgress, completed, cancelled, needsResponse }

enum OrderType { internal, external }

enum ItemStatus { pending, available, notAvailable }

class OrderItem {
  final String name;
  final ItemStatus status;
  final String? notes; // Office boy can add notes like "out of stock"

  OrderItem({required this.name, this.status = ItemStatus.pending, this.notes});

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      status: ItemStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => ItemStatus.pending,
      ),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'status': status.toString().split('.').last,
      'notes': notes,
    };
  }

  OrderItem copyWith({String? name, ItemStatus? status, String? notes}) {
    return OrderItem(
      name: name ?? this.name,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

class AdminOrder {
  final String id;
  final String employeeId;
  final String employeeName;
  final String officeBoyId;
  final String officeBoyName;
  final List<OrderItem> items; // Changed from single item to list
  final String description;
  final OrderType type;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? price;
  final double? finalPrice;
  final String organizationId;
  final String? notes;
  final String? employeeResponse; // Employee's response to unavailable items
  final bool isSpecificallyAssigned;
  final String? specificallyAssignedOfficeBoyId;
  AdminOrder({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.officeBoyId,
    required this.officeBoyName,
    required this.items,
    required this.description,
    required this.type,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.price,
    this.finalPrice,
    required this.organizationId,
    this.notes,
    this.employeeResponse,
    this.isSpecificallyAssigned = false,
    this.specificallyAssignedOfficeBoyId,
  });

  // Compatibility getter for single item (for existing code)
  String get item => items.isNotEmpty ? items.first.name : '';

  factory AdminOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<OrderItem> itemsList = [];
    if (data['items'] != null) {
      itemsList = (data['items'] as List)
          .map((item) => OrderItem.fromMap(item))
          .toList();
    } else if (data['item'] != null) {
      // Backward compatibility for single item
      itemsList = [OrderItem(name: data['item'])];
    }

    return AdminOrder(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      officeBoyId: data['officeBoyId'] ?? '',
      officeBoyName: data['officeBoyName'] ?? '',
      items: itemsList,
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
      finalPrice: data['final_price']?.toDouble(),
      organizationId: data['organizationId'] ?? '',
      notes: data['notes'],
      employeeResponse: data['employeeResponse'],
      isSpecificallyAssigned: data['isSpecificallyAssigned'] ?? false,
      specificallyAssignedOfficeBoyId: data['specificallyAssignedOfficeBoyId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'officeBoyId': officeBoyId,
      'officeBoyName': officeBoyName,
      'items': items.map((item) => item.toMap()).toList(),
      'item': item, // Keep for backward compatibility
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'price': price,
      'final_price': finalPrice,
      'organizationId': organizationId,
      'notes': notes,
      'employeeResponse': employeeResponse,
      'isSpecificallyAssigned': isSpecificallyAssigned,
      'specificallyAssignedOfficeBoyId': specificallyAssignedOfficeBoyId,
    };
  }

  AdminOrder copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? officeBoyId,
    String? officeBoyName,
    List<OrderItem>? items,
    String? description,
    OrderType? type,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    double? price,
    double? finalPrice,
    String? organizationId,
    String? notes,
    String? employeeResponse,
    bool? isSpecificallyAssigned,
    String? specificallyAssignedOfficeBoyId,
  }) {
    return AdminOrder(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      officeBoyId: officeBoyId ?? this.officeBoyId,
      officeBoyName: officeBoyName ?? this.officeBoyName,
      items: items ?? this.items,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      price: price ?? this.price,
      finalPrice: finalPrice ?? this.finalPrice,
      organizationId: organizationId ?? this.organizationId,
      notes: notes ?? this.notes,
      employeeResponse: employeeResponse ?? this.employeeResponse,
      isSpecificallyAssigned:
          isSpecificallyAssigned ?? this.isSpecificallyAssigned,
      specificallyAssignedOfficeBoyId:
          specificallyAssignedOfficeBoyId ??
          this.specificallyAssignedOfficeBoyId,
    );
  }
}
