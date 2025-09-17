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
import 'package:taqy/features/admin/presentation/widgets/stat_card.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/all/splash/presentation/pages/splash.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final FirebaseService _firebaseService = FirebaseService();

  AdminOrganization? organization;
  List<AdminOrder> orders = [];
  List<AdminAppUser> employees = [];
  List<AdminAppUser> officeBoys = [];
  bool isLoading = true;
  String? errorMessage;
  OrderStatus? selectedFilter;

  late AnimationController _backgroundController;

  int _selectedIndex = 0;

  // For scroll animation
  double _scrollOffset = 0.0;
  bool _isHeaderCollapsed = false;
  late Animation<double> _backgroundGradient;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _backgroundGradient = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      _isHeaderCollapsed = _scrollOffset > 100;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
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
          organization = AdminOrganization.fromFirestore(orgDoc);
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
                  .map((doc) => AdminOrder.fromFirestore(doc))
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
                .map((doc) => AdminAppUser.fromFirestore(doc))
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

  List<AdminOrder> get filteredOrders {
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Stack(
            children: [
              // Main scrollable content

              // Animated header
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: _isHeaderCollapsed ? -50 : 0,
                left: 0,
                right: 0,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        organization!.primaryColorValue,
                        organization!.secondaryColorValue,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Stack(
                      children: [
                        // Left icon (refresh)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: ParticlesPainter(
                              _backgroundGradient.value,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.refresh, color: Colors.white),
                              onPressed: _loadData,
                            ),
                          ),
                        ),

                        // Right icon (settings)
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.settings, color: Colors.white),
                              onPressed: () =>
                                  _showSettingsBottomSheet(context),
                            ),
                          ),
                        ),

                        // Center logo and text
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo container
                              Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: organization!.logoUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Image.network(
                                          organization!.logoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.business,
                                                    color: Colors.white,
                                                    size: 40,
                                                  ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.business,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                              ),
                              const SizedBox(height: 16),

                              // Organization name
                              Text(
                                organization!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Subtitle
                              Text(
                                'Admin Dashboard',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),

                              _buildNavigationBar(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  // Header space
                  SizedBox(height: MediaQuery.of(context).size.height * 0.42),
                  // Tab content area
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Tab bar container
                        SizedBox(height: 16),
                        // Tab content
                        _buildSelectedContent(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildNavigationBar() {
  //   final navItems = [
  //     {'title': 'Overview', 'icon': Icons.dashboard},
  //     {'title': 'Orders', 'icon': Icons.receipt_long},
  //     {'title': 'Employees', 'icon': Icons.people},
  //     {'title': 'Office Boys', 'icon': Icons.delivery_dining},
  //   ];

  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     child: Row(
  //       children: navItems.asMap().entries.map((entry) {
  //         final index = entry.key;
  //         final item = entry.value;
  //         final isSelected = _selectedIndex == index;

  //         return GestureDetector(
  //           onTap: () => setState(() => _selectedIndex = index),
  //           child: AnimatedContainer(
  //             duration: Duration(milliseconds: 200),
  //             margin: EdgeInsets.only(right: 12),
  //             padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  //             decoration: BoxDecoration(
  //               color: isSelected
  //                   ? organization!.primaryColorValue
  //                   : Colors.grey.shade100,
  //               borderRadius: BorderRadius.circular(25),
  //               border: isSelected
  //                   ? Border.all(color: Colors.grey[300]!, width: 2)
  //                   : null,
  //               boxShadow: isSelected
  //                   ? [
  //                       BoxShadow(
  //                         color: organization!.primaryColorValue.withOpacity(
  //                           0.3,
  //                         ),
  //                         blurRadius: 8,
  //                         offset: Offset(0, 2),
  //                       ),
  //                     ]
  //                   : null,
  //             ),
  //             child: Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Icon(
  //                   item['icon'] as IconData,
  //                   color: isSelected
  //                       ? Colors.white
  //                       : AppColors.onSurfaceVariant,
  //                   size: 20,
  //                 ),
  //                 SizedBox(width: 8),
  //                 Text(
  //                   item['title'] as String,
  //                   style: TextStyle(
  //                     color: isSelected
  //                         ? Colors.white
  //                         : AppColors.onSurfaceVariant,
  //                     fontWeight: isSelected
  //                         ? FontWeight.w600
  //                         : FontWeight.normal,
  //                     fontSize: 14,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       }).toList(),
  //     ),
  //   );
  // }

  Widget _buildNavigationBar() {
    final navItems = [
      {'title': 'Overview', 'icon': Icons.dashboard_outlined},
      {'title': 'Orders', 'icon': Icons.receipt_long_outlined},
      {'title': 'Employees', 'icon': Icons.people_outline},
      {'title': 'Office Boys', 'icon': Icons.delivery_dining_outlined},
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.glassStroke, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: navItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = _selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                margin: EdgeInsets.all(2),
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.accentGradient : null,
                  borderRadius: BorderRadius.circular(20),
                  // boxShadow: isSelected ? [
                  //   BoxShadow(
                  //     color: AppColors.secondary.withOpacity(0.3),
                  //     blurRadius: 12,
                  //     offset: Offset(0, 4),
                  //   ),
                  // ] : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    SizedBox(height: 4),
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildOrdersTab();
      case 2:
        return _buildEmployeesTab();
      case 3:
        return _buildOfficeBoysTab();
      default:
        return _buildOverviewTab();
    }
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

        employees.isEmpty
            ? _buildEmptyState('No employees found', Icons.people)
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: employees.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildUserCard(employees[index]);
                },
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

        officeBoys.isEmpty
            ? _buildEmptyState('No office boys found', Icons.delivery_dining)
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: officeBoys.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildUserCard(officeBoys[index]);
                },
              ),
      ],
    );
  }

  Widget _buildUserCard(AdminAppUser user) {
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
            color: Colors.black.withOpacity(0.09),
            blurRadius: 10,
            offset: Offset(0, 0),
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
            crossAxisAlignment: CrossAxisAlignment.end,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.8,
            shrinkWrap: true,
            padding: EdgeInsets.all(0),
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
              StatCard(
                title: 'Cancelled',
                value: orders
                    .where((o) => o.status == OrderStatus.cancelled)
                    .length
                    .toString(),
                icon: Icons.cancel,
                color: AppColors.error,
              ),
            ],
          ),

          SizedBox(height: 24),
        ],
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

        filteredOrders.isEmpty
            ? _buildEmptyState('No orders found', Icons.search_off)
            : ListView.builder(
                padding: EdgeInsets.all(16),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  return _buildDetailedOrderCard(filteredOrders[index]);
                },
              ),
      ],
    );
  }

  Widget _buildDetailedOrderCard(AdminOrder order) {
    // Calculate display price (finalPrice if available, otherwise price)
    final displayPrice = order.finalPrice ?? order.price;
    final hasPriceChange =
        order.finalPrice != null &&
        order.price != null &&
        order.finalPrice != order.price;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 10,
            offset: Offset(0, 0),
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

          // Display items (support multiple items)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    order.type == OrderType.internal ? Icons.home : Icons.store,
                    color: _getOrderTypeColor(order.type),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Items (${order.items.length}):',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (displayPrice != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (hasPriceChange) ...[
                          Text(
                            'EGP ${order.price!.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            'EGP ${order.finalPrice!.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ] else
                          Text(
                            'EGP ${displayPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              SizedBox(height: 8),

              // Display each item with its status
              ...order.items.map(
                (item) => Padding(
                  padding: EdgeInsets.only(left: 28, bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getItemStatusColor(item.status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: item.status == ItemStatus.notAvailable
                                ? AppColors.onSurfaceVariant
                                : AppColors.onSurface,
                            decoration: item.status == ItemStatus.notAvailable
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (item.notes != null && item.notes!.isNotEmpty)
                        Text(
                          item.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (order.description.isNotEmpty) ...[
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 28),
                  child: Text(
                    order.description,
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
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

          // Show employee response if available
          if (order.employeeResponse != null &&
              order.employeeResponse!.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Employee Response: ${order.employeeResponse}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getItemStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.pending:
        return Colors.orange;
      case ItemStatus.available:
        return AppColors.success;
      case ItemStatus.notAvailable:
        return AppColors.error;
    }
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        side: BorderSide(
          color: isSelected
              ? organization!.primaryColorValue
              : Colors.grey[300]!,
        ),
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
        backgroundColor: Colors.white,

        labelStyle: TextStyle(
          color: isSelected
              ? organization!.primaryColorValue
              : AppColors.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  //

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
      case OrderStatus.needsResponse:
        color = Colors.purple;
        text = 'Need Response';
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
