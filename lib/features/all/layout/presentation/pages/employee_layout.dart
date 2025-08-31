import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/services/firebase_service.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';

// User Model (based on your provided structure)
enum UserRole { admin, employee, officeBoy }

class UserModel {
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

  UserModel({
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

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
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

// Order models
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

  Order copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? officeBoyId,
    String? officeBoyName,
    String? item,
    String? description,
    OrderType? type,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    double? price,
    String? organizationId,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      officeBoyId: officeBoyId ?? this.officeBoyId,
      officeBoyName: officeBoyName ?? this.officeBoyName,
      item: item ?? this.item,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      price: price ?? this.price,
      organizationId: organizationId ?? this.organizationId,
      notes: notes ?? this.notes,
    );
  }
}

class Organization {
  final String id;
  final String name;
  final String code;
  final String? logoUrl;
  final String primaryColor;
  final String secondaryColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Organization({
    required this.id,
    required this.name,
    required this.code,
    this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory Organization.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Organization(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      logoUrl: data['logoUrl'],
      primaryColor: data['primaryColor'] ?? '#2196F3',
      secondaryColor: data['secondaryColor'] ?? '#FFC107',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Color get primaryColorValue {
    try {
      String colorString = primaryColor;
      if (colorString.startsWith('#')) {
        colorString = colorString.substring(1);
      }
      if (colorString.length == 6) {
        return Color(int.parse('FF$colorString', radix: 16));
      }
      if (colorString.length == 8) {
        return Color(int.parse(colorString, radix: 16));
      }
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.blue; // Fallback color
    }
  }

  Color get secondaryColorValue {
    try {
      String colorString = secondaryColor;
      if (colorString.startsWith('#')) {
        colorString = colorString.substring(1);
      }
      if (colorString.length == 6) {
        return Color(int.parse('FF$colorString', radix: 16));
      }
      if (colorString.length == 8) {
        return Color(int.parse(colorString, radix: 16));
      }
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.amber; // Fallback color
    }
  }
}

class EmployeeLayout extends StatefulWidget {
  const EmployeeLayout({super.key});

  @override
  State<EmployeeLayout> createState() => _EmployeeLayoutState();
}

class _EmployeeLayoutState extends State<EmployeeLayout> {
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? currentUser;
  Organization? organization;
  List<Order> myOrders = [];
  List<UserModel> officeBoys = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final user = _firebaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current user data
      final userDoc = await _firebaseService.getDocument('users', user.uid);
      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      setState(() {
        currentUser = UserModel.fromFirestore(userDoc);
      });

      // Load organization data
      final orgDoc = await _firebaseService.getDocument(
        'organizations',
        currentUser!.organizationId,
      );
      if (orgDoc.exists) {
        setState(() {
          organization = Organization.fromFirestore(orgDoc);
        });
      }

      // Load office boys from the same organization
      await _loadOfficeBoys();

      // Load user's orders
      _loadMyOrders();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadOfficeBoys() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('organizationId', isEqualTo: currentUser!.organizationId)
          .where('role', isEqualTo: 'officeBoy')
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        officeBoys = querySnapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error loading office boys: $e');
    }
  }

  void _loadMyOrders() {
    FirebaseFirestore.instance
        .collection('orders')
        .where('organizationId', isEqualTo: currentUser!.organizationId)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                // Filter and sort in memory
                myOrders =
                    snapshot.docs
                        .map((doc) => Order.fromFirestore(doc))
                        .where(
                          (order) => order.employeeId == currentUser!.id,
                        ) // Filter by employee
                        .toList()
                      ..sort(
                        (a, b) => b.createdAt.compareTo(a.createdAt),
                      ); // Sort newest first
                isLoading = false;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                errorMessage = error.toString();
                isLoading = false;
              });
            }
          },
        );
  }

  void _showNewOrderBottomSheet() {
    if (officeBoys.isEmpty) {
      _showErrorToast('No office boys available. Please contact admin.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NewOrderBottomSheet(
        employee: currentUser!,
        organization: organization!,
        officeBoys: officeBoys,
        onOrderCreated: (order) async {
          try {
            await _firebaseService.addDocument('orders', order.toFirestore());
            _showSuccessToast('Order placed successfully!');
          } catch (e) {
            _showErrorToast('Failed to place order: $e');
          }
        },
      ),
    );
  }

  void _showEditOrderBottomSheet(Order order) {
    if (order.status != OrderStatus.pending) {
      _showErrorToast('Only pending orders can be edited.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditOrderBottomSheet(
        order: order,
        organization: organization!,
        officeBoys: officeBoys,
        onOrderUpdated: (updatedOrder) async {
          try {
            await _firebaseService.updateDocument(
              'orders',
              updatedOrder.id,
              updatedOrder.toFirestore(),
            );
            _showSuccessToast('Order updated successfully!');
          } catch (e) {
            _showErrorToast('Failed to update order: $e');
          }
        },
        onOrderDeleted: (orderId) async {
          try {
            await _firebaseService.deleteDocument('orders', orderId);
            _showSuccessToast('Order deleted successfully!');
          } catch (e) {
            _showErrorToast('Failed to delete order: $e');
          }
        },
      ),
    );
  }

  void _showProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileBottomSheet(
        user: currentUser!,
        organization: organization!,
        onLogout: () => _handleLogout(),
        onProfileUpdated: (updatedUser) {
          setState(() {
            currentUser = updatedUser;
          });
        },
      ),
    );
  }

  void _handleLogout() async {
    try {
      await context.read<AuthCubit>().signOut();
      if (mounted) {
        context.go(Routes.login);
      }
    } catch (e) {
      _showErrorToast('Failed to logout: $e');
    }
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: CircularProgressIndicator(
            color: organization?.primaryColorValue ?? Colors.blue,
          ),
        ),
      );
    }

    if (errorMessage != null || currentUser == null || organization == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(errorMessage ?? 'Unknown error'),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    organization!.primaryColorValue,
                    organization!.secondaryColorValue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: organization!.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        organization!.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.business, color: Colors.white, size: 20),
                      ),
                    )
                  : Icon(Icons.business, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organization!.name,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Welcome, ${currentUser!.name}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Icon(Icons.person, color: Colors.black87),
            onPressed: _showProfileBottomSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Actions Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      organization!.primaryColorValue,
                      organization!.secondaryColorValue,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: organization!.primaryColorValue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Place a New Order',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Order internal items like tea or external food',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showNewOrderBottomSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: organization!.primaryColorValue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'New Order',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Order Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Orders',
                      myOrders.length.toString(),
                      Icons.receipt_long,
                      organization!.primaryColorValue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Pending',
                      myOrders
                          .where((o) => o.status == OrderStatus.pending)
                          .length
                          .toString(),
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Completed',
                      myOrders
                          .where((o) => o.status == OrderStatus.completed)
                          .length
                          .toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Today\'s Orders',
                      myOrders
                          .where(
                            (o) =>
                                o.createdAt.day == DateTime.now().day &&
                                o.createdAt.month == DateTime.now().month &&
                                o.createdAt.year == DateTime.now().year,
                          )
                          .length
                          .toString(),
                      Icons.today,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // My Orders
              Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),

              if (myOrders.isEmpty)
                _buildEmptyState('No orders yet', Icons.receipt_long)
              else
                ...myOrders.map((order) => _buildOrderCard(order)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.substring(0, 8)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Row(
                children: [
                  _buildStatusChip(order.status),
                  if (order.status == OrderStatus.pending) ...[
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showEditOrderBottomSheet(order),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.edit, size: 16, color: Colors.blue),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: _getOrderTypeColor(order.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  order.type == OrderType.internal ? Icons.home : Icons.store,
                  color: _getOrderTypeColor(order.type),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.item,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (order.description.isNotEmpty)
                      Text(
                        order.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Row(
                      children: [
                        Icon(
                          Icons.delivery_dining,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          order.officeBoyName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Spacer(),
                        if (order.price != null)
                          Text(
                            'EGP ${order.price!.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _formatTime(order.createdAt),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String text;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case OrderStatus.inProgress:
        color = Colors.blue;
        text = 'In Progress';
        break;
      case OrderStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getOrderTypeColor(OrderType type) {
    return type == OrderType.internal
        ? organization!.secondaryColorValue
        : organization!.primaryColorValue;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Edit Order Bottom Sheet
class EditOrderBottomSheet extends StatefulWidget {
  final Order order;
  final Organization organization;
  final List<UserModel> officeBoys;
  final Function(Order) onOrderUpdated;
  final Function(String) onOrderDeleted;

  const EditOrderBottomSheet({
    super.key,
    required this.order,
    required this.organization,
    required this.officeBoys,
    required this.onOrderUpdated,
    required this.onOrderDeleted,
  });

  @override
  State<EditOrderBottomSheet> createState() => _EditOrderBottomSheetState();
}

class _EditOrderBottomSheetState extends State<EditOrderBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  late OrderType _selectedType;
  UserModel? _selectedOfficeBoy;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  // Predefined items
  final Map<OrderType, List<String>> _predefinedItems = {
    OrderType.internal: [
      'Tea',
      'Coffee',
      'Water',
      'Juice',
      'Snacks',
      'Biscuits',
      'Other',
    ],
    OrderType.external: [
      'Breakfast',
      'Lunch',
      'Dinner',
      'Fast Food',
      'Dessert',
      'Drinks',
      'Other',
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _itemController.text = widget.order.item;
    _descriptionController.text = widget.order.description;
    _priceController.text = widget.order.price?.toString() ?? '';
    _notesController.text = widget.order.notes ?? '';
    _selectedType = widget.order.type;
    _selectedOfficeBoy = widget.officeBoys.firstWhere(
      (officeBoy) => officeBoy.id == widget.order.officeBoyId,
      // orElse: () => widget.officeBoys.isNotEmpty ? widget.officeBoys.first : null,
    );
  }

  @override
  void dispose() {
    _itemController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Order',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Order #${widget.order.id.substring(0, 8)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Type Selection
                    Text(
                      'Order Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeCard(
                            'Internal',
                            'Tea, Coffee, Water',
                            Icons.home,
                            OrderType.internal,
                            widget.organization.secondaryColorValue,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeCard(
                            'External',
                            'Food, Meals, Delivery',
                            Icons.store,
                            OrderType.external,
                            widget.organization.primaryColorValue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Item Selection
                    Text(
                      'What would you like to order?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),

                    // Predefined Items Grid
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _predefinedItems[_selectedType]!.map((item) {
                        final isSelected = _itemController.text == item;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _itemController.text = item;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? widget.organization.primaryColorValue
                                        .withOpacity(0.1)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? widget.organization.primaryColorValue
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              item,
                              style: TextStyle(
                                color: isSelected
                                    ? widget.organization.primaryColorValue
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),

                    // Custom Item Input
                    TextFormField(
                      controller: _itemController,
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        hintText: 'Enter custom item or select above',
                        prefixIcon: Icon(
                          _selectedType == OrderType.internal
                              ? Icons.local_cafe
                              : Icons.restaurant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.organization.primaryColorValue,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an item name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Any specific details or preferences...',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.organization.primaryColorValue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Price (for external orders)
                    if (_selectedType == OrderType.external) ...[
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Estimated Price (EGP)',
                          hintText: 'Enter estimated price',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: widget.organization.primaryColorValue,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (_selectedType == OrderType.external &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Please enter estimated price for external orders';
                          }
                          if (value != null && value.isNotEmpty) {
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Please enter a valid price';
                            }
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                    ],

                    // Office Boy Selection
                    Text(
                      'Select Office Boy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<UserModel>(
                        value: _selectedOfficeBoy,
                        isExpanded: true,
                        underline: SizedBox(),
                        icon: Icon(Icons.arrow_drop_down),
                        items: widget.officeBoys.map((officeBoy) {
                          return DropdownMenuItem<UserModel>(
                            value: officeBoy,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: widget
                                      .organization
                                      .primaryColorValue
                                      .withOpacity(0.1),
                                  backgroundImage:
                                      officeBoy.profileImageUrl != null
                                      ? NetworkImage(officeBoy.profileImageUrl!)
                                      : null,
                                  child: officeBoy.profileImageUrl == null
                                      ? Icon(
                                          Icons.delivery_dining,
                                          color: widget
                                              .organization
                                              .primaryColorValue,
                                          size: 16,
                                        )
                                      : null,
                                ),
                                SizedBox(width: 12),
                                Text(officeBoy.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (UserModel? newValue) {
                          setState(() {
                            _selectedOfficeBoy = newValue;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 20),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        hintText: 'Any special instructions...',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.organization.primaryColorValue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                children: [
                  // Update Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || _isDeleting
                          ? null
                          : _updateOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.organization.primaryColorValue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isSubmitting ? 'Updating...' : 'Update Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Delete Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || _isDeleting
                          ? null
                          : _showDeleteConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isDeleting ? 'Deleting...' : 'Delete Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    String title,
    String subtitle,
    IconData icon,
    OrderType type,
    Color color,
  ) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          // Clear price if changing from external to internal
          if (type == OrderType.internal) {
            _priceController.clear();
          }
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(isSelected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _updateOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedOfficeBoy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an office boy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final updatedOrder = widget.order.copyWith(
        item: _itemController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        officeBoyId: _selectedOfficeBoy!.id,
        officeBoyName: _selectedOfficeBoy!.name,
        price: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      widget.onOrderUpdated(updatedOrder);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Order'),
        content: Text(
          'Are you sure you want to delete this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOrder();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteOrder() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      widget.onOrderDeleted(widget.order.id);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }
}

// New Order Bottom Sheet
class NewOrderBottomSheet extends StatefulWidget {
  final UserModel employee;
  final Organization organization;
  final List<UserModel> officeBoys;
  final Function(Order) onOrderCreated;

  const NewOrderBottomSheet({
    super.key,
    required this.employee,
    required this.organization,
    required this.officeBoys,
    required this.onOrderCreated,
  });

  @override
  State<NewOrderBottomSheet> createState() => _NewOrderBottomSheetState();
}

class _NewOrderBottomSheetState extends State<NewOrderBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  OrderType _selectedType = OrderType.internal;
  UserModel? _selectedOfficeBoy;
  bool _isSubmitting = false;

  // Predefined items
  final Map<OrderType, List<String>> _predefinedItems = {
    OrderType.internal: [
      'Tea',
      'Coffee',
      'Water',
      'Juice',
      'Snacks',
      'Biscuits',
      'Other',
    ],
    OrderType.external: [
      'Breakfast',
      'Lunch',
      'Dinner',
      'Fast Food',
      'Dessert',
      'Drinks',
      'Other',
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedOfficeBoy = widget.officeBoys.isNotEmpty
        ? widget.officeBoys.first
        : null;
  }

  @override
  void dispose() {
    _itemController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    'New Order',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Type Selection
                    Text(
                      'Order Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeCard(
                            'Internal',
                            'Tea, Coffee, Water',
                            Icons.home,
                            OrderType.internal,
                            widget.organization.secondaryColorValue,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeCard(
                            'External',
                            'Food, Meals, Delivery',
                            Icons.store,
                            OrderType.external,
                            widget.organization.primaryColorValue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Item Selection
                    Text(
                      'What would you like to order?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),

                    // Predefined Items Grid
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _predefinedItems[_selectedType]!.map((item) {
                        final isSelected = _itemController.text == item;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _itemController.text = item;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? widget.organization.primaryColorValue
                                        .withOpacity(0.1)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? widget.organization.primaryColorValue
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              item,
                              style: TextStyle(
                                color: isSelected
                                    ? widget.organization.primaryColorValue
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),

                    // Custom Item Input
                    TextFormField(
                      controller: _itemController,
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        hintText: 'Enter custom item or select above',
                        prefixIcon: Icon(
                          _selectedType == OrderType.internal
                              ? Icons.local_cafe
                              : Icons.restaurant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.organization.primaryColorValue,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an item name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Any specific details or preferences...',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.organization.primaryColorValue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Price (for external orders)
                    if (_selectedType == OrderType.external) ...[
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Estimated Price (EGP)',
                          hintText: 'Enter estimated price',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: widget.organization.primaryColorValue,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (_selectedType == OrderType.external &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Please enter estimated price for external orders';
                          }
                          if (value != null && value.isNotEmpty) {
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Please enter a valid price';
                            }
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                    ],

                    // Office Boy Selection
                    Text(
                      'Select Office Boy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<UserModel>(
                        value: _selectedOfficeBoy,
                        isExpanded: true,
                        underline: SizedBox(),
                        icon: Icon(Icons.arrow_drop_down),
                        items: widget.officeBoys.map((officeBoy) {
                          return DropdownMenuItem<UserModel>(
                            value: officeBoy,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: widget
                                      .organization
                                      .primaryColorValue
                                      .withOpacity(0.1),
                                  backgroundImage:
                                      officeBoy.profileImageUrl != null
                                      ? NetworkImage(officeBoy.profileImageUrl!)
                                      : null,
                                  child: officeBoy.profileImageUrl == null
                                      ? Icon(
                                          Icons.delivery_dining,
                                          color: widget
                                              .organization
                                              .primaryColorValue,
                                          size: 16,
                                        )
                                      : null,
                                ),
                                SizedBox(width: 12),
                                Text(officeBoy.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (UserModel? newValue) {
                          setState(() {
                            _selectedOfficeBoy = newValue;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 20),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        hintText: 'Any special instructions...',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.organization.primaryColorValue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Action
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.organization.primaryColorValue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isSubmitting ? 'Placing Order...' : 'Place Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    String title,
    String subtitle,
    IconData icon,
    OrderType type,
    Color color,
  ) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _itemController.clear(); // Clear item when changing type
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(isSelected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedOfficeBoy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an office boy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final order = Order(
        id: '', // Will be set by Firestore
        employeeId: widget.employee.id,
        employeeName: widget.employee.name,
        officeBoyId: _selectedOfficeBoy!.id,
        officeBoyName: _selectedOfficeBoy!.name,
        item: _itemController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        price: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
        organizationId: widget.organization.id,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      widget.onOrderCreated(order);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

// Profile Bottom Sheet
class ProfileBottomSheet extends StatefulWidget {
  final UserModel user;
  final Organization organization;
  final VoidCallback onLogout;
  final Function(UserModel) onProfileUpdated;

  const ProfileBottomSheet({
    super.key,
    required this.user,
    required this.organization,
    required this.onLogout,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends State<ProfileBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  PlatformFile? _profileImageFile;
  bool _isSaving = false;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Profile Image
                  Center(
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(
                            color: widget.organization.primaryColorValue,
                            width: 2,
                          ),
                        ),
                        child: _profileImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(58),
                                child: Image.file(
                                  File(_profileImageFile!.path!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : widget.user.profileImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(58),
                                child: Image.network(
                                  widget.user.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.person,
                                        color: widget
                                            .organization
                                            .primaryColorValue,
                                        size: 40,
                                      ),
                                ),
                              )
                            : Icon(
                                Icons.add_photo_alternate,
                                size: 40,
                                color: widget.organization.primaryColorValue,
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to change photo',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 32),

                  // User Info Card
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.email, color: Colors.grey[600]),
                            SizedBox(width: 12),
                            Text(
                              widget.user.email,
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.badge, color: Colors.grey[600]),
                            SizedBox(width: 12),
                            Text(
                              'Employee ID: ${widget.user.id.substring(0, 8)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.business, color: Colors.grey[600]),
                            SizedBox(width: 12),
                            Text(
                              widget.organization.name,
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Editable Fields
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Bottom Actions
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // Update Profile Button
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.organization.primaryColorValue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isSaving ? 'Saving...' : 'Update Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),

                // Logout Button
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            Navigator.pop(context);
                            _showLogoutConfirmation();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.organization.primaryColorValue,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  void _pickProfileImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File size must be less than 5MB'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        setState(() {
          _profileImageFile = file;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? profileImageUrl = widget.user.profileImageUrl;

      // Upload new profile image if selected
      if (_profileImageFile != null) {
        profileImageUrl = await _firebaseService.uploadProfileImage(
          widget.user.id,
          _profileImageFile!.path!,
        );
      }

      // Update user data
      final updatedData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'profileImageUrl': profileImageUrl,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firebaseService.updateDocument(
        'users',
        widget.user.id,
        updatedData,
      );

      // Create updated user model
      final updatedUser = UserModel(
        id: widget.user.id,
        email: widget.user.email,
        passwordHash: widget.user.passwordHash,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        role: widget.user.role,
        organizationId: widget.user.organizationId,
        locale: widget.user.locale,
        profileImageUrl: profileImageUrl,
        isActive: widget.user.isActive,
        isVerified: widget.user.isVerified,
        fcmToken: widget.user.fcmToken,
        createdAt: widget.user.createdAt,
        updatedAt: DateTime.now(),
      );

      widget.onProfileUpdated(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
