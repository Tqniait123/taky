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

/// Free notification service without Cloud Functions
/// Sends notifications directly from the app
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

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        _fcmToken = await _messaging.getToken();
        debugPrint('📱 FCM Token: $_fcmToken');

        if (_fcmToken != null) {
          // Save token to Firestore
          await _saveTokenToFirestore(userId, organizationId, role);

          // Subscribe to role-based topics
          await _subscribeToTopics(organizationId, role);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _saveTokenToFirestore(userId, organizationId, role);
        });
      }

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background/terminated notifications
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification when app was terminated
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('❌ Notification initialization error: $e');
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
        // Handle notification tap
        if (details.payload != null) {
          final data = jsonDecode(details.payload!);
          _navigateToScreen(data);
        }
      },
    );

    // Create Android notification channel
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
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Save FCM token to Firestore
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

  /// Subscribe to role-based topics
  Future<void> _subscribeToTopics(String organizationId, UserRole role) async {
    try {
      // Subscribe to organization topic
      await _messaging.subscribeToTopic('org_$organizationId');
      
      // Subscribe to role-specific topic
      await _messaging.subscribeToTopic('${role}_$organizationId');
      
      debugPrint('✅ Subscribed to topics: org_$organizationId, ${role}_$organizationId');
    } catch (e) {
      debugPrint('❌ Topic subscription error: $e');
    }
  }

  /// Handle foreground notifications - SHOW LOCAL NOTIFICATION
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 Foreground notification: ${message.notification?.title}');
    
    // Show local notification when app is in foreground
    await _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  /// Show local notification
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

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    _navigateToScreen(message.data);
  }

  /// Navigate to screen based on notification data
  void _navigateToScreen(Map<String, dynamic> data) {
    // TODO: Implement navigation logic based on data['screen'] and data['type']
    // Example: 
    // final screen = data['screen'];
    // if (screen == 'order_details') {
    //   Navigator.pushNamed(context, '/order_details', arguments: data['orderId']);
    // }
    debugPrint('Navigate to: ${data['screen']}');
  }

  /// Send notification to specific user
  Future<void> sendNotificationToUser({
    required String targetUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get target user's FCM token
      final userDoc = await _firestore.collection('users').doc(targetUserId).get();
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

  /// Send notification to topic (role-based)
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

  /// Core FCM notification sending method
 /// Core FCM notification sending method - FIXED
Future<void> _sendFCMNotification({
  String? token,
  String? topic,
  required String title,
  required String body,
  Map<String, dynamic>? data,
}) async {
  try {
    // Load service account
    final serviceAccountJson = await rootBundle.loadString(
      'assets/service_account.json',
    );
    final serviceAccountData = jsonDecode(serviceAccountJson) as Map<String, dynamic>;

    // Get access token
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final credentials = ServiceAccountCredentials.fromJson(serviceAccountData);
    final client = await clientViaServiceAccount(credentials, scopes);
    final accessToken = client.credentials.accessToken.data;

    // Build payload - FIXED STRUCTURE
    final projectId = serviceAccountData['project_id'] as String;
    final Map<String, dynamic> message = {
      'notification': {
        'title': title,
        'body': body,
      },
      'android': {
        'priority': 'high', // ✅ Priority at android level, NOT in notification
        'notification': {
          'channel_id': 'high_importance_channel',
          'sound': 'default',
          // ❌ REMOVED: 'priority': 'high' - This was causing the error
        },
      },
      'apns': {
        'headers': {'apns-priority': '10'},
        'payload': {
          'aps': {
            'sound': 'default',
            'badge': 1,
            'alert': {
              'title': title,
              'body': body,
            },
          },
        },
      },
    };

    // Add token or topic
    if (token != null) {
      message['token'] = token;
    } else if (topic != null) {
      message['topic'] = topic;
    }

    // Add custom data
    if (data != null) {
      message['data'] = data.map((key, value) => MapEntry(key, value.toString()));
    }

    // Send request
    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      debugPrint('✅ Notification sent successfully');
      debugPrint('Response: ${response.body}');
    } else {
      debugPrint('❌ Failed to send notification: ${response.statusCode} - ${response.body}');
    }

    client.close();
  } catch (e) {
    debugPrint('❌ FCM notification error: $e');
  }
}

  /// Send order notification to office boy
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
    log('Notification sent to office boy $officeBoyId for order $orderId');
  }

  /// Send order status update to employee
  Future<void> notifyEmployeeOrderUpdate({
    required String employeeId,
    required String orderId,
    required String status,
    required String officeBoyName,
  }) async {
    String title = '';
    String body = '';

    switch (status) {
      case 'inProgress':
        title = '🚀 Order In Progress';
        body = '$officeBoyName started processing your order';
        break;
      case 'completed':
        title = '✅ Order Completed';
        body = '$officeBoyName completed your order';
        break;
      case 'cancelled':
        title = '❌ Order Cancelled';
        body = 'Your order was cancelled';
        break;
      case 'needsResponse':
        title = '⚠️ Action Required';
        body = 'Some items are unavailable. Please respond.';
        break;
    }

    await sendNotificationToUser(
      targetUserId: employeeId,
      title: title,
      body: body,
      data: {
        'type': 'order_update',
        'orderId': orderId,
        'status': status,
        'screen': 'order_details',
      },
    );
  }

  /// Send order transfer notification
  Future<void> notifyOrderTransferred({
    required String newOfficeBoyId,
    required String orderId,
    required String employeeName,
    required int itemCount,
  }) async {
    await sendNotificationToUser(
      targetUserId: newOfficeBoyId,
      title: '🔄 Order Transferred to You',
      body: '$employeeName\'s order ($itemCount items) was assigned to you',
      data: {
        'type': 'order_transferred',
        'orderId': orderId,
        'screen': 'order_details',
      },
    );
  }

  /// Send admin notification for new orders
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
  }

  /// Cleanup on logout
  Future<void> cleanup() async {
    try {
      if (_currentOrganizationId != null) {
        // Unsubscribe from topics
        await _messaging.unsubscribeFromTopic('org_$_currentOrganizationId');
      }

      // Clear token from Firestore
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