import 'dart:async';
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
import 'package:taqy/core/notifications/notification_service.dart';
import 'package:taqy/core/notifications/office_boy_notification_bottom_sheet.dart';
import 'package:taqy/core/services/firebase_service.dart';
import 'package:taqy/core/static/app_assets.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/office_boy/data/models/office_order.dart';
import 'package:taqy/features/office_boy/data/models/office_organization.dart';
import 'package:taqy/features/office_boy/data/models/office_user_model.dart';
import 'package:taqy/features/office_boy/presentation/widgets/office_profile.dart';
import 'package:taqy/features/office_boy/presentation/widgets/order_details.dart';

class OfficeBoyLayout extends StatefulWidget {
  const OfficeBoyLayout({super.key});

  @override
  State<OfficeBoyLayout> createState() => _OfficeBoyLayoutState();
}

class _OfficeBoyLayoutState extends State<OfficeBoyLayout>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();

  OfficeUserModel? currentUser;
  OfficeOrganization? organization;
  List<OfficeOrder> myOrders = [];
  List<OfficeOrder> availableOrders = [];
  List<OfficeUserModel> otherOfficeBoys = [];
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
  bool hasUnreadNotifications = false;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeAnimations();
    _loadData();
    _loadSavedColors();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUser?.id ?? '')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                _unreadCount = snapshot.docs.length;
                hasUnreadNotifications = _unreadCount > 0;
              });
            }
          },
          onError: (error) {
            log('Error listening to notifications: $error');
          },
        );
  }

  void _checkUnreadNotifications() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUser!.id)
          .where('isRead', isEqualTo: false)
          .get();

      if (mounted) {
        setState(() {
          _unreadCount = snapshot.docs.length;
          hasUnreadNotifications = _unreadCount > 0;
        });
      }
    } catch (e) {
      log('Error checking unread notifications: $e');
    }
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _backgroundGradient = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

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

  Future<void> _loadSavedColors() async {
    final savedPrimaryColor =
        await SharedPreferencesService.getOrganizationPrimaryColor();
    final savedSecondaryColor =
        await SharedPreferencesService.getOrganizationSecondaryColor();

    if (savedPrimaryColor != null && savedSecondaryColor != null && mounted) {
      setState(() {});
    }
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
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _refreshNotificationBadge() {
    // Force refresh the notification badge
    _checkUnreadNotifications();
  }

  void _showNotificationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfficeBoyNotificationBottomSheet(
        organization: organization!,
        userId: currentUser!.id,
        userRole: currentUser!.role,
        onNotificationsUpdated: _refreshNotificationBadge,
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      _slideController.reset();
      _fadeController.reset();
      _scaleController.reset();

      final user = _firebaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await _firebaseService.getDocument('users', user.uid);
      if (!userDoc.exists) throw Exception('User data not found');

      setState(() {
        currentUser = OfficeUserModel.fromFirestore(userDoc);
      });

      final orgDoc = await _firebaseService.getDocument(
        'organizations',
        currentUser!.organizationId,
      );
      if (orgDoc.exists) {
        setState(() {
          organization = OfficeOrganization.fromFirestore(orgDoc);
        });

        ColorManager().updateColors(
          organization!.primaryColorValue,
          organization!.secondaryColorValue,
        );
      }

      await _loadOtherOfficeBoys();
      _loadOrders();

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

  Future<void> _loadOtherOfficeBoys() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('organizationId', isEqualTo: currentUser!.organizationId)
          .where('role', isEqualTo: 'officeBoy')
          .get();

      setState(() {
        otherOfficeBoys = snapshot.docs
            .where((doc) => doc.id != currentUser!.id)
            .map((doc) => OfficeUserModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error loading other office boys: $e');
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

                // Get current date for filtering
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                // Get TODAY'S orders for current user (replace userOrders with todayOrders)
                myOrders = allOrders.where((order) {
                  // First check if it's today's order
                  final orderDate = DateTime(
                    order.createdAt.year,
                    order.createdAt.month,
                    order.createdAt.day,
                  );
                  final isToday = orderDate.isAtSameMomentAs(today);

                  // Then check if it belongs to current user
                  final isMyOrder =
                      order.officeBoyId == currentUser!.id ||
                      (order.isSpecificallyAssigned &&
                          order.specificallyAssignedOfficeBoyId ==
                              currentUser!.id);

                  return isToday && isMyOrder;
                }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                // Available orders (unchanged)
                availableOrders = allOrders.where((order) {
                  if (order.status != OrderStatus.pending) return false;
                  if (order.isSpecificallyAssigned) {
                    return order.specificallyAssignedOfficeBoyId ==
                            currentUser!.id &&
                        order.officeBoyId != currentUser!.id;
                  }
                  return order.officeBoyId != currentUser!.id;
                }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
      if (order.isSpecificallyAssigned &&
          order.specificallyAssignedOfficeBoyId != currentUser!.id) {
        showErrorToast(
          context,
          _currentLocale == 'ar'
              ? 'الطلب ده معاد لأوفيس بوي تاني'
              : 'This order is specifically assigned to another office boy',
        );
        return;
      }

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

      final bool isOrderFromAdmin = order.employeeRole == UserRole.admin;

      await NotificationService().notifyUserOrderAccepted(
        userId: order.employeeId,
        orderId: order.id,
        officeBoyName: currentUser!.name,
        isAdmin: isOrderFromAdmin,
        isArabic: _currentLocale == 'ar',
      );

      showSuccessToast(
        context,
        _currentLocale == 'ar'
            ? 'تم قبول الطلب بنجاح!'
            : 'Order accepted successfully!',
      );
    } catch (e) {
      showErrorToast(
        context,
        _currentLocale == 'ar'
            ? 'فشل في قبول الطلب: $e'
            : 'Failed to accept order: $e',
      );
    }
  }

  Future<void> _rejectSpecificallyAssignedOrder(OfficeOrder order) async {
    try {
      final updatedOrder = order.copyWith(
        isSpecificallyAssigned: false,
        specificallyAssignedOfficeBoyId: null,
      );

      await _firebaseService.updateDocument(
        'orders',
        order.id,
        updatedOrder.toFirestore(),
      );

      showSuccessToast(
        context,
        _currentLocale == 'ar'
            ? 'تم رفض الطلب وإتاحته للآخرين'
            : 'Order rejected and made available for others',
      );
    } catch (e) {
      showErrorToast(
        context,
        _currentLocale == 'ar'
            ? 'فشل في رفض الطلب: $e'
            : 'Failed to reject order: $e',
      );
    }
  }

  Future<void> _transferOrder(
    OfficeOrder order,
    String newOfficeBoyId,
    String newOfficeBoyName,
  ) async {
    try {
      final updatedOrder = order.copyWith(
        isSpecificallyAssigned: true,
        specificallyAssignedOfficeBoyId: newOfficeBoyId,
        officeBoyId: '',
        officeBoyName: '',
      );

      await _firebaseService.updateDocument(
        'orders',
        order.id,
        updatedOrder.toFirestore(),
      );

      // ✅ NOTIFY NEW OFFICE BOY
      await NotificationService().notifyOrderTransferredToOfficeBoy(
        newOfficeBoyId: newOfficeBoyId,
        orderId: order.id,
        employeeName: order.employeeName,
        itemCount: order.items.length,
        fromOfficeBoyName: currentUser!.name,
        isArabic: _currentLocale == 'ar',
      );

      // ✅ NOTIFY EMPLOYEE
      await NotificationService().notifyUserOrderTransferred(
        userId: order.employeeId,
        orderId: order.id,
        fromOfficeBoyName: currentUser!.name,
        toOfficeBoyName: newOfficeBoyName,
        isAdmin: order.employeeRole == UserRole.admin,
        isArabic: _currentLocale == 'ar',
      );

      showSuccessToast(
        context,
        _currentLocale == 'ar'
            ? 'تم تحويل الطلب لـ $newOfficeBoyName'
            : 'Order transferred to $newOfficeBoyName',
      );
    } catch (e) {
      showErrorToast(
        context,
        _currentLocale == 'ar'
            ? 'فشل في تحويل الطلب: $e'
            : 'Failed to transfer order: $e',
      );
    }
  }

  void _showTransferBottomSheet(OfficeOrder order) {
    if (otherOfficeBoys.isEmpty) {
      showErrorToast(
        context,
        _currentLocale == 'ar'
            ? 'مفيش أوفيس بويز تانيين متاحين للتحويل'
            : 'No other office boys available for transfer',
      );
      return;
    }

    _showGlassBottomSheet(
      context: context,
      heightFactor: 0.7,
      child: _buildTransferBottomSheetContent(order),
    );
  }

  Widget _buildTransferBottomSheetContent(OfficeOrder order) {
    final locale = Localizations.localeOf(context).languageCode;

    return Column(
      children: [
        // Header
        _buildGlassBottomSheetHeader(
          icon: Assets.imagesSvgsEdit,
          title: locale == 'ar' ? 'تحويل الطلب' : 'Transfer Order',
          subtitle: locale == 'ar'
              ? 'اختار اوفيس بوي تحول ليه الطلب'
              : 'Select an office boy to transfer this order',
        ),

        // Office Boys List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: otherOfficeBoys.length,
            itemBuilder: (context, index) {
              final officeBoy = otherOfficeBoys[index];
              return _buildGlassListItem(
                onTap: () {
                  Navigator.pop(context);
                  _showTransferConfirmationBottomSheet(order, officeBoy);
                },
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        organization!.primaryColorValue,
                        organization!.secondaryColorValue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      officeBoy.name[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: officeBoy.name,
                subtitle: officeBoy.email,
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showTransferConfirmationBottomSheet(
    OfficeOrder order,
    OfficeUserModel newOfficeBoy,
  ) {
    _showGlassBottomSheet(
      context: context,
      heightFactor: 0.35,
      child: _buildTransferConfirmationContent(order, newOfficeBoy),
    );
  }

  Widget _buildTransferConfirmationContent(
    OfficeOrder order,
    OfficeUserModel newOfficeBoy,
  ) {
    final locale = Localizations.localeOf(context).languageCode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGlassBottomSheetHeader(
          icon: Assets.imagesSvgsEdit,
          title: locale == 'ar' ? 'تحويل الطلب؟' : 'Transfer Order?',
          subtitle: locale == 'ar'
              ? 'الطلب ده هيتبعت لـ ${newOfficeBoy.name}. هيحتاج يقبله.'
              : 'This order will be specifically assigned to ${newOfficeBoy.name}. They will need to accept it.',
        ),

        SizedBox(height: 24),

        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildGlassButton(
                  text: locale == 'ar' ? 'إلغاء' : 'Cancel',
                  onPressed: () => Navigator.pop(context),
                  isSecondary: true,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildGlassButton(
                  text: locale == 'ar' ? 'تحويل الطلب' : 'Transfer Order',
                  onPressed: () {
                    Navigator.pop(context);
                    _transferOrder(order, newOfficeBoy.id, newOfficeBoy.name);
                  },
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.orange.withOpacity(0.8)],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  void _showSpecificallyAssignedBottomSheet(OfficeOrder order) {
    if (order.isSpecificallyAssigned &&
        order.specificallyAssignedOfficeBoyId == currentUser!.id &&
        order.status == OrderStatus.pending) {
      _showGlassBottomSheet(
        context: context,
        heightFactor: 0.35,
        child: _buildSpecificallyAssignedContent(order),
      );
    }
  }

  Widget _buildSpecificallyAssignedContent(OfficeOrder order) {
    final locale = Localizations.localeOf(context).languageCode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGlassBottomSheetHeader(
          icon: Assets.imagesSvgsShoppingCart,
          title: locale == 'ar' ? 'توكيل المهمة' : 'Order Assignment',
          subtitle: locale == 'ar'
              ? 'الطلب ده معاد ليك بالتحديد. عايز تقبله ولا ترفضه؟'
              : 'This order was specifically assigned to you. Do you want to accept or reject it?',
        ),

        SizedBox(height: 24),

        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildGlassButton(
                  text: locale == 'ar' ? 'رفض' : 'Reject',
                  onPressed: () {
                    Navigator.pop(context);
                    _rejectSpecificallyAssignedOrder(order);
                  },
                  isSecondary: true,
                  backgroundColor: Colors.red.withOpacity(0.5),
                  textColor: Colors.red,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildGlassButton(
                  text: locale == 'ar' ? 'قبول الطلب' : 'Accept Order',
                  onPressed: () {
                    Navigator.pop(context);
                    _acceptOrder(order);
                  },
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.green.withOpacity(0.8)],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Future<void> _updateItemStatus(
    OfficeOrder order,
    int itemIndex,
    ItemStatus newStatus,
    String? notes,
  ) async {
    try {
      final updatedItems = List<OrderItem>.from(order.items);
      updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
        status: newStatus,
        notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      );

      final updateData = <String, dynamic>{
        'items': updatedItems.map((item) => item.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      final bool allItemsProcessed = updatedItems.every(
        (item) => item.status != ItemStatus.pending,
      );
      final bool hasUnavailableItems = updatedItems.any(
        (item) => item.status == ItemStatus.notAvailable,
      );

      if (allItemsProcessed &&
          hasUnavailableItems &&
          order.status == OrderStatus.inProgress) {
        updateData['status'] = OrderStatus.needsResponse
            .toString()
            .split('.')
            .last;

        final unavailableCount = updatedItems
            .where((item) => item.status == ItemStatus.notAvailable)
            .length;

        await NotificationService().notifyEmployeeResponseNeeded(
          employeeId: order.employeeId,
          orderId: order.id,
          officeBoyName: currentUser!.name,
          unavailableCount: unavailableCount,
          isArabic: _currentLocale == 'ar',
        );
      } else if (allItemsProcessed && !hasUnavailableItems) {
        await NotificationService().notifyEmployeeItemsStatusUpdated(
          employeeId: order.employeeId,
          orderId: order.id,
          officeBoyName: currentUser!.name,
          availableCount: updatedItems.length,
          unavailableCount: 0,
          isArabic: _currentLocale == 'ar',
        );
      }

      await _firebaseService.updateDocument('orders', order.id, updateData);
      showSuccessToast(
        context,
        _currentLocale == 'ar'
            ? 'تم تحديث حالة الصنف بنجاح'
            : 'Item status updated successfully',
      );
    } catch (e) {
      showErrorToast(
        context,
        _currentLocale == 'ar'
            ? 'فشل في تحديث حالة الصنف: $e'
            : 'Failed to update item status: $e',
      );
    }
  }

  void _showItemStatusBottomSheet(OfficeOrder order, int itemIndex) {
    final item = order.items[itemIndex];
    final TextEditingController notesController = TextEditingController(
      text: item.notes ?? '',
    );
    ItemStatus selectedStatus = item.status;

    _showGlassBottomSheet(
      context: context,
      heightFactor: 0.8,
      child: StatefulBuilder(
        builder: (context, setDialogState) => _buildItemStatusContent(
          order,
          itemIndex,
          item,
          notesController,
          selectedStatus,
          (newStatus) {
            setDialogState(() {
              selectedStatus = newStatus;
            });
          },
        ),
      ),
    );
  }

  Widget _buildItemStatusContent(
    OfficeOrder order,
    int itemIndex,
    OrderItem item,
    TextEditingController notesController,
    ItemStatus selectedStatus,
    Function(ItemStatus) onStatusChanged,
  ) {
    final locale = Localizations.localeOf(context).languageCode;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlassBottomSheetHeader(
            icon: Assets.imagesSvgsEdit,
            title: locale == 'ar' ? 'تحديث حالة الصنف' : 'Update Item Status',
            subtitle: item.name,
          ),

          SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale == 'ar' ? 'حالة الصنف' : 'Item Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),

                ...ItemStatus.values.map(
                  (status) => Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedStatus == status
                            ? _getItemStatusColor(status)
                            : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      color: selectedStatus == status
                          ? _getItemStatusColor(status).withOpacity(0.1)
                          : Colors.white.withOpacity(0.05),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          onStatusChanged(status);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getItemStatusColor(
                                    status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SvgPicture.asset(
                                  _getItemStatusIcon(status),
                                  color: _getItemStatusColor(status),
                                  height: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getItemStatusText(status),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: selectedStatus == status
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedStatus == status
                                        ? _getItemStatusColor(status)
                                        : Colors.white.withOpacity(0.5),
                                    width: 2,
                                  ),
                                  color: selectedStatus == status
                                      ? _getItemStatusColor(status)
                                      : Colors.transparent,
                                ),
                                child: selectedStatus == status
                                    ? Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                _buildGlassTextField(
                  controller: notesController,
                  label: locale == 'ar'
                      ? 'ملاحظات (اختياري)'
                      : 'Notes (optional)',
                  hint: locale == 'ar'
                      ? 'ضيف ملاحظات عن التوفر...'
                      : 'Add notes about availability...',
                  icon: Assets.imagesSvgsNote,
                ),

                SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _buildGlassButton(
                        text: locale == 'ar' ? 'إلغاء' : 'Cancel',
                        onPressed: () => Navigator.pop(context),
                        isSecondary: true,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildGlassButton(
                        text: locale == 'ar' ? 'تحديث الحالة' : 'Update Status',
                        onPressed: () async {
                          Navigator.pop(context);
                          await _updateItemStatus(
                            order,
                            itemIndex,
                            selectedStatus,
                            notesController.text.trim(),
                          );
                        },
                        gradient: LinearGradient(
                          colors: [
                            _getItemStatusColor(selectedStatus),
                            _getItemStatusColor(
                              selectedStatus,
                            ).withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

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
          updateData['final_price'] = finalPrice;
        }

        await NotificationService().notifyEmployeeOrderCompleted(
          employeeId: order.employeeId,
          orderId: order.id,
          officeBoyName: currentUser!.name,
          finalPrice: finalPrice,
          isArabic: _currentLocale == 'ar',
        );

        // ✅ NOTIFY ADMIN

        if (currentUser?.role == UserRole.admin) {
          await NotificationService().notifyAdminOrderCompleted(
            organizationId: order.organizationId,
            employeeName: order.employeeName,
            officeBoyName: currentUser!.name,
            finalPrice: finalPrice,
            isArabic: _currentLocale == 'ar',
          );
        }
      } else if (status == OrderStatus.cancelled) {
        // ✅ NOTIFY EMPLOYEE - ORDER CANCELLED
        await NotificationService().notifyEmployeeOrderCancelled(
          employeeId: order.employeeId,
          orderId: order.id,
          officeBoyName: currentUser!.name,
          reason: notes,
          isArabic: _currentLocale == 'ar',
        );

        // ✅ NOTIFY ADMIN
        if (currentUser?.role == UserRole.admin) {
          await NotificationService().notifyAdminOrderCancelled(
            organizationId: order.organizationId,
            employeeName: order.employeeName,
            officeBoyName: currentUser!.name,
            isArabic: _currentLocale == 'ar',
          );
        }
      } else if (status == OrderStatus.inProgress) {
        // ✅ NOTIFY EMPLOYEE - ORDER RESUMED
        await NotificationService().notifyEmployeeOrderInProgress(
          employeeId: order.employeeId,
          orderId: order.id,
          officeBoyName: currentUser!.name,
          isArabic: _currentLocale == 'ar',
        );

        // ✅ NOTIFY ADMIN
        if (currentUser?.role == UserRole.admin) {
          await NotificationService().notifyAdminOrderInProgress(
            organizationId: order.organizationId,
            orderId: order.id,
            officeBoyName: currentUser!.name,
            isArabic: _currentLocale == 'ar',
          );
        }
      }

      if (notes != null && notes.isNotEmpty) {
        updateData['notes'] = notes;
      }

      await _firebaseService.updateDocument('orders', order.id, updateData);

      showSuccessToast(
        context,
        _currentLocale == 'ar'
            ? 'تم ${_getOrderStatusText(status)} الطلب!'
            : 'Order ${status.toString().split('.').last}!',
      );
    } catch (e) {
      showErrorToast(
        context,
        _currentLocale == 'ar'
            ? 'فشل في تحديث الطلب: $e'
            : 'Failed to update order: $e',
      );
    }
  }

  void _showStatusChangeBottomSheet(OfficeOrder order, OrderStatus newStatus) {
    final TextEditingController notesController = TextEditingController();
    final bool isCancellation = newStatus == OrderStatus.cancelled;

    _showGlassBottomSheet(
      context: context,
      heightFactor: 0.6,
      child: _buildStatusChangeContent(
        order,
        newStatus,
        isCancellation,
        notesController,
      ),
    );
  }

  Widget _buildStatusChangeContent(
    OfficeOrder order,
    OrderStatus newStatus,
    bool isCancellation,
    TextEditingController notesController,
  ) {
    final locale = Localizations.localeOf(context).languageCode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGlassBottomSheetHeader(
          icon: isCancellation
              ? Assets.imagesSvgsCancell
              : Assets.imagesSvgsShoppingCart,
          title: locale == 'ar'
              ? '${_getOrderStatusText(newStatus)} الطلب'
              : '${newStatus.toString().split('.').last.toUpperCase()} Order',
          subtitle: locale == 'ar'
              ? 'متأكد إنك عايز ${_getOrderStatusActionText(newStatus)} الطلب ده؟'
              : 'Are you sure you want to ${newStatus.toString().split('.').last} this order?',
        ),

        SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              _buildGlassTextField(
                controller: notesController,
                label: locale == 'ar'
                    ? 'ضيف ملاحظات (اختياري)'
                    : 'Add notes (optional)',
                hint: locale == 'ar'
                    ? 'سبب ${_getOrderStatusActionText(newStatus)}...'
                    : 'Reason for ${newStatus.toString().split('.').last}...',
                icon: Assets.imagesSvgsNote,
              ),

              SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _buildGlassButton(
                      text: locale == 'ar' ? 'إلغاء' : 'Cancel',
                      onPressed: () => Navigator.pop(context),
                      isSecondary: true,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildGlassButton(
                      text: locale == 'ar'
                          ? _getOrderStatusActionText(newStatus)
                          : newStatus.toString().split('.').last.toUpperCase(),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _updateOrderWithNotes(
                          order,
                          newStatus,
                          notes: notesController.text.trim(),
                        );
                      },
                      gradient: LinearGradient(
                        colors: [
                          isCancellation ? Colors.red : Colors.blue,
                          isCancellation
                              ? Colors.red.withOpacity(0.8)
                              : Colors.blue.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCompletionBottomSheet(OfficeOrder order) {
    final TextEditingController priceController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    if (order.price != null) {
      priceController.text = order.price!.toStringAsFixed(0);
    }

    _showGlassBottomSheet(
      context: context,
      heightFactor: 0.7,
      child: StatefulBuilder(
        builder: (context, setState) => Form(
          key: formKey,
          child: _buildCompletionContent(
            order,
            priceController,
            notesController,
            formKey,
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionContent(
    OfficeOrder order,
    TextEditingController priceController,
    TextEditingController notesController,
    GlobalKey<FormState> formKey,
  ) {
    final locale = Localizations.localeOf(context).languageCode;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGlassBottomSheetHeader(
            icon: Assets.imagesSvgsComplete,
            title: locale == 'ar' ? 'إكمال الطلب' : 'Complete Order',
            subtitle: locale == 'ar'
                ? 'تعمل الطلب ده كمكتمل؟'
                : 'Mark this order as completed?',
          ),

          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                if (order.type == OrderType.external) ...[
                  _buildGlassTextField(
                    controller: priceController,
                    label: locale == 'ar'
                        ? 'السعر النهائي (ج.م) *'
                        : 'Final Price (EGP) *',
                    hint: locale == 'ar'
                        ? 'ادخل السعر الفعلي'
                        : 'Enter the actual price',
                    icon: Assets.imagesSvgsWallet,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return locale == 'ar'
                            ? 'يلزم تدخل السعر النهائي'
                            : 'Please enter the final price';
                      }
                      if (double.tryParse(value) == null) {
                        return locale == 'ar'
                            ? 'يلزم تدخل رقم صحيح'
                            : 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  if (order.price != null) ...[
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          locale == 'ar'
                              ? 'ال اتدفع: ج.م ${order.price!.toStringAsFixed(0)}'
                              : 'Paid: EGP ${order.price!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 16),
                ],

                _buildGlassTextField(
                  controller: notesController,
                  label: locale == 'ar'
                      ? 'ملاحظات الإكمال (اختياري)'
                      : 'Completion notes (optional)',
                  hint: locale == 'ar'
                      ? 'أي تفاصيل إضافية...'
                      : 'Any additional details...',
                  icon: Assets.imagesSvgsNote,
                  maxLines: 2,
                ),

                SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _buildGlassButton(
                        text: locale == 'ar' ? 'إلغاء' : 'Cancel',
                        onPressed: () => Navigator.pop(context),
                        isSecondary: true,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildGlassButton(
                        text: locale == 'ar' ? 'إكمال الطلب' : 'Complete Order',
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          double? finalPrice;
                          if (order.type == OrderType.external &&
                              priceController.text.trim().isNotEmpty) {
                            try {
                              finalPrice = double.parse(
                                priceController.text.trim(),
                              );
                            } catch (e) {
                              showErrorToast(
                                context,
                                locale == 'ar'
                                    ? 'يلزم تدخل سعر صحيح'
                                    : 'Please enter a valid price',
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
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.green.withOpacity(0.8)],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Glass Morphism Bottom Sheet Utility Methods
  void _showGlassBottomSheet({
    required BuildContext context,
    required Widget child,
    double heightFactor = 0.5,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          GlassBottomSheet(heightFactor: heightFactor, child: child),
    );
  }

  Widget _buildGlassBottomSheetHeader({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(icon, color: Colors.white, height: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
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

  Widget _buildGlassListItem({
    required VoidCallback onTap,
    required Widget leading,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                leading,
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                validator: validator,
                style: TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      icon,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required String text,
    required VoidCallback onPressed,
    bool isSecondary = false,
    Gradient? gradient,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isSecondary
            ? LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              )
            : gradient ??
                  LinearGradient(
                    colors: [
                      organization!.primaryColorValue,
                      organization!.secondaryColorValue,
                    ],
                  ),
        borderRadius: BorderRadius.circular(16),
        border: isSecondary
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
            : null,
        boxShadow: isSecondary
            ? null
            : [
                BoxShadow(
                  color:
                      (gradient?.colors.first ??
                              organization!.primaryColorValue)
                          .withOpacity(0.4),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSecondary ? Colors.white : textColor ?? Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getItemStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.pending:
        return Colors.orange;
      case ItemStatus.available:
        return Colors.greenAccent;
      case ItemStatus.notAvailable:
        return Colors.red;
    }
  }

  String _getItemStatusIcon(ItemStatus status) {
    switch (status) {
      case ItemStatus.pending:
        return Assets.imagesSvgsPending;
      case ItemStatus.available:
        return Assets.imagesSvgsComplete;
      case ItemStatus.notAvailable:
        return Assets.imagesSvgsCancell;
    }
  }

  String _getItemStatusText(ItemStatus status) {
    final locale = Localizations.localeOf(context).languageCode;

    switch (status) {
      case ItemStatus.pending:
        return locale == 'ar' ? 'قيد الفحص...' : 'Checking...';
      case ItemStatus.available:
        return locale == 'ar' ? 'متاح' : 'Available';
      case ItemStatus.notAvailable:
        return locale == 'ar' ? 'مش متاح' : 'Not Available';
    }
  }

  String _getOrderStatusText(OrderStatus status) {
    final locale = Localizations.localeOf(context).languageCode;

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
        return locale == 'ar' ? 'محتاج رد' : 'Needs Response';
    }
  }

  String _getOrderStatusActionText(OrderStatus status) {
    final locale = Localizations.localeOf(context).languageCode;

    switch (status) {
      case OrderStatus.pending:
        return locale == 'ar' ? 'انتظار' : 'Pending';
      case OrderStatus.inProgress:
        return locale == 'ar' ? 'بدء التنفيذ' : 'Start Progress';
      case OrderStatus.completed:
        return locale == 'ar' ? 'إكمال' : 'Complete';
      case OrderStatus.cancelled:
        return locale == 'ar' ? 'إلغاء' : 'Cancel';
      case OrderStatus.needsResponse:
        return locale == 'ar' ? 'طلب رد' : 'Request Response';
    }
  }

  String get _currentLocale => Localizations.localeOf(context).languageCode;

  void _showProfileBottomSheet() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return OfficeBoyProfileBottomSheet(
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
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          var scaleAnimation = Tween<double>(
            begin: 0.9,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          var fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return Stack(
            children: [
              FadeTransition(
                opacity: fadeAnimation,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
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

  void _showOrderDetailsBottomSheet(OfficeOrder order) {
    final bool canTransfer =
        order.status == OrderStatus.pending &&
        order.isSpecificallyAssigned &&
        order.specificallyAssignedOfficeBoyId == currentUser!.id &&
        otherOfficeBoys.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsBottomSheet(
        order: order,
        organization: organization!,
        isOfficeBoy: true,
        onStatusUpdate: _updateOrderWithNotes,
        otherOfficeBoys: otherOfficeBoys,
        onTransferRequest: canTransfer
            ? () {
                Navigator.pop(context);
                _showTransferBottomSheet(order);
              }
            : null,
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
      showErrorToast(
        context,
        _currentLocale == 'ar'
            ? 'فشل في تسجيل الخروج: $e'
            : 'Failed to logout: $e',
      );
    }
  }

  Color _getOrderTypeColor(OrderType type) {
    switch (type) {
      case OrderType.internal:
        return organization?.secondaryColorValue ?? Colors.blue;
      case OrderType.external:
        return organization?.primaryColorValue ?? Colors.orange;
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
      case OrderStatus.needsResponse:
        return Colors.purple;
    }
  }

  String _formatTime(DateTime dateTime) {
    final locale = Localizations.localeOf(context).languageCode;
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

  Widget _buildAnimatedHeader() {
    final locale = Localizations.localeOf(context).languageCode;

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
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
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
                          onPressed: _showNotificationBottomSheet,
                        ),

                        if (hasUnreadNotifications)
                          Positioned(
                            top: 2,
                            left: 24,
                            child: Container(
                              width: _unreadCount > 9 ? 20 : 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                                // border: Border.all(
                                //   color: Colors.white,
                                //   width: 1.5,
                                // ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _unreadCount > 9 ? 8 : 9,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
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
                                                child: Icon(
                                                  Icons.delivery_dining,
                                                  color: Colors.white,
                                                  size: 40,
                                                ),
                                              ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.delivery_dining,
                                      color: Colors.white,
                                      size: 40,
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
                            locale == 'ar'
                                ? 'أهلاً وسهلاً، ${currentUser?.name ?? ""}'
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
    final locale = Localizations.localeOf(context).languageCode;

    final navItems = (otherOfficeBoys.isNotEmpty)
        ? [
            {
              'title': locale == 'ar' ? 'طلباتي' : 'My Orders',
              'icon': Assets.imagesSvgsOrder,
            },
            {
              'title': locale == 'ar' ? 'المتاحة' : 'Available',
              'icon': Assets.imagesSvgsPending,
            },

            // {
            //   'title': locale == 'ar' ? 'الإحصائيات' : 'Statistics',
            //   'icon': Icons.analytics,
            // },
          ]
        : [
            {
              'title': locale == 'ar' ? 'طلباتي' : 'My Orders',
              'icon': Assets.imagesSvgsOrder,
            },
            // {
            //   'title': locale == 'ar' ? 'الإحصائيات' : 'Statistics',
            //   'icon': Icons.analytics,
            // },
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
                    padding: EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildItemManagementSection(OfficeOrder order) {
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: organization?.secondaryColorValue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: organization!.secondaryColorValue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: organization!.secondaryColorValue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.checklist, color: Colors.grey[700], size: 20),
              ),
              SizedBox(width: 12),
              Text(
                locale == 'ar' ? 'فحص توفر العناصر' : 'Item Availability Check',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...order.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(AppImages.pattern),
                  colorFilter: ColorFilter.mode(
                    _getItemStatusColor(item.status).withOpacity(.5),
                    BlendMode.modulate,
                  ),
                  fit: BoxFit.fill,
                ),
                border: Border.all(
                  color: _getItemStatusColor(item.status).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showItemStatusBottomSheet(order, index),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getItemStatusColor(
                              item.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SvgPicture.asset(
                            _getItemStatusIcon(item.status),
                            height: 20,
                            color: _getItemStatusColor(item.status),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (item.notes != null &&
                                  item.notes!.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Text(
                                  item.notes!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getItemStatusColor(
                                    item.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getItemStatusText(item.status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _getItemStatusColor(item.status),
                                  ),
                                ),
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
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnimatedEmptyState(String message, String icon) {
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

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

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
                    locale == 'ar'
                        ? 'خطأ في تحميل البيانات'
                        : 'Error loading data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    errorMessage ??
                        (locale == 'ar' ? 'خطأ غير معروف' : 'Unknown error'),
                  ),
                  SizedBox(height: 16),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: ElevatedButton(
                      onPressed: _loadData,
                      child: Text(locale == 'ar' ? 'إعادة المحاولة' : 'Retry'),
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
      duration: Duration(milliseconds: 100),
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
        return _buildMyOrdersTab();
      case 1:
        return _buildAvailableOrdersTab();
      case 2:
        return _buildStatsTab();
      default:
        return _buildAvailableOrdersTab();
    }
  }

  Widget _buildAvailableOrdersTab() {
    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  locale == 'ar' ? 'المتاحة' : 'Available',
                  availableOrders.length.toString(),
                  Assets.imagesSvgsPending,
                  organization!.primaryColorValue,
                  organization!.secondaryColorValue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  locale == 'ar' ? 'النشطة عندي' : 'My Active',
                  myOrders
                      .where((o) => o.status != OrderStatus.completed)
                      .length
                      .toString(),
                  Assets.imagesSvgsShoppingCart,
                  organization!.primaryColorValue,
                  organization!.secondaryColorValue,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          if (availableOrders.isEmpty)
            _buildAnimatedEmptyState(
              locale == 'ar' ? 'مفيش طلبات متاحة' : 'No available orders',
              Assets.imagesSvgsEdit,
            )
          else
            ...availableOrders.asMap().entries.map(
              (entry) => _buildAvailableOrderCard(entry.value, entry.key),
            ),
        ],
      ),
    );
  }

  Widget _buildMyOrdersTab() {
    final locale = Localizations.localeOf(context).languageCode;

    final todayMyOrders = myOrders
        .where(
          (o) =>
              o.createdAt.day == DateTime.now().day &&
              o.createdAt.month == DateTime.now().month &&
              o.createdAt.year == DateTime.now().year,
        )
        .toList();

    final todayBudgetPrice = todayMyOrders
        .where((o) => o.price != null)
        .fold<double>(0.0, (summ, o) => summ + o.price!);

    final todayFinalPrice = todayMyOrders
        .where((o) => o.finalPrice != null)
        .fold<double>(0.0, (summ, o) => summ + o.finalPrice!);

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        Assets.imagesSvgsWallet,
                        color: Colors.white,
                        height: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${locale == 'ar' ? 'ج.م' : 'EGP'} ${todayBudgetPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        locale == 'ar'
                            ? 'ال اتدفع النهاردة'
                            : 'Today\'s Budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        Assets.imagesSvgsMoney,
                        color: Colors.white,
                        height: 24,
                      ),

                      SizedBox(height: 8),
                      Text(
                        '${locale == 'ar' ? 'ج.م' : 'EGP'} ${todayFinalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        locale == 'ar' ? 'ال اتصرف النهاردة' : 'Today\'s Spent',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  locale == 'ar' ? 'قيد التنفيذ' : 'In Progress',
                  myOrders
                      .where((o) => o.status == OrderStatus.inProgress)
                      .length
                      .toString(),
                  Assets.imagesSvgsPending,
                  organization!.primaryColorValue,
                  organization!.secondaryColorValue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  locale == 'ar' ? 'المكتملة' : 'Completed',
                  myOrders
                      .where((o) => o.status == OrderStatus.completed)
                      .length
                      .toString(),
                  Assets.imagesSvgsComplete,
                  organization!.primaryColorValue,
                  organization!.secondaryColorValue,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text(
            locale == 'ar' ? 'طلباتي' : 'My Orders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          if (myOrders.isEmpty)
            _buildAnimatedEmptyState(
              locale == 'ar' ? 'مفيش طلبات معادة ليك' : 'No orders assigned',
              Assets.imagesSvgsShoppingCart,
            )
          else
            ...myOrders.asMap().entries.map(
              (entry) => Column(
                children: [
                  _buildMyOrderCard(entry.value, entry.key),
                  if (entry.value.status == OrderStatus.inProgress)
                    _buildItemManagementSection(entry.value),
                  _buildQuickStatusActions(entry.value),
                  SizedBox(height: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final locale = Localizations.localeOf(context).languageCode;

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
    final needsResponseOrders = myOrders
        .where((o) => o.status == OrderStatus.needsResponse)
        .length;

    final todayOrders = myOrders
        .where(
          (o) =>
              o.createdAt.day == DateTime.now().day &&
              o.createdAt.month == DateTime.now().month &&
              o.createdAt.year == DateTime.now().year,
        )
        .toList();

    final todayBudgetPrice = todayOrders
        .where((o) => o.price != null)
        .fold<double>(0.0, (sum, o) => sum + o.price!);

    final todayFinalPrice = todayOrders
        .where((o) => o.finalPrice != null)
        .fold<double>(0.0, (sum, o) => sum + o.finalPrice!);

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale == 'ar' ? 'إحصائياتي' : 'My Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        Assets.imagesSvgsWallet,
                        height: 24,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${locale == 'ar' ? 'ج.م' : 'EGP'} ${todayBudgetPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        locale == 'ar' ? 'ال اتدفعالنهاردة' : 'Today\'s Budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        Assets.imagesSvgsMoney,
                        color: Colors.white,
                        height: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${locale == 'ar' ? 'ج.م' : 'EGP'} ${todayFinalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        locale == 'ar' ? 'ال اتصرف النهاردة' : 'Today\'s Spent',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                locale == 'ar' ? 'إجمالي الطلبات' : 'Total Orders',
                totalOrders.toString(),
                Assets.imagesSvgsOrder,
                organization!.primaryColorValue,
                organization!.secondaryColorValue,
              ),
              _buildStatCard(
                locale == 'ar' ? 'طلبات النهاردة' : 'Today\'s Orders',
                todayOrders.length.toString(),
                Assets.imagesSvgsCalendar,
                organization!.primaryColorValue,
                organization!.secondaryColorValue,
              ),
              _buildStatCard(
                locale == 'ar' ? 'المكتملة' : 'Completed',
                completedOrders.toString(),
                Assets.imagesSvgsComplete,
                organization!.primaryColorValue,
                organization!.secondaryColorValue,
              ),
              _buildStatCard(
                locale == 'ar' ? 'قيد التنفيذ' : 'In Progress',
                inProgressOrders.toString(),
                Assets.imagesSvgsPending,
                organization!.primaryColorValue,
                organization!.secondaryColorValue,
              ),
              _buildStatCard(
                locale == 'ar' ? 'محتاجة رد' : 'Needs Response',
                needsResponseOrders.toString(),
                Assets.imagesSvgsNote,
                organization!.primaryColorValue,
                organization!.secondaryColorValue,
              ),
              _buildStatCard(
                locale == 'ar' ? 'الملغية' : 'Cancelled',
                cancelledOrders.toString(),
                Assets.imagesSvgsCancell,
                organization!.primaryColorValue,
                organization!.secondaryColorValue,
              ),
            ],
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAvailableOrderCard(OfficeOrder order, int index) {
    final locale = Localizations.localeOf(context).languageCode;

    final isSpecificallyAssignedToMe =
        order.isSpecificallyAssigned &&
        order.specificallyAssignedOfficeBoyId == currentUser!.id;

    final isSpecificallyAssignedToOther =
        order.isSpecificallyAssigned &&
        order.specificallyAssignedOfficeBoyId != currentUser!.id;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(50 * (1 - value), 0),
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSpecificallyAssignedToMe
                ? Border.all(color: Colors.orange, width: 2)
                : Border.all(
                    color: organization!.secondaryColorValue.withOpacity(0.2),
                    width: 1,
                  ),
            boxShadow: [
              BoxShadow(
                color: isSpecificallyAssignedToMe
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.black.withOpacity(0.08),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: !isSpecificallyAssignedToOther
                  ? () => _showOrderDetailsBottomSheet(order)
                  : null,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSpecificallyAssignedToMe)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withOpacity(0.2),
                              Colors.orange.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.orange),
                            SizedBox(width: 6),
                            Text(
                              locale == 'ar'
                                  ? 'معادة ليك بالتحديد'
                                  : 'Specifically Assigned to You',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!isSpecificallyAssignedToOther) ...[
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _getOrderTypeColor(
                                order.type,
                              ).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getOrderTypeColor(
                                  order.type,
                                ).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              order.type == OrderType.internal
                                  ? (locale == 'ar' ? 'داخلي' : 'Internal')
                                  : (locale == 'ar' ? 'خارجي' : 'External'),
                              style: TextStyle(
                                color: _getOrderTypeColor(order.type),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (order.items.length > 1) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.list_alt,
                                    size: 12,
                                    color: Colors.grey[700],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${order.items.length} ${locale == 'ar' ? 'عناصر' : 'items'}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _formatTime(order.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getOrderTypeColor(
                                    order.type,
                                  ).withOpacity(0.2),
                                  _getOrderTypeColor(
                                    order.type,
                                  ).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _getOrderTypeColor(
                                  order.type,
                                ).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                order.type == OrderType.internal
                                    ? Assets.imagesSvgsCompany
                                    : Assets.imagesSvgsShoppingCart,
                                color: _getOrderTypeColor(order.type),
                                height: 28,
                              ),
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.items.length == 1
                                      ? order.items.first.name
                                      : '${order.items.first.name} + ${order.items.length - 1} ${locale == 'ar' ? 'اكتر' : 'more'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (order.description.isNotEmpty) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    order.description,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (order.isFromAdmin)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.admin_panel_settings,
                                              size: 14,
                                              color: Colors.orange,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              locale == 'ar'
                                                  ? 'المدير'
                                                  : 'Boss',
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: organization!
                                              .secondaryColorValue
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.person,
                                              size: 14,
                                              color: Colors.grey[700],
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              order.employeeName,
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (order.price != null) ...[
                                      Spacer(),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.green.withOpacity(0.2),
                                              Colors.green.withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SvgPicture.asset(
                                              Assets.imagesSvgsWallet,
                                              height: 24,
                                              color: Colors.green[700],
                                            ),

                                            SizedBox(width: 4),
                                            Text(
                                              '${locale == 'ar' ? 'ج.م' : 'EGP'} ${order.price!.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
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
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSpecificallyAssignedToMe
                              ? () =>
                                    _showSpecificallyAssignedBottomSheet(order)
                              : () => _acceptOrder(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSpecificallyAssignedToMe
                                ? Colors.orange
                                : organization!.primaryColorValue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                isSpecificallyAssignedToMe
                                    ? Assets.imagesSvgsShoppingCart
                                    : Assets.imagesSvgsComplete,
                                height: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                isSpecificallyAssignedToMe
                                    ? (locale == 'ar'
                                          ? 'شوف المهمة'
                                          : 'View Assignment')
                                    : (locale == 'ar'
                                          ? 'قبول الطلب'
                                          : 'Accept Order'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.lock_outline,
                                  color: Colors.grey[600],
                                  size: 32,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                locale == 'ar'
                                    ? 'الطلب ده معاد لأوفيس بوي تاني'
                                    : 'This order is specifically assigned\nto another office boy',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
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
    );
  }

  Widget _buildMyOrderCard(OfficeOrder order, int index) {
    final locale = Localizations.localeOf(context).languageCode;

    final bool canTransfer =
        order.status == OrderStatus.pending &&
        order.isSpecificallyAssigned &&
        order.specificallyAssignedOfficeBoyId == currentUser!.id;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(50 * (1 - value), 0),
        child: GestureDetector(
          onTap: () => _showOrderDetailsBottomSheet(order),
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: canTransfer
                  ? Border.all(color: Colors.orange.withOpacity(0.5), width: 2)
                  : Border.all(
                      color: organization!.secondaryColorValue.withOpacity(0.2),
                      width: 1,
                    ),
              boxShadow: [
                BoxShadow(
                  color: canTransfer
                      ? Colors.orange.withOpacity(0.15)
                      : Colors.black.withOpacity(0.08),
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
            child: Padding(
              padding: EdgeInsets.all(16),
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
                          color: _getOrderStatusColor(
                            order.status,
                          ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getOrderStatusColor(
                              order.status,
                            ).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getOrderStatusText(order.status).toUpperCase(),
                          style: TextStyle(
                            color: _getOrderStatusColor(order.status),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _getOrderTypeColor(
                            order.type,
                          ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getOrderTypeColor(
                              order.type,
                            ).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          order.type == OrderType.internal
                              ? (locale == 'ar' ? 'داخلي' : 'Internal')
                              : (locale == 'ar' ? 'خارجي' : 'External'),
                          style: TextStyle(
                            color: _getOrderTypeColor(order.type),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (canTransfer) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.withOpacity(0.2),
                                Colors.orange.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.swap_horiz,
                                size: 12,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 4),
                              Text(
                                locale == 'ar' ? 'تقدر تحولها' : 'Can Transfer',
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getOrderStatusColor(
                                order.status,
                              ).withOpacity(0.2),
                              _getOrderStatusColor(
                                order.status,
                              ).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _getOrderStatusColor(
                              order.status,
                            ).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            order.status == OrderStatus.completed
                                ? Assets.imagesSvgsComplete
                                : order.status == OrderStatus.needsResponse
                                ? Assets.imagesSvgsNote
                                : order.type == OrderType.internal
                                ? Assets.imagesSvgsCompany
                                : Assets.imagesSvgsShoppingCart,
                            color: _getOrderStatusColor(order.status),
                            height: 28,
                            fit: BoxFit.scaleDown,
                          ),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.items.length == 1
                                  ? order.items.first.name
                                  : '${order.items.first.name} + ${order.items.length - 1} ${locale == 'ar' ? 'اكتر' : 'more'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (order.description.isNotEmpty) ...[
                              SizedBox(height: 4),
                              Text(
                                order.description,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            SizedBox(height: 6),
                            Row(
                              children: [
                                if (order.isFromAdmin)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.admin_panel_settings,
                                          size: 14,
                                          color: Colors.orange,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          locale == 'ar' ? 'المدير' : 'Boss',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: organization!.secondaryColorValue
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 14,
                                          color: Colors.grey[700],
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          order.employeeName,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
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
                                          '${locale == 'ar' ? 'ال اتدفع' : 'Paid'}: ${locale == 'ar' ? 'ج.م' : 'EGP'} ${order.price!.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 11,
                                          ),
                                        ),
                                      if (order.finalPrice != null)
                                        Text(
                                          '${locale == 'ar' ? 'ال اتصرف' : 'Spent'}: ${locale == 'ar' ? 'ج.م' : 'EGP'} ${order.finalPrice!.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: organization!
                                                .secondaryColorValue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      if (order.price != null &&
                                          order.finalPrice != null)
                                        if (order.finalPrice! > order.price!)
                                          Text(
                                            '${locale == 'ar' ? 'ليك' : 'For You'}: ${locale == 'ar' ? 'ج.م' : 'EGP'} ${(order.finalPrice! - order.price!).toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        else
                                          Text(
                                            '${locale == 'ar' ? 'مطلوب' : 'Required'}: ${locale == 'ar' ? 'ج.م' : 'EGP'} ${(order.price! - order.finalPrice!).toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: Colors.red,
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
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              _formatTime(order.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
    );
  }

  Widget _buildQuickStatusActions(OfficeOrder order) {
    final locale = Localizations.localeOf(context).languageCode;

    final bool canTransfer =
        order.status == OrderStatus.pending &&
        order.isSpecificallyAssigned &&
        order.specificallyAssignedOfficeBoyId == currentUser!.id &&
        otherOfficeBoys.isNotEmpty;

    if (order.status == OrderStatus.completed ||
        order.status == OrderStatus.cancelled) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              if (order.status == OrderStatus.pending) ...[
                // Expanded(
                //   child: ElevatedButton.icon(
                //     onPressed: () => _showStatusChangeBottomSheet(
                //       order,
                //       OrderStatus.cancelled,
                //     ),
                //     icon: SvgPicture.asset(
                //       Assets.imagesSvgsCancell,
                //       color: Colors.red[700],
                //       height: 18,
                //     ),
                //     label: Text(locale == 'ar' ? 'إلغاء' : 'Cancel'),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.red[50],
                //       foregroundColor: Colors.red[700],
                //       elevation: 0,
                //       padding: EdgeInsets.symmetric(vertical: 14),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //     ),
                //   ),
                // ),
                // SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _showStatusChangeBottomSheet(
                      order,
                      OrderStatus.inProgress,
                    ),
                    icon: Icon(Icons.delivery_dining_rounded, size: 18),
                    label: Text(
                      locale == 'ar' ? 'اقبل وابدا' : 'Accept & Start',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              if (order.status == OrderStatus.inProgress) ...[
                // Expanded(
                //   child: ElevatedButton.icon(
                //     onPressed: () => _showStatusChangeBottomSheet(
                //       order,
                //       OrderStatus.cancelled,
                //     ),
                //     icon: SvgPicture.asset(
                //       Assets.imagesSvgsCancell,
                //       color: Colors.red[700],
                //       height: 18,
                //     ),
                //     label: Text(locale == 'ar' ? 'إلغاء' : 'Cancel'),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.red[50],
                //       foregroundColor: Colors.red[700],
                //       elevation: 0,
                //       padding: EdgeInsets.symmetric(vertical: 14),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //     ),
                //   ),
                // ),
                // SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCompletionBottomSheet(order),
                    icon: SvgPicture.asset(
                      Assets.imagesSvgsComplete,
                      color: Colors.white,
                      height: 18,
                    ),
                    label: Text(locale == 'ar' ? 'إكمال' : 'Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (canTransfer)
            Container(
              margin: EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showTransferBottomSheet(order),
                  icon: Icon(Icons.swap_horiz, size: 18),
                  label: Text(
                    locale == 'ar'
                        ? 'حولها لأوفيس بوي تاني'
                        : 'Transfer to Another Office Boy',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String icon,
    Color color,
    Color textColor,
  ) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius:
                  8 + (math.sin(_pulseController.value * 2 * math.pi) * 2),
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
          image: DecorationImage(
            image: AssetImage(AppImages.pattern),
            colorFilter: ColorFilter.mode(
              textColor.withOpacity(.5),
              BlendMode.modulate,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Transform.rotate(
                    angle: math.sin(_pulseController.value * 2 * math.pi) * 0.1,
                    child: SvgPicture.asset(icon, color: color, height: 20),
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [textColor, color],
                  ).createShader(bounds),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Glass Bottom Sheet Widget
class GlassBottomSheet extends StatelessWidget {
  final double heightFactor;
  final Widget child;

  const GlassBottomSheet({
    super.key,
    required this.heightFactor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * heightFactor,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.025),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: CustomPaint(painter: GlassParticlesPainter()),
            ),
          ),

          // Glass morphism content
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
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
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Glass Particles Painter
class GlassParticlesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.05);

    // Draw floating particles
    for (int i = 0; i < 15; i++) {
      final x = (i % 4) * size.width / 4 + math.Random().nextDouble() * 30;
      final y = size.height * math.Random().nextDouble() * 0.8;
      final radius = 1 + math.Random().nextDouble() * 2;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw gradient orbs
    for (int i = 0; i < 5; i++) {
      final centerX = (i + 0.5) * size.width / 5;
      final centerY =
          size.height * 0.3 + math.Random().nextDouble() * size.height * 0.4;
      final radius = 20 + math.Random().nextDouble() * 30;

      final gradient = RadialGradient(
        colors: [Colors.white.withOpacity(0.03), Colors.transparent],
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

// Particle Painter for Header
class AnimatedParticlesPainter extends CustomPainter {
  final double animationValue;
  final double rotationValue;

  AnimatedParticlesPainter(this.animationValue, this.rotationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

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

// Shimmer Loading
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
