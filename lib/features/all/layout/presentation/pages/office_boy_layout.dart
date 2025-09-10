import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/services/firebase_service.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/office_boy/data/models/office_order.dart';
import 'package:taqy/features/office_boy/data/models/office_organization.dart';
import 'package:taqy/features/office_boy/data/models/office_user_model.dart';
import 'package:taqy/features/office_boy/presentation/widgets/office_profile.dart';
import 'package:taqy/features/office_boy/presentation/widgets/order_details.dart';

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

  OfficeUserModel? currentUser;
  OfficeOrganization? organization;
  List<OfficeOrder> myOrders = [];
  List<OfficeOrder> availableOrders = [];
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
        currentUser = OfficeUserModel.fromFirestore(userDoc);
      });

      // Load organization data
      final orgDoc = await _firebaseService.getDocument(
        'organizations',
        currentUser!.organizationId,
      );
      if (orgDoc.exists) {
        setState(() {
          organization = OfficeOrganization.fromFirestore(orgDoc);
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
                    .map((doc) => OfficeOrder.fromFirestore(doc))
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

  Future<void> _acceptOrder(OfficeOrder order) async {
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
    OfficeOrder order,
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
  void _showStatusChangeDialog(OfficeOrder order, OrderStatus newStatus) {
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

  void _showCompletionDialog(OfficeOrder order) {
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

  Widget _buildQuickStatusActions(OfficeOrder order) {
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

  void _showOrderDetailsBottomSheet(OfficeOrder order) {
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
  final cancelledOrders = myOrders
      .where((o) => o.status == OrderStatus.cancelled)
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
            childAspectRatio: 1.1,
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
              _buildStatCard(
                'Cancelled',
                cancelledOrders.toString(),
                Icons.cancel,
                Colors.red,
              ),
              _buildStatCard(
                'Available',
                availableOrders.length.toString(),
                Icons.pending_actions,
                Colors.purple,
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
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cancellation Rate'),
                    Text(
                      totalOrders > 0
                          ? '${((cancelledOrders / totalOrders) * 100).toStringAsFixed(1)}%'
                          : '0%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Order Status Breakdown
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Status Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                _buildStatusRow('Completed', completedOrders, totalOrders, Colors.green),
                _buildStatusRow('In Progress', inProgressOrders, totalOrders, Colors.orange),
                _buildStatusRow('Cancelled', cancelledOrders, totalOrders, Colors.red),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildStatusRow(String label, int count, int total, Color color) {
  final percentage = total > 0 ? (count / total) * 100 : 0.0;
  
  return Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: total > 0 ? count / total : 0,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    ),
  );
}

  Widget _buildAvailableOrderCard(OfficeOrder order) {
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

  Widget _buildMyOrderCard(OfficeOrder order) {
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

