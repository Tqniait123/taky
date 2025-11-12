import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderCreated,
  orderAccepted,
  orderCompleted,
  orderCancelled,
  orderNeedsResponse,
  orderTransferred,
  itemStatusUpdated,
  systemAlert,
  info
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? orderId;
  final String? relatedUserId;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    this.relatedUserId,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: _parseNotificationType(data['type']),
      orderId: data['orderId'],
      relatedUserId: data['relatedUserId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      data: data['data'],
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'orderCreated': return NotificationType.orderCreated;
      case 'orderAccepted': return NotificationType.orderAccepted;
      case 'orderCompleted': return NotificationType.orderCompleted;
      case 'orderCancelled': return NotificationType.orderCancelled;
      case 'orderNeedsResponse': return NotificationType.orderNeedsResponse;
      case 'orderTransferred': return NotificationType.orderTransferred;
      case 'itemStatusUpdated': return NotificationType.itemStatusUpdated;
      case 'systemAlert': return NotificationType.systemAlert;
      default: return NotificationType.info;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'orderId': orderId,
      'relatedUserId': relatedUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'data': data,
    };
  }
}