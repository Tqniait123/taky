// abstract class Failure implements Exception {
//   final String message;
//   const Failure(this.message);
// }

// // General Failures
// class ServerFailure extends Failure {
//   ServerFailure(super.message);
// }

// class NoInternetFailure extends Failure {
//   NoInternetFailure() : super('no internet connection');
// }

// class AuthFailure extends Failure {
//   AuthFailure(super.message);
// }

// class UnAuthorizedFailure extends Failure {
//   UnAuthorizedFailure(super.message);
// }

// class EmptyCacheFailure extends Failure {
//   const EmptyCacheFailure() : super("cache_failure");
// }

// lib/core/errors/failures.dart
import 'package:equatable/equatable.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? code;
  final dynamic details;

  const Failure({required this.message, this.code, this.details});

  @override
  List<Object?> get props => [message, code, details];
}

// Authentication Failures
class AuthFailure extends Failure {
  const AuthFailure(String message, {super.code, super.details})
    : super(message: message);
}

class RegistrationFailure extends Failure {
  const RegistrationFailure(String message, {super.code, super.details})
    : super(message: message);
}

class LoginFailure extends Failure {
  const LoginFailure(String message, {super.code, super.details})
    : super(message: message);
}

class LogoutFailure extends Failure {
  const LogoutFailure(String message, {super.code, super.details})
    : super(message: message);
}

class PasswordResetFailure extends Failure {
  const PasswordResetFailure(String message, {super.code, super.details})
    : super(message: message);
}

class EmailVerificationFailure extends Failure {
  const EmailVerificationFailure(String message, {super.code, super.details})
    : super(message: message);
}

class TokenRefreshFailure extends Failure {
  const TokenRefreshFailure(String message, {super.code, super.details})
    : super(message: message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(String message, {super.code, super.details})
    : super(message: message);
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure(String message, {super.code, super.details})
    : super(message: message);
}

// Database Failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(String message, {super.code, super.details})
    : super(message: message);
}

class QueryFailure extends Failure {
  const QueryFailure(String message, {super.code, super.details})
    : super(message: message);
}

class InsertFailure extends Failure {
  const InsertFailure(String message, {super.code, super.details})
    : super(message: message);
}

class UpdateFailure extends Failure {
  const UpdateFailure(String message, {super.code, super.details})
    : super(message: message);
}

class DeleteFailure extends Failure {
  const DeleteFailure(String message, {super.code, super.details})
    : super(message: message);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure(String message, {super.code, super.details})
    : super(message: message);
}

class TransactionFailure extends Failure {
  const TransactionFailure(String message, {super.code, super.details})
    : super(message: message);
}

// Storage Failures
class StorageFailure extends Failure {
  const StorageFailure(String message, {super.code, super.details})
    : super(message: message);
}

class FileUploadFailure extends Failure {
  const FileUploadFailure(String message, {super.code, super.details})
    : super(message: message);
}

class FileDownloadFailure extends Failure {
  const FileDownloadFailure(String message, {super.code, super.details})
    : super(message: message);
}

class FileDeleteFailure extends Failure {
  const FileDeleteFailure(String message, {super.code, super.details})
    : super(message: message);
}

class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure(String message, {super.code, super.details})
    : super(message: message);
}

class FileSizeExceededFailure extends Failure {
  const FileSizeExceededFailure(String message, {super.code, super.details})
    : super(message: message);
}

class InvalidFileTypeFailure extends Failure {
  const InvalidFileTypeFailure(String message, {super.code, super.details})
    : super(message: message);
}

// Network Failures
class NetworkFailure extends Failure {
  const NetworkFailure(String message, {super.code, super.details})
    : super(message: message);
}

class ServerFailure extends Failure {
  const ServerFailure(String message, {super.code, super.details})
    : super(message: message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(String message, {super.code, super.details})
    : super(message: message);
}

class NoInternetFailure extends Failure {
  const NoInternetFailure(String message, {super.code, super.details})
    : super(message: message);
}

class BadRequestFailure extends Failure {
  const BadRequestFailure(String message, {super.code, super.details})
    : super(message: message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(String message, {super.code, super.details})
    : super(message: message);
}

class InternalServerFailure extends Failure {
  const InternalServerFailure(String message, {super.code, super.details})
    : super(message: message);
}

// Validation Failures
class ValidationFailure extends Failure {
  const ValidationFailure(String message, {super.code, super.details})
    : super(message: message);
}

class InvalidInputFailure extends Failure {
  const InvalidInputFailure(String message, {super.code, super.details})
    : super(message: message);
}

class RequiredFieldFailure extends Failure {
  const RequiredFieldFailure(String message, {super.code, super.details})
    : super(message: message);
}

class InvalidEmailFailure extends Failure {
  const InvalidEmailFailure(String message, {super.code, super.details})
    : super(message: message);
}

class InvalidPasswordFailure extends Failure {
  const InvalidPasswordFailure(String message, {super.code, super.details})
    : super(message: message);
}

class InvalidPhoneFailure extends Failure {
  const InvalidPhoneFailure(String message, {super.code, super.details})
    : super(message: message);
}

class DuplicateEntryFailure extends Failure {
  const DuplicateEntryFailure(String message, {super.code, super.details})
    : super(message: message);
}

// Organization Failures
class OrganizationFailure extends Failure {
  const OrganizationFailure(String message, {super.code, super.details})
    : super(message: message);
}

class OrganizationNotFoundFailure extends Failure {
  const OrganizationNotFoundFailure(String message, {super.code, super.details})
    : super(message: message);
}

class OrganizationCodeFailure extends Failure {
  const OrganizationCodeFailure(String message, {super.code, super.details})
    : super(message: message);
}

class OrganizationInactiveFailure extends Failure {
  const OrganizationInactiveFailure(String message, {super.code, super.details})
    : super(message: message);
}

class InsufficientPermissionsFailure extends Failure {
  const InsufficientPermissionsFailure(
    String message, {
    super.code,
    super.details,
  }) : super(message: message);
}

// Request Failures
class RequestFailure extends Failure {
  const RequestFailure(String message, {super.code, super.details})
    : super(message: message);
}

class RequestNotFoundFailure extends Failure {
  const RequestNotFoundFailure(String message, {super.code, super.details})
    : super(message: message);
}

class RequestAlreadyProcessedFailure extends Failure {
  const RequestAlreadyProcessedFailure(
    String message, {
    super.code,
    super.details,
  }) : super(message: message);
}

class RequestCancelledFailure extends Failure {
  const RequestCancelledFailure(String message, {super.code, super.details})
    : super(message: message);
}

// Notification Failures
class NotificationFailure extends Failure {
  const NotificationFailure(String message, {super.code, super.details})
    : super(message: message);
}

class FCMTokenFailure extends Failure {
  const FCMTokenFailure(String message, {super.code, super.details})
    : super(message: message);
}

class PushNotificationFailure extends Failure {
  const PushNotificationFailure(String message, {super.code, super.details})
    : super(message: message);
}

class LocalNotificationFailure extends Failure {
  const LocalNotificationFailure(String message, {super.code, super.details})
    : super(message: message);
}

// Permission Failures
class PermissionFailure extends Failure {
  const PermissionFailure(String message, {super.code, super.details})
    : super(message: message);
}

class CameraPermissionFailure extends Failure {
  const CameraPermissionFailure(String message, {super.code, super.details})
    : super(message: message);
}

class StoragePermissionFailure extends Failure {
  const StoragePermissionFailure(String message, {super.code, super.details})
    : super(message: message);
}

class LocationPermissionFailure extends Failure {
  const LocationPermissionFailure(String message, {super.code, super.details})
    : super(message: message);
}

class NotificationPermissionFailure extends Failure {
  const NotificationPermissionFailure(
    String message, {
    super.code,
    super.details,
  }) : super(message: message);
}

// Cache Failures
class CacheFailure extends Failure {
  const CacheFailure(String message, {super.code, super.details})
    : super(message: message);
}

class CacheNotFoundFailure extends Failure {
  const CacheNotFoundFailure(String message, {super.code, super.details})
    : super(message: message);
}

class CacheExpiredFailure extends Failure {
  const CacheExpiredFailure(String message, {super.code, super.details})
    : super(message: message);
}

// General Failures
class GeneralFailure extends Failure {
  const GeneralFailure(String message, {super.code, super.details})
    : super(message: message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(String message, {super.code, super.details})
    : super(message: message);
}

class ParseFailure extends Failure {
  const ParseFailure(String message, {super.code, super.details})
    : super(message: message);
}

class SerializationFailure extends Failure {
  const SerializationFailure(String message, {super.code, super.details})
    : super(message: message);
}

class FormatFailure extends Failure {
  const FormatFailure(String message, {super.code, super.details})
    : super(message: message);
}

class ConfigurationFailure extends Failure {
  const ConfigurationFailure(String message, {super.code, super.details})
    : super(message: message);
}

class InitializationFailure extends Failure {
  const InitializationFailure(String message, {super.code, super.details})
    : super(message: message);
}

// Utility extension for common failure handling
extension FailureExtension on Failure {
  /// Returns a user-friendly error message
  String get userMessage {
    switch (runtimeType) {
      case AuthFailure:
        return 'Authentication failed. Please check your credentials.';
      case NetworkFailure:
        return 'Network error. Please check your connection.';
      case ServerFailure:
        return 'Server error. Please try again later.';
      case ValidationFailure:
        return 'Invalid input. Please check your data.';
      case TimeoutFailure:
        return 'Request timeout. Please try again.';
      case NoInternetFailure:
        return 'No internet connection. Please check your network.';
      case OrganizationNotFoundFailure:
        return 'Organization not found. Please check the organization code.';
      case FileUploadFailure:
        return 'File upload failed. Please try again.';
      case PermissionFailure:
        return 'Permission denied. Please grant the required permissions.';
      default:
        return message;
    }
  }

  /// Returns true if the failure is network-related
  bool get isNetworkFailure {
    return this is NetworkFailure ||
        this is TimeoutFailure ||
        this is NoInternetFailure ||
        this is ConnectionFailure;
  }

  /// Returns true if the failure is authentication-related
  bool get isAuthFailure {
    return this is AuthFailure ||
        this is LoginFailure ||
        this is RegistrationFailure ||
        this is UnauthorizedFailure ||
        this is SessionExpiredFailure;
  }

  /// Returns true if the failure is validation-related
  bool get isValidationFailure {
    return this is ValidationFailure ||
        this is InvalidInputFailure ||
        this is RequiredFieldFailure ||
        this is InvalidEmailFailure ||
        this is InvalidPasswordFailure;
  }

  /// Returns true if the failure is retryable
  bool get isRetryable {
    return isNetworkFailure ||
        this is ServerFailure ||
        this is TimeoutFailure ||
        this is DatabaseFailure ||
        this is FileUploadFailure;
  }
}

// Failure factory for creating failures from different sources
class FailureFactory {
  // static Failure fromException(Exception exception) {
  //   if (exception is AuthException) {
  //     return AuthFailure(exception.message);
  //   } else if (exception is PostgrestException) {
  //     return DatabaseFailure(exception.message);
  //   } else if (exception is StorageException) {
  //     return StorageFailure(exception.message);
  //   } else if (exception is FormatException) {
  //     return ParseFailure(exception.message);
  //   } else {
  //     return GeneralFailure(exception.toString());
  //   }
  // }

  static Failure fromError(Error error) {
    return GeneralFailure(error.toString());
  }

  static Failure fromHttpStatus(int statusCode, String message) {
    switch (statusCode) {
      case 400:
        return BadRequestFailure(message, code: statusCode);
      case 401:
        return UnauthorizedFailure(message, code: statusCode);
      case 404:
        return NotFoundFailure(message, code: statusCode);
      case 408:
        return TimeoutFailure(message, code: statusCode);
      case 500:
        return InternalServerFailure(message, code: statusCode);
      default:
        return ServerFailure(message, code: statusCode);
    }
  }
}

// Common failure messages
class FailureMessages {
  static const String networkError = 'Network error occurred';
  static const String serverError = 'Server error occurred';
  static const String authError = 'Authentication failed';
  static const String validationError = 'Validation failed';
  static const String permissionError = 'Permission denied';
  static const String fileError = 'File operation failed';
  static const String unknownError = 'Unknown error occurred';
  static const String timeoutError = 'Request timeout';
  static const String noInternetError = 'No internet connection';
  static const String organizationNotFound = 'Organization not found';
  static const String userNotFound = 'User not found';
  static const String requestNotFound = 'Request not found';
  static const String invalidCredentials = 'Invalid credentials';
  static const String emailAlreadyExists = 'Email already exists';
  static const String organizationCodeExists =
      'Organization code already exists';
  static const String insufficientPermissions = 'Insufficient permissions';
}
