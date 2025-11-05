import 'dart:developer';
import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/helpers/cache_helper.dart';
import 'package:taqy/core/services/firebase_service.dart';
import 'package:taqy/core/static/app_assets.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/employee/data/models/order_model.dart';
import 'package:taqy/features/employee/data/models/organization_model.dart';
import 'package:taqy/features/employee/data/models/user_model.dart';
import 'package:taqy/features/employee/presentation/widgets/edit_order_bottom_sheet.dart';
import 'package:taqy/features/employee/presentation/widgets/new_order_bottom_sheet.dart';
import 'package:taqy/features/employee/presentation/widgets/profile_bottom_sheet.dart';
import 'package:taqy/features/employee/presentation/widgets/response_bottom_sheet.dart';

enum HistoryFilter { all, completed, cancelled, none }

HistoryFilter _currentHistoryFilter = HistoryFilter.all;

class EmployeeLayout extends StatefulWidget {
  const EmployeeLayout({super.key});

  @override
  State<EmployeeLayout> createState() => _EmployeeLayoutState();
}

class _EmployeeLayoutState extends State<EmployeeLayout>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();

  EmployeeUserModel? currentUser;
  EmployeeOrganization? organization;
  // List<EmployeeOrder> myOrders = [];
  List<EmployeeOrder> todayOrders = [];
  List<EmployeeOrder> historyOrders = [];
  List<EmployeeUserModel> officeBoys = [];
  bool isLoading = true;
  String? errorMessage;

  // Animation Controllers
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _backgroundGradient;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _shimmerAnimation;

  int _selectedIndex = 0;
  double _scrollOffset = 0.0;
  bool _isHeaderCollapsed = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeAnimations();
    _loadData();
    _loadSavedColors();
  }

  void _initializeAnimations() {
    // Background animation controller
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _backgroundGradient = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Pulse animation for active elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slide animation for content
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Rotation animation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Shimmer effect
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Start continuous animations
    _backgroundController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _shimmerController.repeat();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      _isHeaderCollapsed = _scrollOffset > 100;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _backgroundController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Start entrance animations
      _slideController.reset();
      _fadeController.reset();
      _scaleController.reset();

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
        currentUser = EmployeeUserModel.fromFirestore(userDoc);
      });

      // Load organization data
      final orgDoc = await _firebaseService.getDocument(
        'organizations',
        currentUser!.organizationId,
      );
      if (orgDoc.exists) {
        setState(() {
          organization = EmployeeOrganization.fromFirestore(orgDoc);
        });

        ColorManager().updateColors(
          organization!.primaryColorValue,
          organization!.secondaryColorValue,
        );
      }

      // Load office boys from the same organization
      await _loadOfficeBoys();

      // Load user's orders
      _loadMyOrders();

      // Trigger entrance animations
      _slideController.forward();
      _fadeController.forward();
      _scaleController.forward();
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
            .map((doc) => EmployeeUserModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      log('Error loading office boys: $e');
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
              final allOrders =
                  snapshot.docs
                      .map((doc) => EmployeeOrder.fromFirestore(doc))
                      .where((order) => order.employeeId == currentUser!.id)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              setState(() {
                // Today's orders (all statuses)
                todayOrders = allOrders.where((order) {
                  final orderDate = DateTime(
                    order.createdAt.year,
                    order.createdAt.month,
                    order.createdAt.day,
                  );
                  return orderDate.isAtSameMomentAs(today);
                }).toList();

                // History orders: past orders + today's cancelled/completed orders
                historyOrders = allOrders.where((order) {
                  final orderDate = DateTime(
                    order.createdAt.year,
                    order.createdAt.month,
                    order.createdAt.day,
                  );

                  // Include past orders (before today)
                  if (orderDate.isBefore(today)) {
                    return true;
                  }

                  // Include today's orders that are cancelled or completed
                  if (orderDate.isAtSameMomentAs(today)) {
                    return order.status == OrderStatus.cancelled ||
                        order.status == OrderStatus.completed;
                  }

                  return false;
                }).toList();

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

  Future<void> _loadSavedColors() async {
    final savedPrimaryColor =
        await SharedPreferencesService.getOrganizationPrimaryColor();
    final savedSecondaryColor =
        await SharedPreferencesService.getOrganizationSecondaryColor();

    if (savedPrimaryColor != null && savedSecondaryColor != null && mounted) {
      setState(() {});
    }
  }

  void _showNewOrderBottomSheet() {
    if (officeBoys.isEmpty) {
      showErrorToast(
        context,
        'No office boys available. Please contact admin.',
      );
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
            showSuccessToast(context, 'Order placed successfully!');
          } catch (e) {
            showErrorToast(context, 'Failed to place order: $e');
          }
        },
      ),
    );
  }

  void _showEditOrderBottomSheet(EmployeeOrder order) {
    if (order.status != OrderStatus.pending &&
        order.status != OrderStatus.needsResponse) {
      showErrorToast(
        context,
        'Only pending orders or orders needing response can be edited.',
      );
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

            // Show appropriate message based on original status
            if (order.status == OrderStatus.needsResponse) {
              showSuccessToast(
                context,
                'Changes submitted! Order sent back for processing.',
              );
            } else {
              showSuccessToast(context, 'Order updated successfully!');
            }
          } catch (e) {
            showErrorToast(context, 'Failed to update order: $e');
          }
        },
        onOrderDeleted: (orderId) async {
          try {
            await _firebaseService.deleteDocument('orders', orderId);
            showSuccessToast(context, 'Order deleted successfully!');
          } catch (e) {
            showErrorToast(context, 'Failed to delete order: $e');
          }
        },
      ),
    );
  }

  void _showResponseBottomSheet(EmployeeOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderResponseBottomSheet(
        order: order,
        organization: organization!,
        onResponse: (orderId, response, newStatus) async {
          try {
            final updateData = <String, dynamic>{
              'status': newStatus.toString().split('.').last,
              'employeeResponse': response,
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            };

            await _firebaseService.updateDocument(
              'orders',
              orderId,
              updateData,
            );
            showSuccessToast(
              context,
              newStatus == OrderStatus.cancelled
                  ? 'Order cancelled successfully!'
                  : 'Order updated successfully!',
            );
          } catch (e) {
            showErrorToast(context, 'Failed to update order: $e');
          }
        },
        onEditRequested: (order, unavailableItems, response) {
          Navigator.pop(context);

          _showEditOrderBottomSheet(order);
        },
      ),
    );
  }

  void _showProfileBottomSheet() {
    // Create a custom page route for smooth animation
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ProfileBottomSheet(
            user: currentUser!,
            organization: organization!,
            onLogout: () => _handleLogout(),
            onProfileUpdated: (updatedUser) {
              setState(() {
                currentUser = updatedUser;
              });
            },
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide up animation
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          // Scale animation for backdrop
          var scaleAnimation = Tween<double>(
            begin: 0.9,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          // Fade animation for backdrop
          var fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return Stack(
            children: [
              // Animated backdrop
              FadeTransition(
                opacity: fadeAnimation,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),

              // Animated bottom sheet
              SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
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
      showErrorToast(context, 'Failed to logout: $e');
    }
  }

  Widget _buildAnimatedHeader() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            organization?.primaryColorValue ?? AppColors.primary,
            organization?.secondaryColorValue ?? AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Animated particles background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) => CustomPaint(
                  painter: AnimatedParticlesPainter(
                    _backgroundGradient.value,
                    _rotationAnimation.value,
                  ),
                ),
              ),
            ),
            if (currentUser?.role == UserRole.employee)
              Positioned(
                top: 20,
                left: 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) => Transform.scale(
                            scale: _pulseAnimation.value,
                            child: SvgPicture.asset(
                              Assets.imagesSvgsNotification,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        onPressed: _loadData,
                      ),
                    ),
                  ),
                ),
              ),
            if (currentUser?.role == UserRole.admin)
              Positioned(
                top: 20,
                right: 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) => Transform.scale(
                            scale: _pulseAnimation.value,
                            child: SvgPicture.asset(
                              Assets.imagesSvgsNotification,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        onPressed: _loadData,
                      ),
                    ),
                  ),
                ),
              ),
            // Animated top icons
            if (currentUser?.role == UserRole.employee)
              Positioned(
                top: 20,
                right: 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) => Transform.rotate(
                            angle: _rotationAnimation.value * 0.1,
                            child: SvgPicture.asset(
                              Assets.imagesSvgsSetting,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        onPressed: _showProfileBottomSheet,
                      ),
                    ),
                  ),
                ),
              ),

            // Animated center content
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 1200),
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated logo
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: organization?.logoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.network(
                                      organization!.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Center(
                                                child: SvgPicture.asset(
                                                  Assets.imagesSvgsUser,
                                                  height: 45,
                                                  width: 45,
                                                  color: Colors.white,
                                                ),
                                              ),
                                    ),
                                  )
                                : Center(
                                    child: SvgPicture.asset(
                                      Assets.imagesSvgsUser,
                                      height: 45,
                                      width: 45,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 50.0, end: 0.0),
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) => Transform.translate(
                          offset: Offset(0, value),
                          child: Text(
                            currentUser?.role == UserRole.admin
                                ? 'Welcome, Boss!'
                                : 'Welcome, ${currentUser?.name ?? ''}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      _buildAnimatedNavigationBar(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedNavigationBar() {
    final navItems = [
      {'title': 'Today\'s Orders', 'icon': Assets.imagesSvgsCalendar},
      {'title': 'History', 'icon': Assets.imagesSvgsClock},
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1400),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Container(
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
                  onTap: () {
                    setState(() => _selectedIndex = index);

                    _slideController.forward();
                    _fadeController.forward();
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    margin: EdgeInsets.all(2),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                Colors.white.withOpacity(.1),
                                Colors.white.withOpacity(.2),
                                Colors.white.withOpacity(.3),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: isSelected ? 1.2 : 1.0,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          child: navItems[index]['icon'] is String
                              ? SvgPicture.asset(
                                  item['icon'] as String,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                                )
                              : Icon(
                                  item['icon'] as IconData,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                                ),
                        ),
                        SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 300),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.7),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 11,
                          ),
                          child: Text(item['title'] as String),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedOrderCard(EmployeeOrder order, int index) {
    final needsResponse = order.status == OrderStatus.needsResponse;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(50 * (1 - value), 0),
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: needsResponse
                ? Border.all(color: organization!.secondaryColorValue, width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: needsResponse
                    ? organization!.secondaryColorValue.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
            image: DecorationImage(
              image: AssetImage(AppImages.homePattern),
              fit: BoxFit.fill,
              colorFilter: ColorFilter.mode(
                organization!.secondaryColorValue.withOpacity(.5),
                BlendMode.modulate,
              ),
            ),
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
                      color: Colors.grey[700],
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
                              color: organization!.secondaryColorValue
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SvgPicture.asset(
                              Assets.imagesSvgsEdit,
                              color: organization!.primaryColorValue,
                              height: 16,
                              width: 16,
                            ),
                          ),
                        ),
                      ],
                      if (needsResponse) ...[
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showResponseBottomSheet(order),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.reply_rounded,
                              size: 16,
                              color: Colors.purple,
                            ),
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
                      color: organization!.secondaryColorValue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) => Transform.rotate(
                        angle: _rotationAnimation.value * 0.05,
                        child: SvgPicture.asset(
                          needsResponse
                              ? Assets.imagesSvgsOrder
                              : order.type == OrderType.internal
                              ? Assets.imagesSvgsCompany
                              : Assets.imagesSvgsShoppingCart,
                          color: organization!.primaryColorValue,
                          fit: BoxFit.scaleDown,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.items.length == 1
                              ? order.items.first.name
                              : '${order.items.length} Items Order',
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
                              Icons.delivery_dining_rounded,
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
                            if (order.price != null ||
                                order.finalPrice != null) ...[
                              Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (order.price != null)
                                    Text(
                                      'Budget: EGP ${order.price!.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    ),
                                  if (order.finalPrice != null)
                                    Text(
                                      'Spent: EGP ${order.finalPrice!.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color:
                                            organization!.secondaryColorValue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Show availability summary for orders needing response
              if (needsResponse && order.items.isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: organization!.secondaryColorValue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: organization!.secondaryColorValue.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: organization!.secondaryColorValue
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SvgPicture.asset(
                              Assets.imagesSvgsInfo,
                              color: organization!.primaryColorValue,
                              height: 16,
                              width: 16,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Item Availability Update',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: organization!.primaryColorValue,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ...order.items
                          .take(2)
                          .map(
                            (item) => Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(4),

                                    decoration: BoxDecoration(
                                      color: item.status == ItemStatus.available
                                          ? Colors.green.withOpacity(.2)
                                          : item.status ==
                                                ItemStatus.notAvailable
                                          ? Colors.red.withOpacity(.2)
                                          : Colors.orange.withOpacity(.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SvgPicture.asset(
                                      item.status == ItemStatus.available
                                          ? Assets.imagesSvgsComplete
                                          : item.status ==
                                                ItemStatus.notAvailable
                                          ? Assets.imagesSvgsCancell
                                          : Assets.imagesSvgsPending,
                                      height: 14,
                                      width: 14,
                                      color: item.status == ItemStatus.available
                                          ? Colors.green
                                          : item.status ==
                                                ItemStatus.notAvailable
                                          ? Colors.red
                                          : Colors.orange,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${item.name} - ${item.status == ItemStatus.available
                                          ? "Available"
                                          : item.status == ItemStatus.notAvailable
                                          ? "Not Available"
                                          : "Checking"}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (order.items.length > 2)
                        Text(
                          '... and ${order.items.length - 2} more items',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showResponseBottomSheet(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: organization!.secondaryColorValue,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Respond Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  SizedBox(width: 8),
                  Text(
                    _formatTime(order.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      case OrderStatus.needsResponse:
        color = Colors.purple;
        text = 'Need Response';
        break;
    }

    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: AnimatedDefaultTextStyle(
            duration: Duration(milliseconds: 200),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedEmptyState(String message, IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Center(
        child: Column(
          children: [
            Text(message, style: TextStyle(fontSize: 16, color: Colors.grey)),
            Lottie.asset(
              'assets/images/lottie/Package Delivery.json',
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
              height: icon == Icons.history ? value * 200 : value * 400,
              width: icon == Icons.history ? value * 200 : value * 400,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime).abs();

    if (difference.inMinutes < 60) {
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
        backgroundColor: AppColors.background,
        body: Center(
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) => ShimmerLoading(
              shimmerAnimation: _shimmerAnimation,
              primaryColor:
                  organization?.primaryColorValue ?? AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (errorMessage != null || currentUser == null || organization == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(
            scale: value.clamp(0.1, 1.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) => Transform.scale(
                      scale: _pulseAnimation.value.clamp(0.5, 1.5),
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(errorMessage ?? 'Unknown error'),
                  SizedBox(height: 16),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: ElevatedButton(
                      onPressed: _loadData,
                      child: Text('Retry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              organization!.primaryColorValue.withOpacity(.9),
              organization!.secondaryColorValue.withOpacity(.8),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: FloatingActionButton(
          heroTag: null,
          shape: CircleBorder(side: BorderSide(color: Colors.transparent)),
          backgroundColor: Colors.transparent,
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          hoverElevation: 0,
          focusElevation: 0,
          highlightElevation: 0,
          disabledElevation: 0,
          elevation: 0,

          child: Icon(Icons.add_rounded, size: 32, color: Colors.white),
          onPressed: () {
            _showNewOrderBottomSheet();
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: organization!.primaryColorValue,
        strokeWidth: 2,
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,

        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _fadeController,
              _slideController,
              _scaleController,
            ]),
            builder: (context, child) => FadeTransition(
              opacity: AlwaysStoppedAnimation(
                _fadeAnimation.value.clamp(0.0, 1.0),
              ),
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: AlwaysStoppedAnimation(
                    _scaleAnimation.value.clamp(0.1, 1.0),
                  ),
                  child: Stack(
                    children: [
                      // Animated header
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        top: _isHeaderCollapsed ? -50 : 0,
                        left: 0,
                        right: 0,
                        child: _buildAnimatedHeader(),
                      ),
                      Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.42,
                          ),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: Offset(0, -5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: 16),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 600),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(_selectedIndex),
        child: _getSelectedContent(),
      ),
    );
  }

  Widget _getSelectedContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildAnimatedTodaysOrders();
      case 1:
        return _buildAnimatedHistoryOrders();

      default:
        return _buildAnimatedTodaysOrders();
    }
  }

  Widget _buildAnimatedHistoryOrders() {
    // Filter orders based on current filter
    List<EmployeeOrder> filteredOrders = _getFilteredHistoryOrders();

    final completedOrders = filteredOrders
        .where((order) => order.status == OrderStatus.completed)
        .toList();

    final cancelledOrders = filteredOrders
        .where((order) => order.status == OrderStatus.cancelled)
        .toList();

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnhancedHistoryHeader(completedOrders, cancelledOrders),
          SizedBox(height: 20),

          if (filteredOrders.isEmpty)
            _buildAnimatedEmptyState(_getEmptyStateMessage(), Icons.history)
          else ...[
            // Show filtered orders
            if (_currentHistoryFilter == HistoryFilter.all ||
                _currentHistoryFilter == HistoryFilter.completed) ...[
              if (completedOrders.isNotEmpty) ...[
                _buildSectionHeader(
                  'Completed Orders',
                  completedOrders.length,
                  Assets.imagesSvgsComplete,
                ),
                SizedBox(height: 12),
                ...completedOrders.asMap().entries.map(
                  (entry) =>
                      _buildDetailedHistoryCard(entry.value, entry.key, false),
                ),
                if (cancelledOrders.isNotEmpty &&
                    _currentHistoryFilter == HistoryFilter.all)
                  SizedBox(height: 24),
              ],
            ],

            if (_currentHistoryFilter == HistoryFilter.all ||
                _currentHistoryFilter == HistoryFilter.cancelled) ...[
              if (cancelledOrders.isNotEmpty) ...[
                _buildSectionHeader(
                  'Cancelled Orders',
                  cancelledOrders.length,
                  Assets.imagesSvgsCancell,
                ),
                SizedBox(height: 12),
                ...cancelledOrders.asMap().entries.map(
                  (entry) =>
                      _buildDetailedHistoryCard(entry.value, entry.key, true),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedHistoryHeader(
    List<EmployeeOrder> completedOrders,
    List<EmployeeOrder> cancelledOrders,
  ) {
    final completedCount = historyOrders
        .where((o) => o.status == OrderStatus.completed)
        .length;
    final cancelledCount = historyOrders
        .where((o) => o.status == OrderStatus.cancelled)
        .length;
    final totalOrders = completedCount + cancelledCount;
    final totalSpent = historyOrders
        .where((o) => o.status == OrderStatus.completed && o.finalPrice != null)
        .fold(0.0, (summ, order) => summ + order.finalPrice!);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => FadeTransition(
        opacity: AlwaysStoppedAnimation(value.clamp(0.0, 1.0)),
        child: Transform.translate(
          offset: Offset(0, -30 * (1 - value)),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppImages.homePattern),
                fit: BoxFit.fill,
                colorFilter: ColorFilter.mode(
                  organization!.primaryColorValue.withOpacity(.3),
                  BlendMode.modulate,
                ),
              ),
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: organization!.primaryColorValue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SvgPicture.asset(
                        Assets.imagesSvgsClock,
                        color: organization!.primaryColorValue,
                        height: 20,
                        width: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Order History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (totalSpent > 0) ...[
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildHistoryStatCard(
                              'Total Spent',
                              'EGP ${totalSpent.toStringAsFixed(0)}',
                              Colors.orange,
                              Assets.imagesSvgsMoney,
                              HistoryFilter.none,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentHistoryFilter = HistoryFilter.all;
                          });
                        },
                        child: _buildHistoryStatCard(
                          'All',
                          totalOrders.toString(),
                          organization!.primaryColorValue,
                          Assets.imagesSvgsOverview,
                          HistoryFilter.all,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentHistoryFilter = HistoryFilter.completed;
                          });
                        },
                        child: _buildHistoryStatCard(
                          'Completed',
                          completedCount.toString(),
                          AppColors.success,
                          Assets.imagesSvgsComplete,
                          HistoryFilter.completed,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentHistoryFilter = HistoryFilter.cancelled;
                          });
                        },
                        child: _buildHistoryStatCard(
                          'Cancelled',
                          cancelledCount.toString(),
                          AppColors.error,
                          Assets.imagesSvgsCancell,
                          HistoryFilter.cancelled,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<EmployeeOrder> _getFilteredHistoryOrders() {
    switch (_currentHistoryFilter) {
      case HistoryFilter.completed:
        return historyOrders
            .where((order) => order.status == OrderStatus.completed)
            .toList();
      case HistoryFilter.cancelled:
        return historyOrders
            .where((order) => order.status == OrderStatus.cancelled)
            .toList();
      case HistoryFilter.all:
        return historyOrders;
      default:
        return historyOrders;
    }
  }

  // Add this method for empty state messages
  String _getEmptyStateMessage() {
    switch (_currentHistoryFilter) {
      case HistoryFilter.completed:
        return 'No completed orders yet';
      case HistoryFilter.cancelled:
        return 'No cancelled orders';
      case HistoryFilter.all:
        return 'No order history';
      default:
        return 'No order history';
    }
  }

  Widget _buildDetailedHistoryCard(
    EmployeeOrder order,
    int index,
    bool isCancelled,
  ) {
    final displayPrice = order.finalPrice ?? order.price;
    // final isCompleted = order.status == OrderStatus.completed;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(50 * (1 - value), 0),
        child: Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCancelled
                  ? Colors.red.withOpacity(0.2)
                  : organization!.secondaryColorValue.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isCancelled
                    ? Colors.red.withOpacity(0.08)
                    : organization!.secondaryColorValue.withOpacity(0.08),
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
            image: DecorationImage(
              image: AssetImage(AppImages.homePattern),
              fit: BoxFit.fill,
              colorFilter: ColorFilter.mode(
                (isCancelled ? Colors.red : organization!.secondaryColorValue)
                    .withOpacity(.5),
                BlendMode.modulate,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and action button
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isCancelled
                                    ? Colors.red.withOpacity(0.1)
                                    : AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isCancelled ? 'CANCELLED' : 'COMPLETED',
                                style: TextStyle(
                                  color: isCancelled
                                      ? Colors.red
                                      : AppColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            SizedBox(width: 6),
                            Text(
                              _formatHistoryDate(
                                isCancelled
                                    ? order.createdAt
                                    : order.completedAt ?? order.createdAt,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action button - Reorder for both completed and cancelled orders
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCancelled
                            ? [Colors.orange, Colors.deepOrange]
                            : [
                                organization!.primaryColorValue,
                                organization!.secondaryColorValue,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isCancelled
                                      ? Colors.orange
                                      : organization!.primaryColorValue)
                                  .withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showImprovedReorderDialog(order),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                isCancelled ? 'Retry Order' : 'Reorder',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getOrderTypeColor(order.type).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getOrderTypeColor(order.type).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.all(0),
                      horizontalTitleGap: 0,
                      leading: SvgPicture.asset(
                        Assets.imagesSvgsOrder,
                        color: organization!.primaryColorValue,
                        height: 18,
                      ),
                      title: Text(
                        isCancelled ? 'Order Cancelled' : 'Items Delivered',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      subtitle: isCancelled && order.employeeResponse != null
                          ? Text(
                              'Reason: ${order.employeeResponse}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[600],
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : displayPrice != null
                          ? Text(
                              'Spent: EGP ${displayPrice.toInt()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            )
                          : null,
                      trailing: Text(
                        order.type == OrderType.internal
                            ? 'Internal'
                            : 'External',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Items display with different styling for cancelled orders
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: order.items
                          .map(
                            (item) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: item.status == ItemStatus.notAvailable
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: item.status == ItemStatus.notAvailable
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    item.status == ItemStatus.notAvailable
                                        ? Assets.imagesSvgsCancell
                                        : Assets.imagesSvgsComplete,
                                    height: 14,
                                    color:
                                        item.status == ItemStatus.notAvailable
                                        ? Colors.red[600]
                                        : Colors.green[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          item.status == ItemStatus.notAvailable
                                          ? Colors.red[700]
                                          : Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                      decoration:
                                          (item.status ==
                                              ItemStatus.notAvailable)
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Office boy info and additional details
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.delivery_dining_rounded,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          isCancelled ? 'Assigned to: ' : 'Delivered by: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            order.officeBoyName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (order.description.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Divider(height: 1, color: Colors.grey[300]),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            Assets.imagesSvgsNote,
                            color: Colors.grey[600],
                            height: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, String icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: organization!.primaryColorValue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.asset(
            icon,
            color: organization!.primaryColorValue,
            height: 18,
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryStatCard(
    String title,
    String value,
    Color color,
    String icon,
    HistoryFilter filter,
  ) {
    final isSelected = _currentHistoryFilter == filter;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Transform.scale(
              scale: _pulseAnimation.value,
              child: SvgPicture.asset(
                icon,
                color: isSelected ? Colors.white : color,
                height: 18,
              ),
            ),
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatHistoryDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Color _getOrderTypeColor(OrderType type) {
    return type == OrderType.internal
        ? organization!.secondaryColorValue
        : organization!.primaryColorValue;
  }

  void _showImprovedReorderDialog(EmployeeOrder originalOrder) {
    final TextEditingController budgetController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isLoading = false;
    final bool isCancelled = originalOrder.status == OrderStatus.cancelled;

    // For cancelled orders, include all items and allow retrying them
    // For completed orders, only show available items
    List<OrderItem> itemsToShow;
    bool allItemsUnavailable = false;
    bool hasUnavailableItems = false;

    if (isCancelled) {
      // For cancelled orders, show ALL items and allow retrying them
      itemsToShow = originalOrder.items
          .map((item) => OrderItem(name: item.name, status: ItemStatus.pending))
          .toList();
      // For cancelled orders, we don't consider items as "unavailable" since we're retrying
      allItemsUnavailable = false;
      hasUnavailableItems = false;
    } else {
      // For completed orders, filter by availability as before
      List<OrderItem> availableItems = originalOrder.items
          .where((item) => item.status != ItemStatus.notAvailable)
          .map((item) => OrderItem(name: item.name, status: ItemStatus.pending))
          .toList();

      List<OrderItem> allItems = originalOrder.items
          .map((item) => OrderItem(name: item.name, status: ItemStatus.pending))
          .toList();

      allItemsUnavailable = availableItems.isEmpty;
      hasUnavailableItems = originalOrder.items.any(
        (item) => item.status == ItemStatus.notAvailable,
      );

      itemsToShow = allItemsUnavailable ? allItems : availableItems;
    }

    List<bool> selectedItems = List.filled(itemsToShow.length, true);

    if (originalOrder.type == OrderType.external &&
        originalOrder.price != null) {
      budgetController.text = originalOrder.price!.toInt().toString();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, animationValue, child) => Transform.scale(
                scale: 0.8 + (animationValue * 0.2),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Stack(
                    children: [
                      // Animated background with particles
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                organization!.primaryColorValue.withOpacity(
                                  0.1,
                                ),
                                organization!.secondaryColorValue.withOpacity(
                                  0.1,
                                ),
                                organization!.primaryColorValue.withOpacity(
                                  0.05,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: CustomPaint(
                            painter: ParticlesPainter(
                              animationValue,
                              organization!.primaryColorValue,
                              organization!.secondaryColorValue,
                            ),
                          ),
                        ),
                      ),

                      // Glass morphism container
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.25),
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Form(
                                key: formKey,
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Animated Header
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: Duration(milliseconds: 600),
                                        curve: Curves.easeOutBack,
                                        builder: (context, value, child) => Transform.translate(
                                          offset: Offset(0, -30 * (1 - value)),
                                          child: Row(
                                            children: [
                                              // Animated icon container
                                              Container(
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  gradient: RadialGradient(
                                                    colors: [
                                                      organization!
                                                          .primaryColorValue
                                                          .withOpacity(0.3),
                                                      organization!
                                                          .primaryColorValue
                                                          .withOpacity(0.1),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          (organization!
                                                                  .primaryColorValue)
                                                              .withOpacity(0.2),
                                                      blurRadius: 10,
                                                      offset: Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.refresh_rounded,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                              SizedBox(width: 16),

                                              // Title and subtitle
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      isCancelled
                                                          ? 'Retry Order'
                                                          : 'Reorder Items',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      isCancelled
                                                          ? 'Create a new order with items from cancelled order'
                                                          : allItemsUnavailable
                                                          ? 'All items are currently unavailable, but you can retry them'
                                                          : 'Select available items to include in new order',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: 24),

                                      // Show cancellation reason if available
                                      if (isCancelled &&
                                          originalOrder.employeeResponse !=
                                              null) ...[
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          duration: Duration(milliseconds: 700),
                                          curve: Curves.easeOutBack,
                                          builder: (context, value, child) =>
                                              Transform.translate(
                                                offset: Offset(
                                                  -30 * (1 - value),
                                                  0,
                                                ),
                                                child: Container(
                                                  padding: EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.white
                                                            .withOpacity(0.2),
                                                        Colors.white
                                                            .withOpacity(0.1),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          SvgPicture.asset(
                                                            Assets
                                                                .imagesSvgsInfo,
                                                            color: Colors.white,
                                                            height: 20,
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            'Previous Cancellation Reason',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.7,
                                                                  ),
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        originalOrder
                                                            .employeeResponse!,
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(0.8),
                                                          fontSize: 13,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                        ),
                                        SizedBox(height: 20),
                                      ],

                                      // Show info notices only for non-cancelled orders
                                      if (!isCancelled) ...[
                                        if (allItemsUnavailable) ...[
                                          Container(
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.red.withOpacity(0.2),
                                                  Colors.red.withOpacity(0.1),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.red.withOpacity(
                                                  0.3,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    SvgPicture.asset(
                                                      Assets.imagesSvgsInfo,
                                                      color:
                                                          Colors.red.shade300,
                                                      height: 20,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'All Items Currently Unavailable',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white
                                                            .withOpacity(0.9),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'All items from this order are currently marked as unavailable, but you can retry them in case their availability has changed.',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.8),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                        ] else if (hasUnavailableItems) ...[
                                          Container(
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                                  Colors.orange.withOpacity(
                                                    0.1,
                                                  ),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.orange
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .warning_amber_rounded,
                                                      color: Colors.orange,
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Some Items Not Available',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white
                                                            .withOpacity(0.9),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'The following items are currently not available: ${originalOrder.items.where((item) => item.status == ItemStatus.notAvailable).map((item) => item.name).join(", ")}',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.8),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                        ],
                                      ],

                                      // Animated Items Selection Card
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: Duration(milliseconds: 800),
                                        curve: Curves.easeOutBack,
                                        builder: (context, value, child) => Transform.scale(
                                          scale: 0.9 + (value * 0.1),
                                          child: Container(
                                            padding: EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withOpacity(
                                                    0.15,
                                                  ),
                                                  Colors.white.withOpacity(
                                                    0.05,
                                                  ),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 15,
                                                  offset: Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(
                                                  sigmaX: 10,
                                                  sigmaY: 10,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            gradient: RadialGradient(
                                                              colors: [
                                                                Colors.white
                                                                    .withOpacity(
                                                                      0.2,
                                                                    ),
                                                                Colors.white
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                              ],
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                          child: SvgPicture.asset(
                                                            Assets
                                                                .imagesSvgsOrder,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.9,
                                                                ),
                                                            height: 20,
                                                          ),
                                                        ),
                                                        SizedBox(width: 12),
                                                        Expanded(
                                                          child: Text(
                                                            isCancelled
                                                                ? 'Items to retry:'
                                                                : allItemsUnavailable
                                                                ? 'Items to retry:'
                                                                : 'Available items to reorder:',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.7,
                                                                  ),
                                                              fontSize: 16,
                                                              letterSpacing:
                                                                  0.3,
                                                            ),
                                                          ),
                                                        ),
                                                        // Select/Deselect all button
                                                        Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            onTap: () {
                                                              setState(() {
                                                                bool
                                                                allSelected =
                                                                    selectedItems.every(
                                                                      (
                                                                        selected,
                                                                      ) =>
                                                                          selected,
                                                                    );
                                                                for (
                                                                  int i = 0;
                                                                  i <
                                                                      selectedItems
                                                                          .length;
                                                                  i++
                                                                ) {
                                                                  selectedItems[i] =
                                                                      !allSelected;
                                                                }
                                                              });
                                                            },
                                                            child: Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 4,
                                                                  ),
                                                              child: Text(
                                                                selectedItems.every(
                                                                      (
                                                                        selected,
                                                                      ) =>
                                                                          selected,
                                                                    )
                                                                    ? 'Deselect All'
                                                                    : 'Select All',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .red
                                                                      .shade900,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 16),

                                                    // Items chips with selection functionality
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children: itemsToShow.asMap().entries.map((
                                                        entry,
                                                      ) {
                                                        final index = entry.key;
                                                        final item =
                                                            entry.value;
                                                        final isSelected =
                                                            selectedItems[index];

                                                        return TweenAnimationBuilder<
                                                          double
                                                        >(
                                                          tween: Tween(
                                                            begin: 0.0,
                                                            end: 1.0,
                                                          ),
                                                          duration: Duration(
                                                            milliseconds:
                                                                600 +
                                                                (index * 100),
                                                          ),
                                                          curve:
                                                              Curves.elasticOut,
                                                          builder:
                                                              (
                                                                context,
                                                                chipValue,
                                                                child,
                                                              ) => Transform.scale(
                                                                scale:
                                                                    chipValue,
                                                                child: Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: InkWell(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          20,
                                                                        ),
                                                                    onTap: () {
                                                                      setState(() {
                                                                        selectedItems[index] =
                                                                            !selectedItems[index];
                                                                      });
                                                                    },
                                                                    child: AnimatedContainer(
                                                                      duration: Duration(
                                                                        milliseconds:
                                                                            300,
                                                                      ),
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            12,
                                                                        vertical:
                                                                            8,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        gradient: LinearGradient(
                                                                          colors:
                                                                              isSelected
                                                                              ? [
                                                                                  organization!.primaryColorValue.withOpacity(
                                                                                    0.3,
                                                                                  ),
                                                                                  organization!.secondaryColorValue.withOpacity(
                                                                                    0.2,
                                                                                  ),
                                                                                ]
                                                                              : [
                                                                                  Colors.grey.withOpacity(
                                                                                    0.2,
                                                                                  ),
                                                                                  Colors.grey.withOpacity(
                                                                                    0.1,
                                                                                  ),
                                                                                ],
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              20,
                                                                            ),
                                                                        border: Border.all(
                                                                          color:
                                                                              isSelected
                                                                              ? Colors.white.withOpacity(
                                                                                  0.4,
                                                                                )
                                                                              : Colors.grey.withOpacity(0.3),
                                                                          width:
                                                                              1,
                                                                        ),
                                                                        boxShadow:
                                                                            isSelected
                                                                            ? [
                                                                                BoxShadow(
                                                                                  color: organization!.primaryColorValue.withOpacity(
                                                                                    0.2,
                                                                                  ),
                                                                                  blurRadius: 5,
                                                                                  offset: Offset(
                                                                                    0,
                                                                                    2,
                                                                                  ),
                                                                                ),
                                                                              ]
                                                                            : null,
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          // Selection indicator
                                                                          AnimatedContainer(
                                                                            duration: Duration(
                                                                              milliseconds: 200,
                                                                            ),
                                                                            width:
                                                                                16,
                                                                            height:
                                                                                16,
                                                                            margin: EdgeInsets.only(
                                                                              right: 6,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                              color: isSelected
                                                                                  ? Colors.white
                                                                                  : Colors.transparent,
                                                                              border: Border.all(
                                                                                color: isSelected
                                                                                    ? Colors.transparent
                                                                                    : Colors.white.withOpacity(
                                                                                        0.5,
                                                                                      ),
                                                                                width: 1,
                                                                              ),
                                                                            ),
                                                                            child:
                                                                                isSelected
                                                                                ? Icon(
                                                                                    Icons.check,
                                                                                    size: 12,
                                                                                    color: organization!.primaryColorValue,
                                                                                  )
                                                                                : null,
                                                                          ),
                                                                          // Item name
                                                                          Text(
                                                                            item.name,
                                                                            style: TextStyle(
                                                                              fontSize: 13,
                                                                              color: isSelected
                                                                                  ? Colors.white
                                                                                  : Colors.white.withOpacity(
                                                                                      0.6,
                                                                                    ),
                                                                              fontWeight: FontWeight.w600,
                                                                              decoration: isSelected
                                                                                  ? TextDecoration.none
                                                                                  : TextDecoration.lineThrough,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                        );
                                                      }).toList(),
                                                    ),

                                                    SizedBox(height: 12),

                                                    // Selected items count
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8.0,
                                                          ),
                                                      child: Text(
                                                        isCancelled
                                                            ? '${selectedItems.where((selected) => selected).length} of ${itemsToShow.length} items selected for retry'
                                                            : allItemsUnavailable
                                                            ? '${selectedItems.where((selected) => selected).length} of ${itemsToShow.length} unavailable items selected for retry'
                                                            : '${selectedItems.where((selected) => selected).length} of ${itemsToShow.length} available items selected',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white
                                                              .withOpacity(0.7),
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                      ),
                                                    ),

                                                    // Description if exists
                                                    if (originalOrder
                                                        .description
                                                        .isNotEmpty) ...[
                                                      SizedBox(height: 16),
                                                      Container(
                                                        padding: EdgeInsets.all(
                                                          12,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              Colors.white
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                              Colors.white
                                                                  .withOpacity(
                                                                    0.05,
                                                                  ),
                                                            ],
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'Original Description: ${originalOrder.description}',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.8,
                                                                ),
                                                            fontStyle: FontStyle
                                                                .italic,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Budget input for external orders
                                      if (originalOrder.type ==
                                          OrderType.external) ...[
                                        SizedBox(height: 24),
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          duration: Duration(
                                            milliseconds: 1000,
                                          ),
                                          curve: Curves.easeOutBack,
                                          builder: (context, value, child) => Transform.translate(
                                            offset: Offset(50 * (1 - value), 0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Set Your Budget',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                SizedBox(height: 12),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.white
                                                            .withOpacity(0.15),
                                                        Colors.white
                                                            .withOpacity(0.05),
                                                      ],
                                                    ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.2),
                                                      width: 1,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        blurRadius: 15,
                                                        offset: Offset(0, 5),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    child: BackdropFilter(
                                                      filter: ImageFilter.blur(
                                                        sigmaX: 10,
                                                        sigmaY: 10,
                                                      ),
                                                      child: TextFormField(
                                                        controller:
                                                            budgetController,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        decoration: InputDecoration(
                                                          hintText:
                                                              'Enter budget amount',
                                                          hintStyle: TextStyle(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.6,
                                                                ),
                                                            fontSize: 14,
                                                          ),
                                                          prefixIcon:
                                                              SvgPicture.asset(
                                                                Assets
                                                                    .imagesSvgsMoney,
                                                                color: Colors
                                                                    .white,
                                                                fit: BoxFit
                                                                    .scaleDown,
                                                              ),
                                                          border:
                                                              InputBorder.none,
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 20,
                                                                vertical: 16,
                                                              ),
                                                        ),
                                                        validator: (value) {
                                                          if (value == null ||
                                                              value.isEmpty) {
                                                            return 'Please enter a budget amount';
                                                          }
                                                          final budget =
                                                              double.tryParse(
                                                                value,
                                                              );
                                                          if (budget == null ||
                                                              budget <= 0) {
                                                            return 'Please enter a valid amount';
                                                          }
                                                          return null;
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Previous budget: EGP ${originalOrder.price?.toInt() ?? 0}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],

                                      SizedBox(height: 32),

                                      // Action buttons
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: Duration(milliseconds: 1200),
                                        curve: Curves.elasticOut,
                                        builder: (context, value, child) => Transform.translate(
                                          offset: Offset(0, 50 * (1 - value)),
                                          child: Row(
                                            children: [
                                              // Cancel button
                                              Expanded(
                                                child: Container(
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.white
                                                            .withOpacity(0.15),
                                                        Colors.white
                                                            .withOpacity(0.05),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      onTap: isLoading
                                                          ? null
                                                          : () => Navigator.of(
                                                              context,
                                                            ).pop(),
                                                      child: Center(
                                                        child: Text(
                                                          'Cancel',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 16),

                                              // Action button with glow effect
                                              Expanded(
                                                flex: 2,
                                                child: TweenAnimationBuilder<double>(
                                                  tween: Tween(
                                                    begin: 0.0,
                                                    end: 1.0,
                                                  ),
                                                  duration: Duration(
                                                    seconds: 2,
                                                  ),
                                                  builder: (context, glowValue, child) {
                                                    int selectedCount =
                                                        selectedItems
                                                            .where(
                                                              (selected) =>
                                                                  selected,
                                                            )
                                                            .length;
                                                    bool hasSelectedItems =
                                                        selectedCount > 0;

                                                    return Container(
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors:
                                                              hasSelectedItems
                                                              ? [
                                                                  organization!
                                                                      .primaryColorValue,
                                                                  organization!
                                                                      .secondaryColorValue,
                                                                ]
                                                              : [
                                                                  Colors.grey
                                                                      .withOpacity(
                                                                        0.3,
                                                                      ),
                                                                  Colors.grey
                                                                      .withOpacity(
                                                                        0.2,
                                                                      ),
                                                                ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                        boxShadow:
                                                            hasSelectedItems
                                                            ? [
                                                                BoxShadow(
                                                                  color: (organization!.primaryColorValue)
                                                                      .withOpacity(
                                                                        0.4 +
                                                                            (glowValue *
                                                                                0.3),
                                                                      ),
                                                                  blurRadius:
                                                                      15 +
                                                                      (glowValue *
                                                                          10),
                                                                  spreadRadius:
                                                                      1,
                                                                  offset:
                                                                      Offset(
                                                                        0,
                                                                        5,
                                                                      ),
                                                                ),
                                                              ]
                                                            : null,
                                                      ),
                                                      child: Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: InkWell(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                16,
                                                              ),
                                                          onTap:
                                                              (isLoading ||
                                                                  !hasSelectedItems)
                                                              ? null
                                                              : () async {
                                                                  if (formKey
                                                                      .currentState!
                                                                      .validate()) {
                                                                    setState(
                                                                      () => isLoading =
                                                                          true,
                                                                    );
                                                                    try {
                                                                      List<
                                                                        OrderItem
                                                                      >
                                                                      selectedOrderItems =
                                                                          [];
                                                                      for (
                                                                        int i =
                                                                            0;
                                                                        i <
                                                                            itemsToShow.length;
                                                                        i++
                                                                      ) {
                                                                        if (selectedItems[i]) {
                                                                          selectedOrderItems.add(
                                                                            itemsToShow[i],
                                                                          );
                                                                        }
                                                                      }

                                                                      await _processReorder(
                                                                        originalOrder,
                                                                        selectedOrderItems,
                                                                        budgetController
                                                                            .text,
                                                                      );
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop();

                                                                      String
                                                                      successMessage =
                                                                          isCancelled
                                                                          ? '$selectedCount items have been retried successfully!'
                                                                          : allItemsUnavailable
                                                                          ? '$selectedCount unavailable items have been retried successfully!'
                                                                          : '$selectedCount available items have been reordered successfully!';

                                                                      showSuccessToast(
                                                                        context,
                                                                        successMessage,
                                                                      );

                                                                      // Switch to today's orders tab
                                                                      this.setState(
                                                                        () => _selectedIndex =
                                                                            0,
                                                                      );
                                                                    } catch (
                                                                      e
                                                                    ) {
                                                                      showErrorToast(
                                                                        context,
                                                                        'Failed to create ${isCancelled || allItemsUnavailable ? 'retry' : 'reorder'}: $e',
                                                                      );
                                                                    } finally {
                                                                      setState(
                                                                        () => isLoading =
                                                                            false,
                                                                      );
                                                                    }
                                                                  }
                                                                },
                                                          child: Container(
                                                            alignment: Alignment
                                                                .center,
                                                            child: isLoading
                                                                ? Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      SizedBox(
                                                                        width:
                                                                            18,
                                                                        height:
                                                                            18,
                                                                        child: CircularProgressIndicator(
                                                                          color:
                                                                              Colors.white,
                                                                          strokeWidth:
                                                                              2,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            12,
                                                                      ),
                                                                      Text(
                                                                        'Creating Order...',
                                                                        style: TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  )
                                                                : Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .refresh_rounded,
                                                                        color:
                                                                            hasSelectedItems
                                                                            ? Colors.white
                                                                            : Colors.white.withOpacity(
                                                                                0.5,
                                                                              ),
                                                                        size:
                                                                            20,
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            8,
                                                                      ),
                                                                      Text(
                                                                        hasSelectedItems
                                                                            ? isCancelled
                                                                                  ? 'Retry $selectedCount Item${selectedCount > 1 ? 's' : ''}'
                                                                                  : allItemsUnavailable
                                                                                  ? 'Retry $selectedCount Item${selectedCount > 1 ? 's' : ''}'
                                                                                  : 'Reorder $selectedCount Item${selectedCount > 1 ? 's' : ''}'
                                                                            : 'Select Items First',
                                                                        style: TextStyle(
                                                                          color:
                                                                              hasSelectedItems
                                                                              ? Colors.white
                                                                              : Colors.white.withOpacity(0.5),
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          letterSpacing:
                                                                              0.5,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processReorder(
    EmployeeOrder originalOrder,
    List<OrderItem> selectedItems,
    String budgetText,
  ) async {
    // Find available office boys
    final availableOfficeBoys = officeBoys.where((ob) => ob.isActive).toList();

    if (availableOfficeBoys.isEmpty) {
      throw Exception('No available office boys for reorder');
    }

    final bool isCancelled = originalOrder.status == OrderStatus.cancelled;

    List<OrderItem> itemsToProcess;

    if (isCancelled) {
      itemsToProcess = selectedItems
          .map((item) => OrderItem(name: item.name, status: ItemStatus.pending))
          .toList();
    } else {
      itemsToProcess = selectedItems
          .map((item) => OrderItem(name: item.name, status: ItemStatus.pending))
          .toList();
    }

    if (itemsToProcess.isEmpty) {
      throw Exception(
        'No items selected for ${isCancelled ? 'retry' : 'reorder'}',
      );
    }

    // Parse budget for external orders
    double? budget;
    if (originalOrder.type == OrderType.external) {
      budget = double.tryParse(budgetText);
      if (budget == null || budget <= 0) {
        throw Exception('Invalid budget amount');
      }
    }

    // Create the reorder/retry
    final newOrder = EmployeeOrder(
      id: '',
      employeeId: currentUser!.id,
      employeeName: currentUser!.name,
      employeeRole: currentUser!.role,
      officeBoyId: availableOfficeBoys.first.id,
      officeBoyName: availableOfficeBoys.first.name,
      items: itemsToProcess,
      description: originalOrder.description,
      type: originalOrder.type,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      price: budget,
      organizationId: currentUser!.organizationId,
      notes: isCancelled
          ? 'Retried from cancelled order #${originalOrder.id.substring(0, 8)}'
          : 'Reordered from #${originalOrder.id.substring(0, 8)}',
    );

    // Add to Firestore
    await _firebaseService.addDocument('orders', newOrder.toFirestore());
  }

  Widget _buildAnimatedTodaysOrders() {
    return Column(
      children: [
        SizedBox(height: 16),

        if (todayOrders.any((o) => o.status == OrderStatus.needsResponse)) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.priority_high, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Response Required',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Some of your orders need your response due to item availability issues.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
        ],

        // My Orders
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'My Orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        SizedBox(height: 16),

        if (todayOrders.isEmpty)
          _buildAnimatedEmptyState('No orders yet', Icons.receipt_long)
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: todayOrders
                  .asMap()
                  .entries
                  .map(
                    (entry) => _buildAnimatedOrderCard(entry.value, entry.key),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// Add missing classes from admin layout
class AnimatedParticlesPainter extends CustomPainter {
  final double animationValue;
  final double rotationValue;

  AnimatedParticlesPainter(this.animationValue, this.rotationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Create animated particles
    for (int i = 0; i < 15; i++) {
      final x =
          (size.width * 0.2) +
          (i * size.width * 0.05) +
          (math.sin(animationValue * 2 * math.pi + i) * 20);
      final y =
          (size.height * 0.3) +
          (math.cos(animationValue * 2 * math.pi + i * 0.5) * 30);
      final radius = 2 + math.sin(animationValue * 2 * math.pi + i) * 1.5;

      canvas.drawCircle(Offset(x, y), radius.abs(), paint);
    }

    // Add flowing gradient lines
    final gradient = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final startY = size.height * (0.2 + i * 0.15);

      path.moveTo(-50, startY);

      for (double x = -50; x <= size.width + 50; x += 10) {
        final y =
            startY +
            math.sin((x * 0.01) + (animationValue * 2 * math.pi) + (i * 2)) *
                15;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, gradient);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ShimmerLoading extends StatelessWidget {
  final Animation<double> shimmerAnimation;
  final Color primaryColor;

  const ShimmerLoading({
    super.key,
    required this.shimmerAnimation,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: [
                (shimmerAnimation.value - 1).clamp(0.0, 1.0),
                shimmerAnimation.value.clamp(0.0, 1.0),
                (shimmerAnimation.value + 1).clamp(0.0, 1.0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        SizedBox(height: 16),
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: [
                (shimmerAnimation.value - 1).clamp(0.0, 1.0),
                shimmerAnimation.value.clamp(0.0, 1.0),
                (shimmerAnimation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
      ],
    );
  }
}

class ParticlesPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;

  ParticlesPainter(this.animationValue, this.primaryColor, this.secondaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final progress = (animationValue + i * 0.1) % 1.0;
      final x =
          (i % 4) * size.width / 4 +
          math.sin(animationValue * 2 * math.pi + i) * 30;
      final y = size.height * progress;
      final opacity = math.sin(progress * math.pi) * 0.3;

      paint.color = (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(
        opacity,
      );

      final radius = 2 + math.sin(animationValue * 4 * math.pi + i) * 1;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw flowing waves
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final waveHeight = 20 + i * 10;
      final waveLength = size.width / 4;
      final waveOffset = animationValue * 2 * math.pi;

      wavePaint.color = (i % 2 == 0 ? primaryColor : secondaryColor)
          .withOpacity(0.1);

      path.moveTo(0, size.height * 0.3 + i * size.height * 0.2);

      for (double x = 0; x <= size.width; x += 5) {
        final y =
            size.height * 0.3 +
            i * size.height * 0.2 +
            math.sin((x / waveLength + waveOffset + i) * 2 * math.pi) *
                waveHeight;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, wavePaint);
    }

    // Draw gradient orbs
    for (int i = 0; i < 5; i++) {
      final centerX = (i + 0.5) * size.width / 5;
      final centerY =
          size.height * 0.5 +
          math.sin(animationValue * 2 * math.pi + i * 1.2) * 100;
      final radius = 40 + math.sin(animationValue * 3 * math.pi + i) * 20;

      final gradient = RadialGradient(
        colors: [
          (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(0.1),
          Colors.transparent,
        ],
      );

      final rect = Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius,
      );
      paint.shader = gradient.createShader(rect);
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
