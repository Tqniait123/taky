import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/services/firebase_service.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/features/admin/data/models/app_user.dart';
import 'package:taqy/features/admin/data/models/order.dart';
import 'package:taqy/features/admin/data/models/organization.dart';
import 'package:taqy/features/admin/presentation/widgets/admin_settings_bottom_sheet.dart';
import 'package:taqy/features/admin/presentation/widgets/order_card.dart';
import 'package:taqy/features/admin/presentation/widgets/stat_card.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();

  Organization? organization;
  List<Order> orders = [];
  List<AppUser> employees = [];
  List<AppUser> officeBoys = [];
  bool isLoading = true;
  String? errorMessage;
  OrderStatus? selectedFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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

      final userDoc = await _firebaseService.getDocument('users', user.uid);
      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final organizationId = userData['organizationId'] as String;

      final orgDoc = await _firebaseService.getDocument(
        'organizations',
        organizationId,
      );
      if (orgDoc.exists) {
        setState(() {
          organization = Organization.fromFirestore(orgDoc);
        });
      }

      _loadOrders(organizationId);
      _loadUsers(organizationId);
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _loadOrders(String organizationId) {
    _firebaseService
        .streamOrganizationDocuments('orders', organizationId)
        .listen(
          (snapshot) {
            setState(() {
              orders = snapshot.docs
                  .map((doc) => Order.fromFirestore(doc))
                  .toList();
              isLoading = false;
            });
          },
          onError: (error) {
            setState(() {
              errorMessage = error.toString();
              isLoading = false;
            });
          },
        );
  }

  void _loadUsers(String organizationId) {
    _firebaseService
        .streamOrganizationDocuments('users', organizationId)
        .listen(
          (snapshot) {
            final users = snapshot.docs
                .map((doc) => AppUser.fromFirestore(doc))
                .toList();

            setState(() {
              employees = users
                  .where((user) => user.role == UserRole.employee)
                  .toList();
              officeBoys = users
                  .where((user) => user.role == UserRole.officeBoy)
                  .toList();
            });
          },
          onError: (error) {
            setState(() {
              errorMessage = error.toString();
            });
          },
        );
  }

  void _handleLogout(BuildContext context) async {
    await context.read<AuthCubit>().signOut();
    if (context.mounted) {
      Navigator.pop(context);
      context.go(Routes.login);
    }
  }

  void _showSettingsBottomSheet(BuildContext context) {
    if (organization == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (buildContext) => AdminSettingsBottomSheet(
        organization: organization!,
        onSettingsUpdated: (updatedOrg) async {
          try {
            await _firebaseService.updateDocument(
              'organizations',
              organization!.id,
              updatedOrg.toFirestore(),
            );

            setState(() {
              organization = updatedOrg;
            });

            showSuccessToast(context, 'Settings updated successfully!');
          } catch (e) {
            showErrorToast(context, 'Failed to update settings: $e');
          }
        },
        onLogout: () => _handleLogout(context),
      ),
    );
  }

  List<Order> get filteredOrders {
    if (selectedFilter == null) return orders;
    return orders.where((order) => order.status == selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: organization?.primaryColorValue ?? AppColors.primary,
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              SizedBox(height: 16),
              Text(
                'Error loading data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(errorMessage!),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (organization == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Organization not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
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
                    color: AppColors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.onSurface),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.onSurface),
            onPressed: () => _showSettingsBottomSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: organization!.primaryColorValue,
          labelColor: organization!.primaryColorValue,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          isScrollable: true,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Orders'),
            Tab(text: 'Employees'),
            Tab(text: 'Office Boys'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildOrdersTab(),
          _buildEmployeesTab(),
          _buildOfficeBoysTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildEmployeesTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Employees',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    '${employees.length} total employees',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: organization!.primaryColorValue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${employees.where((e) => e.isActive).length} Active',
                  style: TextStyle(
                    color: organization!.primaryColorValue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: employees.isEmpty
                ? _buildEmptyState('No employees found', Icons.people)
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(employees[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfficeBoysTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Office Boys',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    '${officeBoys.length} total office boys',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: organization!.secondaryColorValue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${officeBoys.where((o) => o.isActive).length} Active',
                  style: TextStyle(
                    color: organization!.secondaryColorValue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: officeBoys.isEmpty
                ? _buildEmptyState(
                    'No office boys found',
                    Icons.delivery_dining,
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: officeBoys.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(officeBoys[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(AppUser user) {
    final userOrders = orders
        .where(
          (order) =>
              order.employeeId == user.id || order.officeBoyId == user.id,
        )
        .length;

    final completedOrders = orders
        .where(
          (order) =>
              (order.employeeId == user.id || order.officeBoyId == user.id) &&
              order.status == OrderStatus.completed,
        )
        .length;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
        border: !user.isActive
            ? Border.all(color: AppColors.error.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: user.role == UserRole.employee
                    ? [
                        organization!.primaryColorValue,
                        organization!.secondaryColorValue,
                      ]
                    : [
                        organization!.secondaryColorValue,
                        organization!.primaryColorValue,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: user.profilePictureUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      user.profilePictureUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        user.role == UserRole.employee
                            ? Icons.person
                            : Icons.delivery_dining,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  )
                : Icon(
                    user.role == UserRole.employee
                        ? Icons.person
                        : Icons.delivery_dining,
                    color: Colors.white,
                    size: 30,
                  ),
          ),
          SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: !user.isActive
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface,
                        ),
                      ),
                    ),
                    if (!user.isActive)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Inactive',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        user.email,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      user.phone,
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (user.department != null) ...[
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.business_center,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      SizedBox(width: 4),
                      Text(
                        user.department!,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          Column(
            children: [
              Text(
                '$userOrders',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: user.role == UserRole.employee
                      ? organization!.primaryColorValue
                      : organization!.secondaryColorValue,
                ),
              ),
              Text(
                user.role == UserRole.employee ? 'Orders' : 'Deliveries',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '$completedOrders completed',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final totalOrders = orders.length;
    final pendingOrders = orders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final completedOrders = orders
        .where((o) => o.status == OrderStatus.completed)
        .length;
    final internalOrders = orders
        .where((o) => o.type == OrderType.internal)
        .length;
    final externalOrders = orders
        .where((o) => o.type == OrderType.external)
        .length;
    final todayOrders = orders
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
              'Quick Stats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  title: 'Total Orders',
                  value: totalOrders.toString(),
                  icon: Icons.receipt_long,
                  color: organization!.primaryColorValue,
                ),
                StatCard(
                  title: 'Today\'s Orders',
                  value: todayOrders.toString(),
                  icon: Icons.today,
                  color: Colors.blue,
                ),
                StatCard(
                  title: 'Employees',
                  value: employees.length.toString(),
                  icon: Icons.people,
                  color: organization!.primaryColorValue,
                ),
                StatCard(
                  title: 'Office Boys',
                  value: officeBoys.length.toString(),
                  icon: Icons.delivery_dining,
                  color: organization!.secondaryColorValue,
                ),
                StatCard(
                  title: 'Internal Orders',
                  value: internalOrders.toString(),
                  icon: Icons.coffee,
                  color: Colors.brown,
                ),
                StatCard(
                  title: 'External Orders',
                  value: externalOrders.toString(),
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
                StatCard(
                  title: 'Pending',
                  value: pendingOrders.toString(),
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
                StatCard(
                  title: 'Completed',
                  value: completedOrders.toString(),
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
              ],
            ),

            SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 16),

            if (orders.isEmpty)
              _buildEmptyState('No orders yet', Icons.receipt_long)
            else
              ...orders
                  .take(5)
                  .map(
                    (order) =>
                        OrderCard(order: order, organization: organization!),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Orders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', selectedFilter == null),
                    _buildFilterChip(
                      'Pending',
                      selectedFilter == OrderStatus.pending,
                    ),
                    _buildFilterChip(
                      'In Progress',
                      selectedFilter == OrderStatus.inProgress,
                    ),
                    _buildFilterChip(
                      'Completed',
                      selectedFilter == OrderStatus.completed,
                    ),
                    _buildFilterChip(
                      'Cancelled',
                      selectedFilter == OrderStatus.cancelled,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: filteredOrders.isEmpty
                ? _buildEmptyState('No orders found', Icons.search_off)
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildDetailedOrderCard(filteredOrders[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final totalRevenue = orders
        .where((o) => o.price != null && o.status == OrderStatus.completed)
        .fold(0.0, (sum, order) => sum + order.price!);

    final mostActiveEmployee = _getMostActiveEmployee();
    final mostActiveOfficeBoy = _getMostActiveOfficeBoy();
    final popularItem = _getPopularItem();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: 16),

            _buildAnalyticsCard(
              'Most Active Employee',
              mostActiveEmployee['name'] ?? 'N/A',
              '${mostActiveEmployee['count']} orders',
              Icons.person_pin,
              organization!.primaryColorValue,
            ),
            SizedBox(height: 12),
            _buildAnalyticsCard(
              'Most Active Office Boy',
              mostActiveOfficeBoy['name'] ?? 'N/A',
              '${mostActiveOfficeBoy['count']} deliveries',
              Icons.delivery_dining,
              organization!.secondaryColorValue,
            ),
            SizedBox(height: 12),
            _buildAnalyticsCard(
              'Popular Item',
              popularItem['item'] ?? 'N/A',
              'Ordered ${popularItem['count']} times',
              Icons.local_cafe,
              Colors.brown,
            ),
            SizedBox(height: 12),
            _buildAnalyticsCard(
              'Total Revenue',
              'EGP ${totalRevenue.toStringAsFixed(0)}',
              'From external orders',
              Icons.attach_money,
              AppColors.success,
            ),

            SizedBox(height: 24),

            Text(
              'Team Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: 16),
            _buildTeamPerformance(),

            SizedBox(height: 24),

            Text(
              'Order Status Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: 16),
            _buildStatusDistribution(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamPerformance() {
    return Container(
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
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${employees.where((e) => e.isActive).length}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: organization!.primaryColorValue,
                      ),
                    ),
                    Text(
                      'Active Employees',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.outline),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${officeBoys.where((o) => o.isActive).length}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: organization!.secondaryColorValue,
                      ),
                    ),
                    Text(
                      'Active Office Boys',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(color: AppColors.outline),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      (employees.isEmpty ? 0 : orders.length / employees.length)
                          .toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'Avg Orders/Employee',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      (officeBoys.isEmpty
                              ? 0
                              : orders.length / officeBoys.length)
                          .toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'Avg Deliveries/Office Boy',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
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
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedOrderCard(Order order) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
              Text(
                'Order #${order.id.substring(0, 8)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.onSurface,
                ),
              ),
              _buildStatusChip(order.status),
            ],
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Icon(
                order.type == OrderType.internal ? Icons.home : Icons.store,
                color: _getOrderTypeColor(order.type),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.item,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (order.description.isNotEmpty)
                      Text(
                        order.description,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              if (order.price != null)
                Text(
                  'EGP ${order.price!.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: AppColors.onSurfaceVariant,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.employeeName,
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.delivery_dining,
                      color: AppColors.onSurfaceVariant,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.officeBoyName,
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppColors.onSurfaceVariant,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                _formatTime(order.createdAt),
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                SizedBox(width: 16),
                Icon(Icons.note, color: AppColors.onSurfaceVariant, size: 16),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.notes!,
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool value) {
          setState(() {
            if (label == 'All') {
              selectedFilter = null;
            } else if (label == 'Pending') {
              selectedFilter = value ? OrderStatus.pending : null;
            } else if (label == 'In Progress') {
              selectedFilter = value ? OrderStatus.inProgress : null;
            } else if (label == 'Completed') {
              selectedFilter = value ? OrderStatus.completed : null;
            } else if (label == 'Cancelled') {
              selectedFilter = value ? OrderStatus.cancelled : null;
            }
          });
        },
        selectedColor: organization!.primaryColorValue.withOpacity(0.2),
        checkmarkColor: organization!.primaryColorValue,
        labelStyle: TextStyle(
          color: isSelected
              ? organization!.primaryColorValue
              : AppColors.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStatusDistribution() {
    final statusCounts = <OrderStatus, int>{};
    for (final status in OrderStatus.values) {
      statusCounts[status] = orders.where((o) => o.status == status).length;
    }

    return Container(
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
        children: statusCounts.entries.map((entry) {
          final percentage = orders.isEmpty
              ? 0.0
              : (entry.value / orders.length);
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(entry.key),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  entry.key.toString().split('.').last.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Spacer(),
                Text('${entry.value}'),
                SizedBox(width: 8),
                Text(
                  '(${(percentage * 100).toStringAsFixed(1)}%)',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
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

  Map<String, dynamic> _getMostActiveEmployee() {
    if (orders.isEmpty) return {'name': null, 'count': 0};

    final employeeCounts = <String, int>{};
    final employeeNames = <String, String>{};

    for (final order in orders) {
      employeeCounts[order.employeeId] =
          (employeeCounts[order.employeeId] ?? 0) + 1;
      employeeNames[order.employeeId] = order.employeeName;
    }

    final topEmployee = employeeCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return {'name': employeeNames[topEmployee.key], 'count': topEmployee.value};
  }

  Map<String, dynamic> _getMostActiveOfficeBoy() {
    if (orders.isEmpty) return {'name': null, 'count': 0};

    final officeBoysCounts = <String, int>{};
    final officeBoysNames = <String, String>{};

    for (final order in orders) {
      officeBoysCounts[order.officeBoyId] =
          (officeBoysCounts[order.officeBoyId] ?? 0) + 1;
      officeBoysNames[order.officeBoyId] = order.officeBoyName;
    }

    final topOfficeBoy = officeBoysCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return {
      'name': officeBoysNames[topOfficeBoy.key],
      'count': topOfficeBoy.value,
    };
  }

  Map<String, dynamic> _getPopularItem() {
    if (orders.isEmpty) return {'item': null, 'count': 0};

    final itemCounts = <String, int>{};

    for (final order in orders) {
      itemCounts[order.item] = (itemCounts[order.item] ?? 0) + 1;
    }

    final topItem = itemCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return {'item': topItem.key, 'count': topItem.value};
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
        color = AppColors.success;
        text = 'Completed';
        break;
      case OrderStatus.cancelled:
        color = AppColors.error;
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
}
