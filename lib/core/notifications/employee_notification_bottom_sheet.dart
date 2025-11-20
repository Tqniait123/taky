// widgets/notification_bottom_sheet.dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taqy/core/notifications/notification_model.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/employee/data/models/organization_model.dart';
import 'package:taqy/features/employee/data/models/user_model.dart';

class EmployeeNotificationBottomSheet extends StatefulWidget {
  final EmployeeOrganization organization;
  final String userId;
  final UserRole userRole;
  final VoidCallback? onNotificationsUpdated;

  const EmployeeNotificationBottomSheet({
    super.key,
    required this.organization,
    required this.userId,
    required this.userRole,
    this.onNotificationsUpdated,
  });

  @override
  State<EmployeeNotificationBottomSheet> createState() =>
      _EmployeeNotificationBottomSheetState();
}

class _EmployeeNotificationBottomSheetState
    extends State<EmployeeNotificationBottomSheet>
    with TickerProviderStateMixin {
  List<AppNotification> notifications = [];
  bool isLoading = true;
  bool hasUnreadNotifications = false;

  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      setState(() {
        notifications = snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList();
        hasUnreadNotifications = notifications.any((n) => !n.isRead);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId, String locale) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      setState(() {
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index] = notifications[index].copyWith(isRead: true);
        }
        hasUnreadNotifications = notifications.any((n) => !n.isRead);
      });

      // Notify parent about the update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onNotificationsUpdated?.call();
      });

      showSuccessToast(
        context,
        locale == 'ar' ? 'تم تحديد الإشعار كمقروء' : 'Marked as read',
      );
    } catch (e) {
      print('Error marking notification as read: $e');
      showErrorToast(
        context,
        locale == 'ar' ? 'فشل تحديد الإشعار كمقروء' : 'Failed to mark as read',
      );
    }
  }

  Future<void> _markAsUnread(String notificationId, String locale) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': false});

      setState(() {
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index] = notifications[index].copyWith(isRead: false);
        }
        hasUnreadNotifications = notifications.any((n) => !n.isRead);
      });

      widget.onNotificationsUpdated?.call();
      showSuccessToast(
        context,
        locale == 'ar' ? 'تم تحديد الإشعار كغير مقروء' : 'Marked as unread',
      );
    } catch (e) {
      print('Error marking notification as unread: $e');
      showErrorToast(
        context,
        locale == 'ar'
            ? 'فشل تحديد الإشعار كغير مقروء'
            : 'Failed to mark as unread',
      );
    }
  }

  Future<void> _markAllAsRead(String locale) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final unreadNotifications = notifications.where((n) => !n.isRead);

      for (final notification in unreadNotifications) {
        final docRef = FirebaseFirestore.instance
            .collection('notifications')
            .doc(notification.id);
        batch.update(docRef, {'isRead': true});
      }

      await batch.commit();

      setState(() {
        notifications = notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        hasUnreadNotifications = false;
      });

      // Notify parent about the update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onNotificationsUpdated?.call();
      });

      showSuccessToast(
        context,
        locale == 'ar'
            ? 'تم تحديد جميع الإشعارات كمقروءة'
            : 'All notifications marked as read',
      );
    } catch (e) {
      print('Error marking all notifications as read: $e');
      showErrorToast(
        context,
        locale == 'ar'
            ? 'فشل تحديد جميع الإشعارات كمقروءة'
            : 'Failed to mark all as read',
      );
    }
  }

  Future<void> _deleteNotification(String notificationId, String locale) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();

      setState(() {
        notifications.removeWhere((n) => n.id == notificationId);
      });

      showSuccessToast(
        context,
        locale == 'ar' ? 'تم حذف الإشعار' : 'Notification deleted',
      );
    } catch (e) {
      print('Error deleting notification: $e');
      showErrorToast(
        context,
        locale == 'ar' ? 'فشل حذف الإشعار' : 'Failed to delete notification',
      );
    }
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  void _startAnimations() {
    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
    _glowController.repeat(reverse: true);
    _particleController.repeat();
    _shimmerController.repeat(reverse: true);
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.orderCreated:
        return Colors.blue;
      case NotificationType.orderAccepted:
        return Colors.green;
      case NotificationType.orderCompleted:
        return Colors.greenAccent;
      case NotificationType.orderCancelled:
        return Colors.red;
      case NotificationType.orderNeedsResponse:
        return Colors.orange;
      case NotificationType.orderTransferred:
        return Colors.purple;
      case NotificationType.itemStatusUpdated:
        return Colors.blueAccent;
      case NotificationType.systemAlert:
        return Colors.amber;
      case NotificationType.info:
        return Colors.grey;
    }
  }

  String _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderCreated:
        return Assets.imagesSvgsOrder;
      case NotificationType.orderAccepted:
        return Assets.imagesSvgsComplete;
      case NotificationType.orderCompleted:
        return Assets.imagesSvgsComplete;
      case NotificationType.orderCancelled:
        return Assets.imagesSvgsCancell;
      case NotificationType.orderNeedsResponse:
        return Assets.imagesSvgsNote;
      case NotificationType.orderTransferred:
        return Assets.imagesSvgsEdit;
      case NotificationType.itemStatusUpdated:
        return Assets.imagesSvgsShoppingCart;
      case NotificationType.systemAlert:
        return Assets.imagesSvgsInfo;
      case NotificationType.info:
        return Assets.imagesSvgsInfo;
    }
  }

  String _formatTime(DateTime dateTime, String locale) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return locale == 'ar' ? 'الآن' : 'Just now';
    } else if (difference.inMinutes < 60) {
      return locale == 'ar'
          ? 'قبل ${difference.inMinutes} دقيقة'
          : '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return locale == 'ar'
          ? 'قبل ${difference.inHours} ساعة'
          : '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return locale == 'ar'
          ? 'قبل ${difference.inDays} يوم'
          : '${difference.inDays}d ago';
    } else {
      return locale == 'ar'
          ? '${dateTime.day}/${dateTime.month}/${dateTime.year}'
          : '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> _vibrate() async {
    // Haptic feedback for better UX
    try {
      // HapticFeedback.mediumImpact();
    } catch (e) {
      // Fallback if haptic feedback is not available
    }
  }

  // void _showNotificationDetails(AppNotification notification, String locale) {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     isScrollControlled: true,
  //     builder: (context) => _buildNotificationDetailSheet(notification, locale),
  //   );
  // }

  // Widget _buildNotificationDetailSheet(
  //   AppNotification notification,
  //   String locale,
  // ) {
  //   return Container(
  //     margin: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(25),
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           Colors.white.withOpacity(0.25),
  //           Colors.white.withOpacity(0.1),
  //         ],
  //       ),
  //     ),
  //     child: ClipRRect(
  //       borderRadius: BorderRadius.circular(25),
  //       child: BackdropFilter(
  //         filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
  //         child: Padding(
  //           padding: const EdgeInsets.all(24),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               // Header
  //               Row(
  //                 children: [
  //                   Container(
  //                     width: 50,
  //                     height: 50,
  //                     decoration: BoxDecoration(
  //                       gradient: RadialGradient(
  //                         colors: [
  //                           _getNotificationColor(
  //                             notification.type,
  //                           ).withOpacity(0.3),
  //                           _getNotificationColor(
  //                             notification.type,
  //                           ).withOpacity(0.1),
  //                         ],
  //                       ),
  //                       borderRadius: BorderRadius.circular(15),
  //                       border: Border.all(
  //                         color: _getNotificationColor(
  //                           notification.type,
  //                         ).withOpacity(0.5),
  //                         width: 2,
  //                       ),
  //                     ),
  //                     child: Center(
  //                       child: SvgPicture.asset(
  //                         _getNotificationIcon(notification.type),
  //                         color: _getNotificationColor(notification.type),
  //                         height: 24,
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 16),
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           notification.title,
  //                           style: const TextStyle(
  //                             color: Colors.white,
  //                             fontSize: 18,
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                         Text(
  //                           _formatTime(notification.createdAt, locale),
  //                           style: TextStyle(
  //                             color: Colors.white.withOpacity(0.7),
  //                             fontSize: 12,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 20),

  //               // Body
  //               Text(
  //                 notification.body,
  //                 style: TextStyle(
  //                   color: Colors.white.withOpacity(0.9),
  //                   fontSize: 16,
  //                   height: 1.5,
  //                 ),
  //               ),
  //               const SizedBox(height: 20),

  //               // Actions
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: ElevatedButton(
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: Colors.white.withOpacity(0.1),
  //                         foregroundColor: Colors.white,
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(15),
  //                           side: BorderSide(
  //                             color: Colors.white.withOpacity(0.3),
  //                           ),
  //                         ),
  //                         padding: const EdgeInsets.symmetric(vertical: 12),
  //                       ),
  //                       onPressed: () => Navigator.pop(context),
  //                       child: Text(locale == 'ar' ? 'إغلاق' : 'Close'),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 12),
  //                   Expanded(
  //                     child: ElevatedButton(
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: _getNotificationColor(
  //                           notification.type,
  //                         ).withOpacity(0.3),
  //                         foregroundColor: Colors.white,
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(15),
  //                         ),
  //                         padding: const EdgeInsets.symmetric(vertical: 12),
  //                       ),
  //                       onPressed: () {
  //                         Navigator.pop(context);
  //                         // Handle primary action based on notification type
  //                       },
  //                       child: Text(
  //                         locale == 'ar' ? 'عرض الطلب' : 'View Order',
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Future<void> _showDeleteConfirmation(
    AppNotification notification,
    String locale,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.1),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Warning icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.delete_rounded,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    locale == 'ar' ? 'حذف الإشعار؟' : 'Delete Notification?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    locale == 'ar'
                        ? 'لا يمكن التراجع عن هذا الإجراء. سيتم إزالة الإشعار نهائيًا.'
                        : 'This action cannot be undone. The notification will be permanently removed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(locale == 'ar' ? 'إلغاء' : 'Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(locale == 'ar' ? 'حذف' : 'Delete'),
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

    if (result == true) {
      await _deleteNotification(notification.id, locale);
    }
  }

  Widget _buildGlassMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String locale,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          // Icon container with glow effect
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  iconColor.withOpacity(0.3),
                  iconColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconColor.withOpacity(0.4), width: 1.5),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Chevron icon
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withOpacity(0.5),
            size: 16,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _slideController,
        _fadeController,
        _scaleController,
      ]),
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          MediaQuery.of(context).size.height * 0.1 * _slideAnimation.value,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  // Animated background with particles
                  Positioned.fill(child: _buildAnimatedBackground()),

                  // Glass morphism container
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
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
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
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
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_particleController, _shimmerController]),
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.organization.primaryColorValue.withOpacity(0.1),
              widget.organization.secondaryColorValue.withOpacity(0.1),
              widget.organization.primaryColorValue.withOpacity(0.05),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: CustomPaint(
          painter: _NotificationParticlesPainter(
            _particleAnimation.value,
            widget.organization.primaryColorValue,
            widget.organization.secondaryColorValue,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildContent(String locale) {
    return Column(
      children: [
        _buildGlassHeader(locale),
        if (hasUnreadNotifications && notifications.isNotEmpty)
          _buildMarkAllAsReadButton(locale),
        Expanded(
          child: isLoading
              ? _buildLoadingState(locale)
              : notifications.isEmpty
              ? _buildEmptyState(locale)
              : _buildNotificationsList(locale),
        ),
      ],
    );
  }

  Widget _buildGlassHeader(String locale) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, -50 * (1 - value)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Handle bar with glow effect
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) => Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(
                          0.3 + (_glowAnimation.value * 0.4),
                        ),
                        Colors.white.withOpacity(
                          0.3 + (_glowAnimation.value * 0.4),
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: widget.organization.primaryColorValue
                            .withOpacity(_glowAnimation.value * 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                children: [
                  // Animated title with shimmer effect
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale == 'ar' ? 'الإشعارات' : 'Notifications',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locale == 'ar'
                              ? '${notifications.length} إشعار'
                              : '${notifications.length} notifications',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Animated close button
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) => Transform.scale(
                      scale: value,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) => Container(
                            padding: const EdgeInsets.all(12),
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
                            child: Icon(
                              Icons.close,
                              color: Colors.white.withOpacity(0.9),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildMarkAllAsReadButton(String locale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: locale == 'ar'
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => _markAllAsRead(locale),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.organization.primaryColorValue.withOpacity(0.2),
                  widget.organization.secondaryColorValue.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              locale == 'ar' ? 'تحديد الكل كمقروء' : 'Mark all as read',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(String locale) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => _buildNotificationShimmer(index),
    );
  }

  Widget _buildNotificationShimmer(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 50,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            locale == 'ar' ? 'لا توجد إشعارات' : 'No notifications',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            locale == 'ar'
                ? 'سيظهر هنا الإشعارات الجديدة'
                : 'New notifications will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(String locale) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification, index, locale);
      },
    );
  }

  Widget _buildNotificationCard(
    AppNotification notification,
    int index,
    String locale,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(50 * (1 - value), 0),
        child: Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.3),
                  Colors.red.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: locale == 'ar'
                ? Alignment.centerLeft
                : Alignment.centerRight,
            padding: locale == 'ar'
                ? const EdgeInsets.only(left: 20)
                : const EdgeInsets.only(right: 20),
            child: Icon(
              Icons.delete_rounded,
              color: Colors.red.withOpacity(0.8),
              size: 24,
            ),
          ),
          onDismissed: (direction) =>
              _deleteNotification(notification.id, locale),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(notification.isRead ? 0.05 : 0.15),
                  Colors.white.withOpacity(notification.isRead ? 0.02 : 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notification.isRead
                    ? Colors.white.withOpacity(0.1)
                    : _getNotificationColor(notification.type).withOpacity(0.3),
                width: notification.isRead ? 1 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (!notification.isRead) {
                    _markAsRead(notification.id, locale);
                  }
                  // _showNotificationDetails(notification, locale);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notification icon with status indicator
                      Stack(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  _getNotificationColor(
                                    notification.type,
                                  ).withOpacity(0.3),
                                  _getNotificationColor(
                                    notification.type,
                                  ).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _getNotificationColor(
                                  notification.type,
                                ).withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                _getNotificationIcon(notification.type),
                                color: _getNotificationColor(notification.type),
                                height: 22,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: widget.organization.primaryColorValue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Notification content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notification.body,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(notification.createdAt, locale),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Enhanced Popup Menu Button with Glass Morphism
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        offset: const Offset(0, 10),
                        itemBuilder: (context) => [
                          // Mark as Read/Unread option
                          PopupMenuItem(
                            value: notification.isRead
                                ? 'mark_unread'
                                : 'mark_read',
                            child: _buildGlassMenuItem(
                              icon: notification.isRead
                                  ? Icons.mark_email_unread_rounded
                                  : Icons.mark_email_read_rounded,
                              iconColor: notification.isRead
                                  ? Colors.blue
                                  : Colors.green,
                              title: notification.isRead
                                  ? (locale == 'ar'
                                        ? 'تحديد كغير مقروء'
                                        : 'Mark as unread')
                                  : (locale == 'ar'
                                        ? 'تحديد كمقروء'
                                        : 'Mark as read'),
                              subtitle: notification.isRead
                                  ? (locale == 'ar'
                                        ? 'عرض كجديد'
                                        : 'Show as new')
                                  : (locale == 'ar'
                                        ? 'تحديد كمكتمل'
                                        : 'Mark as completed'),
                              locale: locale,
                            ),
                          ),

                          // Divider with glass effect
                          PopupMenuDivider(
                            color: Colors.black.withOpacity(0.5),
                          ),

                          // Delete option
                          PopupMenuItem(
                            value: 'delete',
                            child: _buildGlassMenuItem(
                              icon: Icons.delete_rounded,
                              iconColor: Colors.red,
                              title: locale == 'ar' ? 'حذف' : 'Delete',
                              subtitle: locale == 'ar'
                                  ? 'إزالة هذا الإشعار'
                                  : 'Remove this notification',
                              locale: locale,
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          // Haptic feedback for better UX
                          await _vibrate();

                          switch (value) {
                            case 'mark_read':
                              if (!notification.isRead) {
                                await _markAsRead(notification.id, locale);
                              }
                              break;
                            case 'mark_unread':
                              if (notification.isRead) {
                                await _markAsUnread(notification.id, locale);
                              }
                              break;
                            // case 'view_details':
                            //   _showNotificationDetails(notification, locale);
                            // break;
                            case 'delete':
                              await _showDeleteConfirmation(
                                notification,
                                locale,
                              );
                              break;
                          }
                        },
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
}

// Custom painter for animated particles
class _NotificationParticlesPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;

  _NotificationParticlesPainter(
    this.animationValue,
    this.primaryColor,
    this.secondaryColor,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 15; i++) {
      final progress = (animationValue + i * 0.1) % 1.0;
      final x =
          (i % 4) * size.width / 4 +
          math.sin(animationValue * 2 * math.pi + i) * 20;
      final y = size.height * progress;
      final opacity = math.sin(progress * math.pi) * 0.2;

      paint.color = (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(
        opacity,
      );

      final radius = 1 + math.sin(animationValue * 4 * math.pi + i) * 0.8;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw gradient orbs
    for (int i = 0; i < 3; i++) {
      final centerX = (i + 0.5) * size.width / 3;
      final centerY =
          size.height * 0.3 +
          math.sin(animationValue * 2 * math.pi + i * 1.5) * 50;
      final radius = 30 + math.sin(animationValue * 3 * math.pi + i) * 15;

      final gradient = RadialGradient(
        colors: [
          (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(0.08),
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

// Extension for copying notification
extension AppNotificationCopyWith on AppNotification {
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    String? orderId,
    String? relatedUserId,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}
