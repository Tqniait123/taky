import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taqy/features/employee/data/models/user_model.dart';

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

class EmployeeOrder {
  final String id;
  final String employeeId;
  final String employeeName;
  final UserRole employeeRole;
  final String officeBoyId;
  final String officeBoyName;
  final List<OrderItem> items;
  final String description;
  final OrderType type;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? price;
  final double? finalPrice;
  final String organizationId;
  final String? notes;
  final String? employeeResponse;
  final bool isSpecificallyAssigned;
  final String? specificallyAssignedOfficeBoyId;

  EmployeeOrder({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeRole, // Added to constructor
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

  String get item => items.isNotEmpty ? items.first.name : '';

  // Getter to check if order is from admin
  bool get isFromAdmin => employeeRole == UserRole.admin;

  // Getter to check if order is from organization
  bool get isFromOrganization => employeeRole == UserRole.admin;

  factory EmployeeOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<OrderItem> itemsList = [];
    if (data['items'] != null) {
      itemsList = (data['items'] as List)
          .map((item) => OrderItem.fromMap(item))
          .toList();
    } else if (data['item'] != null) {
      itemsList = [OrderItem(name: data['item'])];
    }

    // Fix role parsing - check multiple possible field names
    UserRole employeeRole;
    if (data['employeeRole'] != null) {
      employeeRole = UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['employeeRole'],
        orElse: () => UserRole.employee,
      );
    } else if (data['role'] != null) {
      employeeRole = UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.employee,
      );
    } else {
      employeeRole = UserRole.employee; // default
    }

    return EmployeeOrder(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      employeeRole: employeeRole, // Use the parsed role
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
      'employeeRole': employeeRole
          .toString()
          .split('.')
          .last, // Use consistent field name
      'officeBoyId': officeBoyId,
      'officeBoyName': officeBoyName,
      'items': items.map((item) => item.toMap()).toList(),
      'item': item,
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

  EmployeeOrder copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    UserRole? employeeRole, // Added
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
    return EmployeeOrder(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeRole: employeeRole ?? this.employeeRole, // Added
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
