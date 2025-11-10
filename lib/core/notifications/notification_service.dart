import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:taqy/features/all/auth/domain/entities/user.dart';

/// Enhanced notification service with comprehensive notification support
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? _currentUserId;
  String? _currentOrganizationId;

  /// Initialize notification service
  Future<void> initialize({
    required String userId,
    required String organizationId,
    required UserRole role,
  }) async {
    try {
      _currentUserId = userId;
      _currentOrganizationId = organizationId;

      await _initializeLocalNotifications();

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _fcmToken = await _messaging.getToken();
        debugPrint('📱 FCM Token: $_fcmToken');

        if (_fcmToken != null) {
          await _saveTokenToFirestore(userId, organizationId, role);
          await _subscribeToTopics(organizationId, role);
        }

        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _saveTokenToFirestore(userId, organizationId, role);
        });
      }

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('❌ Notification initialization error: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final data = jsonDecode(details.payload!);
          _navigateToScreen(data);
        }
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _saveTokenToFirestore(
    String userId,
    String organizationId,
    UserRole role,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'notificationSettings': {
          'enabled': true,
          'topics': ['org_$organizationId', '${role}_$organizationId'],
        },
      });
      debugPrint('✅ FCM token saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  Future<void> _subscribeToTopics(String organizationId, UserRole role) async {
    try {
      await _messaging.subscribeToTopic('org_$organizationId');
      await _messaging.subscribeToTopic('${role}_$organizationId');
      debugPrint(
        '✅ Subscribed to topics: org_$organizationId, ${role}_$organizationId',
      );
    } catch (e) {
      debugPrint('❌ Topic subscription error: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 Foreground notification: ${message.notification?.title}');

    await _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'ticker',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    _navigateToScreen(message.data);
  }

  void _navigateToScreen(Map<String, dynamic> data) {
    debugPrint('Navigate to: ${data['screen']}');
  }

  Future<void> sendNotificationToUser({
    required String targetUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        debugPrint('⚠️ User $targetUserId has no FCM token');
        return;
      }

      await _sendFCMNotification(
        token: fcmToken,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      debugPrint('❌ Error sending notification to user: $e');
    }
  }

  Future<void> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _sendFCMNotification(
        topic: topic,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      debugPrint('❌ Error sending notification to topic: $e');
    }
  }

  Future<void> _sendFCMNotification({
    String? token,
    String? topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final serviceAccountJson = await rootBundle.loadString(
        'assets/service_account.json',
      );
      final serviceAccountData =
          jsonDecode(serviceAccountJson) as Map<String, dynamic>;

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final credentials = ServiceAccountCredentials.fromJson(
        serviceAccountData,
      );
      final client = await clientViaServiceAccount(credentials, scopes);
      final accessToken = client.credentials.accessToken.data;

      final projectId = serviceAccountData['project_id'] as String;
      final Map<String, dynamic> message = {
        'notification': {'title': title, 'body': body},
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'high_importance_channel',
            'sound': 'default',
          },
        },
        'apns': {
          'headers': {'apns-priority': '10'},
          'payload': {
            'aps': {
              'sound': 'default',
              'badge': 1,
              'alert': {'title': title, 'body': body},
            },
          },
        },
      };

      if (token != null) {
        message['token'] = token;
      } else if (topic != null) {
        message['topic'] = topic;
      }

      if (data != null) {
        message['data'] = data.map(
          (key, value) => MapEntry(key, value.toString()),
        );
      }

      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Notification sent successfully');
      } else {
        debugPrint(
          '❌ Failed to send notification: ${response.statusCode} - ${response.body}',
        );
      }

      client.close();
    } catch (e) {
      debugPrint('❌ FCM notification error: $e');
    }
  }

  // ============== EMPLOYEE NOTIFICATIONS ==============

  /// Send notification when employee creates a new order
  Future<void> notifyOfficeBoyNewOrder({
    required String officeBoyId,
    required String orderId,
    required String orderType,
    required String employeeName,
    required int itemCount,
  }) async {
    await sendNotificationToUser(
      targetUserId: officeBoyId,
      title: '🛒 New Order Assigned',
      body: '$employeeName ordered $itemCount item(s)',
      data: {
        'type': 'new_order',
        'orderId': orderId,
        'orderType': orderType,
        'screen': 'order_details',
      },
    );
    log('✅ New order notification sent to office boy $officeBoyId');
  }

  /// Send notification when employee edits their order
  Future<void> notifyOfficeBoyOrderEdited({
    required String officeBoyId,
    required String orderId,
    required String employeeName,
    required int itemCount,
  }) async {
    await sendNotificationToUser(
      targetUserId: officeBoyId,
      title: '✏️ Order Updated',
      body: '$employeeName modified their order ($itemCount items)',
      data: {
        'type': 'order_edited',
        'orderId': orderId,
        'screen': 'order_details',
      },
    );
    log('✅ Order edit notification sent to office boy $officeBoyId');
  }

  /// Send notification when employee responds to unavailable items
  Future<void> notifyOfficeBoyEmployeeResponse({
    required String officeBoyId,
    required String orderId,
    required String employeeName,
    required String responseType, // 'continue' or 'cancel'
  }) async {
    final title = responseType == 'continue'
        ? '✅ Employee Accepted Available Items'
        : '❌ Employee Cancelled Order';
    final body = responseType == 'continue'
        ? '$employeeName wants to continue with available items'
        : '$employeeName cancelled the order';

    await sendNotificationToUser(
      targetUserId: officeBoyId,
      title: title,
      body: body,
      data: {
        'type': 'employee_response',
        'orderId': orderId,
        'responseType': responseType,
        'screen': 'order_details',
      },
    );
    log('✅ Employee response notification sent to office boy $officeBoyId');
  }

  /// Send notification when employee edits order after response request
  Future<void> notifyOfficeBoyOrderResubmitted({
    required String officeBoyId,
    required String orderId,
    required String employeeName,
    required int itemCount,
  }) async {
    await sendNotificationToUser(
      targetUserId: officeBoyId,
      title: '🔄 Order Resubmitted',
      body:
          '$employeeName updated and resubmitted their order ($itemCount items)',
      data: {
        'type': 'order_resubmitted',
        'orderId': orderId,
        'screen': 'order_details',
      },
    );
    log('✅ Order resubmission notification sent to office boy $officeBoyId');
  }

  /// Send notification when employee reorders from history
  Future<void> notifyOfficeBoyReorder({
    required String officeBoyId,
    required String orderId,
    required String employeeName,
    required int itemCount,
    required String originalOrderId,
  }) async {
    await sendNotificationToUser(
      targetUserId: officeBoyId,
      title: '🔁 Reorder Created',
      body: '$employeeName reordered $itemCount item(s)',
      data: {
        'type': 'reorder',
        'orderId': orderId,
        'originalOrderId': originalOrderId,
        'screen': 'order_details',
      },
    );
    log('✅ Reorder notification sent to office boy $officeBoyId');
  }

  // ============== OFFICE BOY NOTIFICATIONS ==============

  /// Send notification when office boy transfers order to another office boy
  Future<void> notifyOrderTransferredToOfficeBoy({
    required String newOfficeBoyId,
    required String orderId,
    required String employeeName,
    required int itemCount,
    required String fromOfficeBoyName,
  }) async {
    await sendNotificationToUser(
      targetUserId: newOfficeBoyId,
      title: '🔄 Order Transferred to You',
      body:
          '$fromOfficeBoyName transferred $employeeName\'s order ($itemCount items) to you',
      data: {
        'type': 'order_transferred_received',
        'orderId': orderId,
        'screen': 'order_details',
      },
    );
    log('✅ Transfer notification sent to new office boy $newOfficeBoyId');
  }

  /// Notify employee/admin when their order is transferred
  Future<void> notifyUserOrderTransferred({
    required String userId,
    required String orderId,
    required String fromOfficeBoyName,
    required String toOfficeBoyName,
    required bool isAdmin,
  }) async {
    final title = isAdmin ? '🔄 Your Order Reassigned' : '🔄 Order Reassigned';
    final body = isAdmin
        ? 'Your order was transferred from $fromOfficeBoyName to $toOfficeBoyName'
        : 'Your order was transferred from $fromOfficeBoyName to $toOfficeBoyName';

    await sendNotificationToUser(
      targetUserId: userId,
      title: title,
      body: body,
      data: {
        'type': 'order_transferred',
        'orderId': orderId,
        'screen': 'order_details',
      },
    );
    log(
      '✅ Transfer notification sent to ${isAdmin ? 'admin' : 'employee'} $userId',
    );
  }

  /// Send notification when office boy accepts order
  Future<void> notifyUserOrderAccepted({
    required String userId,
    required String orderId,
    required String officeBoyName,
    required bool isAdmin,
  }) async {
    final title = isAdmin ? '✅ Your Order Accepted' : '✅ Order Accepted';
    final body = isAdmin
        ? '$officeBoyName accepted your order'
        : '$officeBoyName accepted your order';

    await sendNotificationToUser(
      targetUserId: userId,
      title: title,
      body: body,
      data: {
        'type': 'order_accepted',
        'orderId': orderId,
        'screen': 'order_details',
      },
    );
    log(
      '✅ Order accepted notification sent to ${isAdmin ? 'admin' : 'employee'} $userId',
    );
  }

  /// Send notification when office boy starts processing order
  Future<void> notifyEmployeeOrderInProgress({
    required String employeeId,
    required String orderId,
    required String officeBoyName,
  }) async {
    await sendNotificationToUser(
      targetUserId: employeeId,
      title: '🚀 Order In Progress',
      body: '$officeBoyName started processing your order',
      data: {
        'type': 'order_in_progress',
        'orderId': orderId,
        'screen': 'order_details',
      },
    );
    log('✅ In progress notification sent to employee $employeeId');
  }

  /// Send notification when office boy marks items as available/unavailable
  Future<void> notifyEmployeeItemsStatusUpdated({
    required String employeeId,
    required String orderId,
    required String officeBoyName,
    required int availableCount,
    required int unavailableCount,
  }) async {
    final body = unavailableCount > 0
        ? '$officeBoyName found $availableCount available and $unavailableCount unavailable items'
        : '$officeBoyName confirmed all items are available';

    await sendNotificationToUser(
      targetUserId: employeeId,
      title: '📋 Items Status Updated',
      body: body,
      data: {
        'type': 'items_status_updated',
        'orderId': orderId,
        'screen': 'order_details',
      },
    );
    log('✅ Items status notification sent to employee $employeeId');
  }

  /// Send notification when office boy requests response for unavailable items
  Future<void> notifyEmployeeResponseNeeded({
    required String employeeId,
    required String orderId,
    required String officeBoyName,
    required int unavailableCount,
  }) async {
    await sendNotificationToUser(
      targetUserId: employeeId,
      title: '⚠️ Action Required',
      body:
          '$unavailableCount item(s) unavailable. Please respond to continue.',
      data: {
        'type': 'response_needed',
        'orderId': orderId,
        'screen': 'order_response',
      },
    );
    log('✅ Response needed notification sent to employee $employeeId');
  }

  /// Send notification when office boy completes order
  Future<void> notifyEmployeeOrderCompleted({
    required String employeeId,
    required String orderId,
    required String officeBoyName,
    double? finalPrice,
  }) async {
    final priceText = finalPrice != null
        ? ' (EGP ${finalPrice.toStringAsFixed(0)})'
        : '';

    await sendNotificationToUser(
      targetUserId: employeeId,
      title: '✅ Order Completed',
      body: '$officeBoyName completed your order$priceText',
      data: {
        'type': 'order_completed',
        'orderId': orderId,
        'screen': 'order_details',
      },
    );
    log('✅ Completion notification sent to employee $employeeId');
  }

  /// Send notification when office boy cancels order
  Future<void> notifyEmployeeOrderCancelled({
    required String employeeId,
    required String orderId,
    required String officeBoyName,
    String? reason,
  }) async {
    final reasonText = reason != null && reason.isNotEmpty ? ': $reason' : '';

    await sendNotificationToUser(
      targetUserId: employeeId,
      title: '❌ Order Cancelled',
      body: '$officeBoyName cancelled your order$reasonText',
      data: {
        'type': 'order_cancelled',
        'orderId': orderId,
        'screen': 'order_details',
      },
    );
    log('✅ Cancellation notification sent to employee $employeeId');
  }

  // ============== ADMIN NOTIFICATIONS ==============

  /// Send notification to admin when new order is created
  Future<void> notifyAdminNewOrder({
    required String organizationId,
    required String employeeName,
    required String orderType,
    required int itemCount,
  }) async {
    await sendNotificationToTopic(
      topic: 'admin_$organizationId',
      title: '📦 New Order Created',
      body: '$employeeName created a $orderType order ($itemCount items)',
      data: {
        'type': 'admin_new_order',
        'orderType': orderType,
        'screen': 'orders',
      },
    );
    log('✅ New order notification sent to admin');
  }

  Future<void> notifyAdminOrderInProgress({
    required String organizationId,


    required String orderId,
    required String officeBoyName,
  }) async {
    await sendNotificationToUser(
      targetUserId: organizationId,
      title: '🚀 Order In Progress',
      body: '$officeBoyName started processing your order',
      data: {
        'type': 'order_in_progress',
        'orderId': orderId,
        'screen': 'order_details',
      },
    );
    log('✅ In progress notification sent to employee $organizationId');
  }

  /// Send notification to admin when order is completed
  Future<void> notifyAdminOrderCompleted({
    required String organizationId,
    required String employeeName,
    required String officeBoyName,
    double? finalPrice,
  }) async {
    final priceText = finalPrice != null
        ? ' (EGP ${finalPrice.toStringAsFixed(0)})'
        : '';

    await sendNotificationToTopic(
      topic: 'admin_$organizationId',
      title: '✅ Order Completed',
      body: '$officeBoyName completed $employeeName\'s order$priceText',
      data: {'type': 'admin_order_completed', 'screen': 'orders'},
    );
    log('✅ Completion notification sent to admin');
  }

  /// Send notification to admin when order is cancelled
  Future<void> notifyAdminOrderCancelled({
    required String organizationId,
    required String employeeName,
    required String officeBoyName,
  }) async {
    await sendNotificationToTopic(
      topic: 'admin_$organizationId',
      title: '❌ Order Cancelled',
      body: '$officeBoyName cancelled $employeeName\'s order',
      data: {'type': 'admin_order_cancelled', 'screen': 'orders'},
    );
    log('✅ Cancellation notification sent to admin');
  }

  /// Cleanup on logout
  Future<void> cleanup() async {
    try {
      if (_currentOrganizationId != null) {
        await _messaging.unsubscribeFromTopic('org_$_currentOrganizationId');
      }

      if (_currentUserId != null) {
        await _firestore.collection('users').doc(_currentUserId).update({
          'fcmToken': FieldValue.delete(),
        });
      }

      _fcmToken = null;
      _currentUserId = null;
      _currentOrganizationId = null;

      debugPrint('✅ Notification service cleaned up');
    } catch (e) {
      debugPrint('❌ Cleanup error: $e');
    }
  }
}
