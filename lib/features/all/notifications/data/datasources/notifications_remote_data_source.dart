import 'package:taqy/core/api/dio_client.dart';
import 'package:taqy/core/api/end_points.dart';
import 'package:taqy/core/api/response/response.dart';
import 'package:taqy/core/extensions/token_to_authorization_options.dart';
import 'package:taqy/features/all/notifications/data/models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<ApiResponse<List<NotificationModel>>> getNotifications(String token);
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final DioClient dioClient;

  NotificationsRemoteDataSourceImpl(this.dioClient);

  @override
  Future<ApiResponse<List<NotificationModel>>> getNotifications(String token) async {
    return dioClient.request<List<NotificationModel>>(
      method: RequestMethod.get,
      EndPoints.notifications,
      options: token.toAuthorizationOptions(),
      fromJson: (json) {
        final data = json as Map<String, dynamic>;
        final notificationsJson = data['notifications'] as List<dynamic>;
        return notificationsJson
            .map((notifications) => NotificationModel.fromJson(notifications as Map<String, dynamic>))
            .toList();
      },
    );
  }
}
