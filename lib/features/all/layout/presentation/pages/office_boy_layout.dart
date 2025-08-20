import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/services/firebase_service.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';

// User Model
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
      return Colors.blue;
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
      return Colors.amber;
    }
  }
}

// MAIN OFFICE BOY LAYOUT
class OfficeBoyLayout extends StatefulWidget {
  const OfficeBoyLayout({super.key});

  @override
  State<OfficeBoyLayout> createState() => _OfficeBoyLayoutState();
}

class _OfficeBoyLayoutState extends State<OfficeBoyLayout>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  UserModel? currentUser;
  Organization? organization;
  List<Order> myOrders = [];
  List<Order> availableOrders = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

      // Load orders
      _loadOrders();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _loadOrders() {
    FirebaseFirestore.instance
        .collection('orders')
        .where('organizationId', isEqualTo: currentUser!.organizationId)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                final allOrders = snapshot.docs
                    .map((doc) => Order.fromFirestore(doc))
                    .toList();

                // My orders (assigned to me)
                myOrders =
                    allOrders
                        .where((order) => order.officeBoyId == currentUser!.id)
                        .toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                // Available orders (pending and not assigned to me)
                availableOrders =
                    allOrders
                        .where(
                          (order) =>
                              order.status == OrderStatus.pending &&
                              order.officeBoyId != currentUser!.id,
                        )
                        .toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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

  Future<void> _acceptOrder(Order order) async {
    try {
      final updatedOrder = order.copyWith(
        status: OrderStatus.inProgress,
        officeBoyId: currentUser!.id,
        officeBoyName: currentUser!.name,
      );

      await _firebaseService.updateDocument(
        'orders',
        order.id,
        updatedOrder.toFirestore(),
      );

      _showSuccessToast('Order accepted successfully!');
    } catch (e) {
      _showErrorToast('Failed to accept order: $e');
    }
  }

  // Replace your existing _updateOrderStatus method with this enhanced version:
  Future<void> _updateOrderWithNotes(
    Order order,
    OrderStatus status, {
    double? finalPrice,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (status == OrderStatus.completed) {
        updateData['completedAt'] = Timestamp.fromDate(DateTime.now());
        if (finalPrice != null && order.type == OrderType.external) {
          updateData['price'] = finalPrice;
        }
      }

      if (notes != null && notes.isNotEmpty) {
        updateData['notes'] = notes;
      }

      await _firebaseService.updateDocument('orders', order.id, updateData);
      _showSuccessToast('Order ${status.toString().split('.').last}!');
    } catch (e) {
      _showErrorToast('Failed to update order: $e');
    }
  }

  // Add these new dialog methods:
  void _showStatusChangeDialog(Order order, OrderStatus newStatus) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${newStatus.toString().split('.').last.toUpperCase()} Order',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${newStatus.toString().split('.').last} this order?',
            ),
            SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Add notes (optional)',
                hintText:
                    'Reason for ${newStatus.toString().split('.').last}...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateOrderWithNotes(
                order,
                newStatus,
                notes: notesController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == OrderStatus.cancelled
                  ? Colors.red
                  : Colors.green,
            ),
            child: Text(
              newStatus.toString().split('.').last.toUpperCase(),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(Order order) {
    final TextEditingController priceController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    if (order.price != null) {
      priceController.text = order.price!.toStringAsFixed(0);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Complete Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mark this order as completed?'),
              SizedBox(height: 16),

              if (order.type == OrderType.external) ...[
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Final Price (EGP) *',
                    hintText: 'Enter the actual price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                SizedBox(height: 12),
              ],

              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Completion notes (optional)',
                  hintText: 'Any additional details...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (order.type == OrderType.external &&
                    priceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter the final price'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                double? finalPrice;
                if (order.type == OrderType.external &&
                    priceController.text.trim().isNotEmpty) {
                  try {
                    finalPrice = double.parse(priceController.text.trim());
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter a valid price'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }

                Navigator.pop(context);
                await _updateOrderWithNotes(
                  order,
                  OrderStatus.completed,
                  finalPrice: finalPrice,
                  notes: notesController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(
                'Complete Order',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatusActions(Order order) {
    if (order.status == OrderStatus.completed ||
        order.status == OrderStatus.cancelled) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (order.status == OrderStatus.pending) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showStatusChangeDialog(order, OrderStatus.cancelled),
                icon: Icon(Icons.cancel, size: 18),
                label: Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[700],
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showStatusChangeDialog(order, OrderStatus.inProgress),
                icon: Icon(Icons.time_to_leave, size: 18),
                label: Text('In-Progress'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[100],
                  foregroundColor: Colors.blue[700],
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
          if (order.status == OrderStatus.inProgress) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showStatusChangeDialog(order, OrderStatus.cancelled),
                icon: Icon(Icons.cancel, size: 18),
                label: Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[700],
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            SizedBox(width: 8),

            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _showCompletionDialog(order),
                icon: Icon(Icons.check_circle, size: 18),
                label: Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[100],
                  foregroundColor: Colors.green[700],
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfficeBoyProfileBottomSheet(
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

  void _showOrderDetailsBottomSheet(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsBottomSheet(
        order: order,
        organization: organization!,
        isOfficeBoy: true,
        onStatusUpdate: _updateOrderWithNotes,
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

  Color _getOrderTypeColor(OrderType type) {
    switch (type) {
      case OrderType.internal:
        return Colors.blue;
      case OrderType.external:
        return Colors.orange;
    }
  }

  Color _getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
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
              child: Icon(Icons.delivery_dining, color: Colors.white, size: 20),
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
                  'Hi, ${currentUser!.name}',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: organization!.primaryColorValue,
          labelColor: organization!.primaryColorValue,
          unselectedLabelColor: Colors.grey[600],
          tabs: [
            Tab(icon: Icon(Icons.pending_actions), text: 'Available'),
            Tab(icon: Icon(Icons.assignment), text: 'My Orders'),
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableOrdersTab(),
          _buildMyOrdersTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildAvailableOrdersTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.delivery_dining, color: Colors.white, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Available Orders',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Accept orders from employees',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Available',
                    availableOrders.length.toString(),
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'My Active',
                    myOrders
                        .where((o) => o.status != OrderStatus.completed)
                        .length
                        .toString(),
                    Icons.assignment,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Available Orders List
            if (availableOrders.isEmpty)
              _buildEmptyState('No available orders', Icons.inbox)
            else
              ...availableOrders.map(
                (order) => _buildAvailableOrderCard(order),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyOrdersTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Summary
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'In Progress',
                    myOrders
                        .where((o) => o.status == OrderStatus.inProgress)
                        .length
                        .toString(),
                    Icons.hourglass_empty,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
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
              ],
            ),
            SizedBox(height: 24),

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
              _buildEmptyState('No orders assigned', Icons.assignment)
            else
              ...myOrders.map(
                (order) => Column(
                  children: [
                    _buildQuickStatusActions(order),
                    SizedBox(height: 16),
                    _buildMyOrderCard(order),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    final totalOrders = myOrders.length;
    final completedOrders = myOrders
        .where((o) => o.status == OrderStatus.completed)
        .length;
    final inProgressOrders = myOrders
        .where((o) => o.status == OrderStatus.inProgress)
        .length;
    final todayOrders = myOrders
        .where(
          (o) =>
              o.createdAt.day == DateTime.now().day &&
              o.createdAt.month == DateTime.now().month &&
              o.createdAt.year == DateTime.now().year,
        )
        .length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .9,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  'Total Orders',
                  totalOrders.toString(),
                  Icons.receipt_long,
                  organization!.primaryColorValue,
                ),
                _buildStatCard(
                  'Today\'s Orders',
                  todayOrders.toString(),
                  Icons.today,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Completed',
                  completedOrders.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'In Progress',
                  inProgressOrders.toString(),
                  Icons.hourglass_empty,
                  Colors.orange,
                ),
              ],
            ),

            SizedBox(height: 24),

            // Performance Card
            Container(
              padding: EdgeInsets.all(20),
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
                children: [
                  Text(
                    'Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Completion Rate'),
                      Text(
                        totalOrders > 0
                            ? '${((completedOrders / totalOrders) * 100).toStringAsFixed(1)}%'
                            : '0%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableOrderCard(Order order) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getOrderTypeColor(order.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.type == OrderType.internal
                            ? 'Internal'
                            : 'External',
                        style: TextStyle(
                          color: _getOrderTypeColor(order.type),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Spacer(),
                    Text(
                      _formatTime(order.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 12),

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
                        order.type == OrderType.internal
                            ? Icons.home
                            : Icons.store,
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
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                order.employeeName,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              if (order.price != null) ...[
                                Spacer(),
                                Text(
                                  'EGP ${order.price!.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _acceptOrder(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: organization!.primaryColorValue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                padding: EdgeInsets.all(16),
              ),
              child: Text(
                'Accept Order',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyOrderCard(Order order) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () => _showOrderDetailsBottomSheet(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getOrderStatusColor(
                        order.status,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        color: _getOrderStatusColor(order.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getOrderTypeColor(order.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.type == OrderType.internal
                          ? 'Internal'
                          : 'External',
                      style: TextStyle(
                        color: _getOrderTypeColor(order.type),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    _formatTime(order.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              SizedBox(height: 12),

              Row(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: _getOrderStatusColor(
                        order.status,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      order.status == OrderStatus.completed
                          ? Icons.check_circle
                          : order.type == OrderType.internal
                          ? Icons.home
                          : Icons.store,
                      color: _getOrderStatusColor(order.status),
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
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              order.employeeName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            if (order.price != null) ...[
                              Spacer(),
                              Text(
                                'EGP ${order.price!.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
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
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// OFFICE BOY PROFILE BOTTOM SHEET
class OfficeBoyProfileBottomSheet extends StatefulWidget {
  final UserModel user;
  final Organization organization;
  final VoidCallback onLogout;
  final Function(UserModel) onProfileUpdated;

  const OfficeBoyProfileBottomSheet({
    super.key,
    required this.user,
    required this.organization,
    required this.onLogout,
    required this.onProfileUpdated,
  });

  @override
  State<OfficeBoyProfileBottomSheet> createState() =>
      _OfficeBoyProfileBottomSheetState();
}

class _OfficeBoyProfileBottomSheetState
    extends State<OfficeBoyProfileBottomSheet> {
  final FirebaseService _firebaseService = FirebaseService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _phoneController.text = widget.user.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorToast('Name cannot be empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firebaseService.updateDocument(
        'users',
        widget.user.id,
        updateData,
      );

      // Get updated user data
      final userDoc = await _firebaseService.getDocument(
        'users',
        widget.user.id,
      );
      final updatedUser = UserModel.fromFirestore(userDoc);

      widget.onProfileUpdated(updatedUser);

      setState(() => _isEditing = false);
      _showSuccessToast('Profile updated successfully');
    } catch (e) {
      _showErrorToast('Failed to update profile: $e');
    } finally {
      setState(() => _isLoading = false);
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (_isEditing)
                  TextButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: Text('Cancel'),
                  )
                else
                  TextButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: Icon(Icons.edit),
                    label: Text('Edit'),
                  ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Profile Picture
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.organization.primaryColorValue,
                          widget.organization.secondaryColorValue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.user.name.isNotEmpty
                            ? widget.user.name[0].toUpperCase()
                            : 'O',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // User Info Cards
                  _buildInfoCard(
                    'Name',
                    _isEditing ? null : widget.user.name,
                    Icons.person,
                    controller: _isEditing ? _nameController : null,
                  ),

                  _buildInfoCard(
                    'Email',
                    widget.user.email,
                    Icons.email,
                    readOnly: true,
                  ),

                  _buildInfoCard(
                    'Phone',
                    _isEditing ? null : (widget.user.phone ?? 'Not provided'),
                    Icons.phone,
                    controller: _isEditing ? _phoneController : null,
                  ),

                  _buildInfoCard(
                    'Role',
                    'Office Boy',
                    Icons.badge,
                    readOnly: true,
                  ),

                  _buildInfoCard(
                    'Organization',
                    widget.organization.name,
                    Icons.business,
                    readOnly: true,
                  ),

                  SizedBox(height: 24),

                  // Action Buttons
                  if (_isEditing) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              widget.organization.primaryColorValue,
                          padding: EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showLogoutDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.all(16),
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

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String? value,
    IconData icon, {
    TextEditingController? controller,
    bool readOnly = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.organization.primaryColorValue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: widget.organization.primaryColorValue,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                if (controller != null)
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  )
                else
                  Text(
                    value ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: readOnly ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ORDER DETAILS BOTTOM SHEET
class OrderDetailsBottomSheet extends StatefulWidget {
  final Order order;
  final Organization organization;
  final bool isOfficeBoy;
  final Function(Order, OrderStatus, {double? finalPrice}) onStatusUpdate;

  const OrderDetailsBottomSheet({
    super.key,
    required this.order,
    required this.organization,
    required this.isOfficeBoy,
    required this.onStatusUpdate,
  });

  @override
  State<OrderDetailsBottomSheet> createState() =>
      _OrderDetailsBottomSheetState();
}

class _OrderDetailsBottomSheetState extends State<OrderDetailsBottomSheet> {
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.order.price != null) {
      _priceController.text = widget.order.price!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Color _getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  // Color _getOrderTypeColor(OrderType type) {
  //   switch (type) {
  //     case OrderType.internal:
  //       return Colors.blue;
  //     case OrderType.external:
  //       return Colors.orange;
  //   }
  // }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateStatus(OrderStatus status) async {
    if (status == OrderStatus.completed &&
        widget.order.type == OrderType.external &&
        _priceController.text.trim().isEmpty) {
      _showErrorToast('Please enter the final price for external orders');
      return;
    }

    setState(() => _isLoading = true);

    try {
      double? finalPrice;
      if (status == OrderStatus.completed &&
          widget.order.type == OrderType.external &&
          _priceController.text.trim().isNotEmpty) {
        finalPrice = double.parse(_priceController.text.trim());
      }

      await widget.onStatusUpdate(widget.order, status, finalPrice: finalPrice);
      Navigator.pop(context);
    } catch (e) {
      _showErrorToast('Failed to update order status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Order Details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(
                      widget.order.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.order.status
                        .toString()
                        .split('.')
                        .last
                        .toUpperCase(),
                    style: TextStyle(
                      color: _getOrderStatusColor(widget.order.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Info Card
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.organization.primaryColorValue,
                          widget.organization.secondaryColorValue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.order.type == OrderType.internal
                                    ? Icons.home
                                    : Icons.store,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.order.item,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.order.type == OrderType.internal
                                        ? 'Internal Order'
                                        : 'External Order',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (widget.order.description.isNotEmpty) ...[
                          SizedBox(height: 16),
                          Text(
                            'Description',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.order.description,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Details
                  _buildDetailRow(
                    'Employee',
                    widget.order.employeeName,
                    Icons.person,
                  ),
                  if (widget.order.officeBoyName.isNotEmpty)
                    _buildDetailRow(
                      'Office Boy',
                      widget.order.officeBoyName,
                      Icons.delivery_dining,
                    ),
                  _buildDetailRow(
                    'Created',
                    _formatDateTime(widget.order.createdAt),
                    Icons.schedule,
                  ),
                  if (widget.order.completedAt != null)
                    _buildDetailRow(
                      'Completed',
                      _formatDateTime(widget.order.completedAt!),
                      Icons.check_circle,
                    ),

                  if (widget.order.price != null ||
                      widget.order.type == OrderType.external) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Price: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.green[700],
                            ),
                          ),
                          if (widget.order.status == OrderStatus.inProgress &&
                              widget.order.type == OrderType.external &&
                              widget.isOfficeBoy)
                            Expanded(
                              child: TextField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter final price',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            )
                          else
                            Text(
                              widget.order.price != null
                                  ? 'EGP ${widget.order.price!.toStringAsFixed(0)}'
                                  : 'To be determined',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                                fontSize: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  if (widget.order.notes != null &&
                      widget.order.notes!.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.order.notes!,
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 32),

                  // Action Buttons
                  if (widget.isOfficeBoy &&
                      widget.order.status == OrderStatus.inProgress) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _updateStatus(OrderStatus.cancelled),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _updateStatus(OrderStatus.completed),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                : Text(
                                    'Mark as Completed',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.organization.primaryColorValue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: widget.organization.primaryColorValue,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
