import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/services/firebase_service.dart';
import 'package:taqy/core/static/app_assets.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/employee/data/models/order_model.dart';
import 'package:taqy/features/employee/data/models/organization_model.dart';
import 'package:taqy/features/employee/data/models/user_model.dart';
import 'package:taqy/features/employee/presentation/widgets/edit_order_bottom_sheet.dart';
import 'package:taqy/features/employee/presentation/widgets/new_order_bottom_sheet.dart';
import 'package:taqy/features/employee/presentation/widgets/profile_bottom_sheet.dart';
import 'package:taqy/features/employee/presentation/widgets/response_bottom_sheet.dart';

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
              final allOrders =
                  snapshot.docs
                      .map((doc) => EmployeeOrder.fromFirestore(doc))
                      .where((order) => order.employeeId == currentUser!.id)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              setState(() {
                todayOrders = allOrders;

                // Separate today's orders and history
                todayOrders = allOrders.where((order) {
                  final orderDate = DateTime(
                    order.createdAt.year,
                    order.createdAt.month,
                    order.createdAt.day,
                  );
                  return orderDate.isAtSameMomentAs(today);
                }).toList();

                historyOrders = allOrders.where((order) {
                  final orderDate = DateTime(
                    order.createdAt.year,
                    order.createdAt.month,
                    order.createdAt.day,
                  );
                  return orderDate.isBefore(today);
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

  void _showEditOrderBottomSheet(EmployeeOrder order) {
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
            _showSuccessToast(
              newStatus == OrderStatus.cancelled
                  ? 'Order cancelled successfully!'
                  : 'Order updated successfully!',
            );
          } catch (e) {
            _showErrorToast('Failed to update order: $e');
          }
        },
      ),
    );
  }

  // void _showProfileBottomSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => ProfileBottomSheet(
  //       user: currentUser!,
  //       organization: organization!,
  //       onLogout: () => _handleLogout(),
  //       onProfileUpdated: (updatedUser) {
  //         setState(() {
  //           currentUser = updatedUser;
  //         });
  //       },
  //     ),
  //   );
  // }

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
            // Animated top icons
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
                            'Welcome, ${currentUser?.name ?? ''}',
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
                              color: organization!.primaryColorValue,
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
                  SvgPicture.asset(
                    Assets.imagesSvgsClock,
                    color: organization!.primaryColorValue,
                    height: 16,
                    width: 16,
                  ),
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
            // boxShadow: [
            //   BoxShadow(
            //     color: color.withOpacity(0.2),
            //     blurRadius: 4,
            //     offset: Offset(0, 2),
            //   ),
            // ],
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
            Lottie.asset(
              'assets/images/lottie/Package Delivery.json',
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
          ],
        ),
      ),
    );
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
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 16),

            if (historyOrders.isEmpty)
              _buildAnimatedEmptyState('No previous orders', Icons.history)
            else
              ...historyOrders.map((order) => _buildCompactOrderCard(order)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactOrderCard(EmployeeOrder order) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: order.status == OrderStatus.needsResponse
            ? Border.all(color: organization!.secondaryColorValue, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        image: DecorationImage(
          image: AssetImage(AppImages.pattern),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            organization!.secondaryColorValue.withOpacity(.4),
            BlendMode.modulate,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SvgPicture.asset(
              _getStatusIcon(order.status),
              color: _getStatusColor(order.status),
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
                      : '${order.items.length} items',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Row(
                  children: [
                    SvgPicture.asset(
                      Assets.imagesSvgsClock,
                      color: organization!.primaryColorValue,
                      height: 12,
                      width: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _formatTime(order.createdAt),
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildStatusChip(order.status),
          if (order.status == OrderStatus.pending) ...[
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showEditOrderBottomSheet(order),
              child: SvgPicture.asset(
                Assets.imagesSvgsEdit,
                color: organization?.primaryColorValue,
                height: 16,
                width: 16,
              ),
            ),
          ],
          if (order.status == OrderStatus.needsResponse) ...[
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showResponseBottomSheet(order),
              child: Icon(Icons.reply_rounded, size: 16, color: Colors.purple),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Assets.imagesSvgsCalendar;
      case OrderStatus.inProgress:
        return Assets.imagesSvgsClock;
      case OrderStatus.completed:
        return Assets.imagesSvgsComplete;
      case OrderStatus.cancelled:
        return Assets.imagesSvgsCancell;
      case OrderStatus.needsResponse:
        return Assets.imagesSvgsEdit;
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.needsResponse:
        return Colors.red;
    }
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
