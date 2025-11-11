import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/admin/data/models/app_user.dart';
import 'package:taqy/features/admin/data/models/order.dart';
import 'package:taqy/features/admin/data/models/organization.dart';

class UserDetailsBottomSheet extends StatefulWidget {
  final AdminAppUser user;
  final List<AdminOrder> orders;
  final AdminOrganization organization;
  final Animation<double> animation;

  const UserDetailsBottomSheet({
    super.key,
    required this.user,
    required this.orders,
    required this.organization,
    required this.animation,
  });

  @override
  State<UserDetailsBottomSheet> createState() => _UserDetailsBottomSheetState();
}

class _UserDetailsBottomSheetState extends State<UserDetailsBottomSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;

  OrderStatus? selectedFilter;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<AdminOrder> get filteredOrders {
    if (selectedFilter == null) return widget.orders;
    return widget.orders
        .where((order) => order.status == selectedFilter)
        .toList();
  }

  List<AdminOrder> get pendingOrders => widget.orders
      .where((order) => order.status == OrderStatus.pending)
      .toList();

  List<AdminOrder> get inProgressOrders => widget.orders
      .where((order) => order.status == OrderStatus.inProgress)
      .toList();

  List<AdminOrder> get completedOrders => widget.orders
      .where((order) => order.status == OrderStatus.completed)
      .toList();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safePadding = MediaQuery.of(context).padding.top;
    final locale = Localizations.localeOf(context).languageCode;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: screenHeight * 0.92 + safePadding,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Stack(
          children: [
            // Animated background
            Positioned.fill(child: _buildAnimatedBackground()),

            // Main content with glass morphism
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: _buildContent(locale),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              widget.organization.primaryColorValue.withOpacity(0.12),
              widget.organization.secondaryColorValue.withOpacity(0.08),
              Colors.transparent,
            ],
            stops: const [0.1, 0.5, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _ParticlesPainter(
            _particleAnimation.value,
            widget.organization.primaryColorValue,
            widget.organization.secondaryColorValue,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String locale) {
    return Column(
      children: [
        // Header with handle
        _buildHeader(locale),

        // User info section
        _buildUserInfo(locale),

        // Tab bar
        _buildTabBar(locale),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildOrdersTab(locale), _buildStatisticsTab(locale)],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String locale) {
    return Column(
      children: [
        // Handle bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) => Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(
                          _glowAnimation.value * 0.3,
                        ),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        locale == 'ar' ? 'الملف الشخصي' : 'User Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) => Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(
                                      0.2 + (_glowAnimation.value * 0.1),
                                    ),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(
                                      _glowAnimation.value * 0.2,
                                    ),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: SvgPicture.asset(
                                Assets.imagesSvgsClose,
                                color: Colors.white.withOpacity(0.9),
                                width: 20,
                                height: 20,
                              ),
                            ),
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
      ],
    );
  }

  Widget _buildUserInfo(String locale) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Row(
            children: [
              _buildAnimatedAvatar(),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameAndStatus(locale),
                    const SizedBox(height: 12),
                    _buildUserDetails(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAvatar() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Transform.scale(
        scale: _pulseAnimation.value,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: widget.organization.primaryColorValue.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: widget.user.profilePictureUrl != null
                ? Image.network(
                    widget.user.profilePictureUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultAvatar(),
                  )
                : _buildDefaultAvatar(),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            widget.organization.primaryColorValue.withOpacity(0.4),
            widget.organization.secondaryColorValue.withOpacity(0.4),
          ],
        ),
      ),
      child: Icon(
        widget.user.role == UserRole.employee
            ? Icons.person_rounded
            : Icons.delivery_dining_rounded,
        color: Colors.white,
        size: 36,
      ),
    );
  }

  Widget _buildNameAndStatus(String locale) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.organization.primaryColorValue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  widget.user.role == UserRole.employee
                      ? locale == 'ar'
                            ? 'موظف'
                            : 'Employee'
                      : locale == 'ar'
                      ? 'عامل'
                      : 'Office Boy',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildStatusIndicator(locale),
      ],
    );
  }

  Widget _buildStatusIndicator(String locale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.user.isActive
              ? [
                  Colors.greenAccent.withOpacity(0.3),
                  Colors.green.withOpacity(0.2),
                ]
              : [
                  Colors.red.withOpacity(0.3),
                  Colors.redAccent.withOpacity(0.2),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.user.isActive ? Colors.greenAccent : Colors.red,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.user.isActive ? Colors.greenAccent : Colors.red,
                boxShadow: [
                  BoxShadow(
                    color:
                        (widget.user.isActive ? Colors.greenAccent : Colors.red)
                            .withOpacity(_pulseAnimation.value * 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.user.isActive
                ? locale == 'ar'
                      ? 'نشط'
                      : 'Active'
                : locale == 'ar'
                ? 'غير نشط'
                : 'Inactive',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(Assets.imagesSvgsMail, widget.user.email),
        const SizedBox(height: 8),
        _buildDetailRow(Assets.imagesSvgsPhone, widget.user.phone),
        if (widget.user.department != null) ...[
          const SizedBox(height: 8),
          _buildDetailRow(Assets.imagesSvgsCompany, widget.user.department!),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String icon, String text) {
    return Row(
      children: [
        SvgPicture.asset(
          icon,
          height: 16,
          width: 16,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(String locale) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.organization.primaryColorValue.withOpacity(0.8),
                  widget.organization.secondaryColorValue.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.organization.primaryColorValue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabs: [
              Tab(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 18),
                    SizedBox(width: 6),
                    Text(locale == 'ar' ? 'الطلبات' : 'Orders'),
                  ],
                ),
              ),
              Tab(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics_rounded, size: 18),
                    SizedBox(width: 6),
                    Text(locale == 'ar' ? 'الإحصائيات' : 'Stats'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTab(String locale) {
    return Column(
      children: [
        _buildOrderFilters(locale),
        Expanded(
          child: filteredOrders.isEmpty
              ? _buildEmptyState(
                  locale == 'ar' ? 'لا توجد طلبات' : 'No orders found',
                  Icons.receipt_long_rounded,
                )
              : _buildOrdersList(locale),
        ),
      ],
    );
  }

  Widget _buildOrderFilters(String locale) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildOrderFilterChip(
              locale == 'ar' ? 'الكل' : 'All',
              selectedFilter == null,
              locale,
            ),
            const SizedBox(width: 8),
            _buildOrderFilterChip(
              locale == 'ar' ? 'قيد الانتظار' : 'Pending',
              selectedFilter == OrderStatus.pending,
              locale,
            ),
            const SizedBox(width: 8),
            _buildOrderFilterChip(
              locale == 'ar' ? 'قيد التنفيذ' : 'In Progress',
              selectedFilter == OrderStatus.inProgress,
              locale,
            ),
            const SizedBox(width: 8),
            _buildOrderFilterChip(
              locale == 'ar' ? 'مكتمل' : 'Completed',
              selectedFilter == OrderStatus.completed,
              locale,
            ),
            const SizedBox(width: 8),
            _buildOrderFilterChip(
              locale == 'ar' ? 'ملغي' : 'Cancelled',
              selectedFilter == OrderStatus.cancelled,
              locale,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderFilterChip(String label, bool isSelected, String locale) {
    return GestureDetector(
      onTap: () => _handleFilterTap(label, locale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    widget.organization.primaryColorValue,
                    widget.organization.secondaryColorValue,
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.4)
                : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _handleFilterTap(String label, String locale) {
    setState(() {
      if (label == (locale == 'ar' ? 'الكل' : 'All')) {
        selectedFilter = null;
      } else if (label == (locale == 'ar' ? 'قيد الانتظار' : 'Pending')) {
        selectedFilter = OrderStatus.pending;
      } else if (label == (locale == 'ar' ? 'قيد التنفيذ' : 'In Progress')) {
        selectedFilter = OrderStatus.inProgress;
      } else if (label == (locale == 'ar' ? 'مكتمل' : 'Completed')) {
        selectedFilter = OrderStatus.completed;
      } else if (label == (locale == 'ar' ? 'ملغي' : 'Cancelled')) {
        selectedFilter = OrderStatus.cancelled;
      }
    });
  }

  Widget _buildOrdersList(String locale) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) =>
          _buildOrderCard(filteredOrders[index], locale),
    );
  }

  Widget _buildOrderCard(AdminOrder order, String locale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // Add order details navigation if needed
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: _buildOrderContent(order, locale),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderContent(AdminOrder order, String locale) {
    final isEmployee = widget.user.role == UserRole.employee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with ID and status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#${order.id.substring(0, 6)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            _buildOrderStatus(order.status, locale),
          ],
        ),

        const SizedBox(height: 12),

        // Items list
        _buildOrderItems(order, locale),

        // Description if available
        if (order.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildOrderDescription(order),
        ],

        // Role-specific info
        if ((isEmployee) || (!isEmployee)) ...[
          const SizedBox(height: 12),
          _buildRoleInfo(order, isEmployee, locale),
        ],

        // Price and time
        const SizedBox(height: 12),
        _buildOrderFooter(order, locale),
      ],
    );
  }

  Widget _buildOrderStatus(OrderStatus status, String locale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
      ),
      child: Text(
        _getStatusText(status, locale),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOrderItems(AdminOrder order, String locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale == 'ar'
              ? '${order.items.length} عنصر'
              : '${order.items.length} items',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...order.items.map((item) => _buildOrderItem(item)),
      ],
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getItemStatusColor(item.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                color: item.status == ItemStatus.notAvailable
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white.withOpacity(0.9),
                fontSize: 13,
                decoration: item.status == ItemStatus.notAvailable
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDescription(AdminOrder order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        order.description,
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildRoleInfo(AdminOrder order, bool isEmployee, String locale) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.organization.primaryColorValue.withOpacity(0.15),
            widget.organization.secondaryColorValue.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isEmployee ? Icons.delivery_dining_rounded : Icons.person_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEmployee
                  ? '${locale == 'ar' ? 'تم التسليم بواسطة' : 'Delivered by'}: ${order.officeBoyName}'
                  : '${locale == 'ar' ? 'تم الطلب بواسطة' : 'Ordered by'}: ${order.employeeName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderFooter(AdminOrder order, String locale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 14,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Text(
              _formatTime(order.createdAt, locale),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        if (order.finalPrice != null) _buildOrderPrice(order, locale),
      ],
    );
  }

  Widget _buildOrderPrice(AdminOrder order, String locale) {
    final hasDiscount = order.price != order.finalPrice;

    return Row(
      children: [
        if (hasDiscount)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              '${order.price?.toStringAsFixed(0) ?? '0'} ${locale == 'ar' ? 'ج.م' : 'EGP'}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        Text(
          '${order.finalPrice!.toStringAsFixed(0)} ${locale == 'ar' ? 'ج.م' : 'EGP'}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab(String locale) {
    final totalOrders = widget.orders.length;
    final todaysOrders = widget.orders.where(
      (o) => o.createdAt.day == DateTime.now().day,
    );
    final completedCount = completedOrders.length;
    final pendingCount = pendingOrders.length;
    final inProgressCount = inProgressOrders.length;
    final cancelledCount = widget.orders
        .where((o) => o.status == OrderStatus.cancelled)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildStatsGrid(
            totalOrders,
            todaysOrders.length,
            completedCount,
            pendingCount,
            inProgressCount,
            cancelledCount,
            locale,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    int total,
    int todaysOrders,
    int completed,
    int pending,
    int inProgress,
    int cancelled,
    String locale,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          locale == 'ar' ? 'إجمالي الطلبات' : 'Total Orders',
          total.toString(),
          Assets.imagesSvgsOrder,
          widget.organization.primaryColorValue,
        ),
        _buildStatCard(
          locale == 'ar' ? 'طلبات اليوم' : 'Today\'s Orders',
          todaysOrders.toString(),
          Assets.imagesSvgsCalendar,
          widget.organization.secondaryColorValue,
        ),
        _buildStatCard(
          locale == 'ar' ? 'مكتمل' : 'Completed',
          completed.toString(),
          Assets.imagesSvgsComplete,
          Colors.green,
        ),
        _buildStatCard(
          locale == 'ar' ? 'قيد الانتظار' : 'Pending',
          pending.toString(),
          Assets.imagesSvgsPending,
          Colors.orange,
        ),
        _buildStatCard(
          locale == 'ar' ? 'قيد التنفيذ' : 'In Progress',
          inProgress.toString(),
          Assets.imagesSvgsClock,
          Colors.blue,
        ),
        _buildStatCard(
          locale == 'ar' ? 'ملغي' : 'Cancelled',
          cancelled.toString(),
          Assets.imagesSvgsCancell,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(icon, color: color, height: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Center(
        child: Column(
          children: [
            SizedBox(height: 60),
            Text(message, style: TextStyle(fontSize: 16, color: Colors.white)),
            Lottie.asset(
              'assets/images/lottie/Package Delivery.json',
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
              height: value * 200,
              width: value * 200,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for status and formatting
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
        return Colors.purple;
    }
  }

  String _getStatusText(OrderStatus status, String locale) {
    switch (status) {
      case OrderStatus.pending:
        return locale == 'ar' ? 'قيد الانتظار' : 'Pending';
      case OrderStatus.inProgress:
        return locale == 'ar' ? 'قيد التنفيذ' : 'In Progress';
      case OrderStatus.completed:
        return locale == 'ar' ? 'مكتمل' : 'Completed';
      case OrderStatus.cancelled:
        return locale == 'ar' ? 'ملغي' : 'Cancelled';
      case OrderStatus.needsResponse:
        return locale == 'ar' ? 'بحاجة للرد' : 'Needs Response';
    }
  }

  Color _getItemStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.pending:
        return Colors.orange;
      case ItemStatus.available:
        return Colors.green;
      case ItemStatus.notAvailable:
        return Colors.red;
    }
  }

  String _formatTime(DateTime dateTime, String locale) {
    final now = DateTime.now();
    final difference = now.difference(dateTime).abs();

    if (difference.inMinutes < 60) {
      return locale == 'ar'
          ? 'منذ ${difference.inMinutes} دقيقة'
          : '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return locale == 'ar'
          ? 'منذ ${difference.inHours} ساعة'
          : '${difference.inHours}h ago';
    } else {
      return locale == 'ar'
          ? 'منذ ${difference.inDays} يوم'
          : '${difference.inDays}d ago';
    }
  }
}

class _ParticlesPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;

  _ParticlesPainter(
    this.animationValue,
    this.primaryColor,
    this.secondaryColor,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;

    final particleCount = 15;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < particleCount; i++) {
      final angle = 2 * math.pi * i / particleCount + animationValue;
      final distance = 50 + 30 * math.sin(animationValue + i);
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);
      final radius = 1 + math.sin(animationValue + i) * 0.5;

      final color = i % 2 == 0 ? primaryColor : secondaryColor;
      paint.color = color.withOpacity(
        0.08 + math.sin(animationValue + i) * 0.04,
      );

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
