// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState()';
}


}

/// @nodoc
class $AuthStateCopyWith<$Res>  {
$AuthStateCopyWith(AuthState _, $Res Function(AuthState) __);
}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthInitial value)?  initial,TResult Function( AuthLoading value)?  loading,TResult Function( AuthAuthenticated value)?  authenticated,TResult Function( AuthUnauthenticated value)?  unauthenticated,TResult Function( AuthError value)?  error,TResult Function( AuthPasswordResetSent value)?  passwordResetSent,TResult Function( AuthCheckingOrganizationCode value)?  checkingOrganizationCode,TResult Function( AuthOrganizationCodeChecked value)?  organizationCodeChecked,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthInitial() when initial != null:
return initial(_that);case AuthLoading() when loading != null:
return loading(_that);case AuthAuthenticated() when authenticated != null:
return authenticated(_that);case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case AuthError() when error != null:
return error(_that);case AuthPasswordResetSent() when passwordResetSent != null:
return passwordResetSent(_that);case AuthCheckingOrganizationCode() when checkingOrganizationCode != null:
return checkingOrganizationCode(_that);case AuthOrganizationCodeChecked() when organizationCodeChecked != null:
return organizationCodeChecked(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthInitial value)  initial,required TResult Function( AuthLoading value)  loading,required TResult Function( AuthAuthenticated value)  authenticated,required TResult Function( AuthUnauthenticated value)  unauthenticated,required TResult Function( AuthError value)  error,required TResult Function( AuthPasswordResetSent value)  passwordResetSent,required TResult Function( AuthCheckingOrganizationCode value)  checkingOrganizationCode,required TResult Function( AuthOrganizationCodeChecked value)  organizationCodeChecked,}){
final _that = this;
switch (_that) {
case AuthInitial():
return initial(_that);case AuthLoading():
return loading(_that);case AuthAuthenticated():
return authenticated(_that);case AuthUnauthenticated():
return unauthenticated(_that);case AuthError():
return error(_that);case AuthPasswordResetSent():
return passwordResetSent(_that);case AuthCheckingOrganizationCode():
return checkingOrganizationCode(_that);case AuthOrganizationCodeChecked():
return organizationCodeChecked(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthInitial value)?  initial,TResult? Function( AuthLoading value)?  loading,TResult? Function( AuthAuthenticated value)?  authenticated,TResult? Function( AuthUnauthenticated value)?  unauthenticated,TResult? Function( AuthError value)?  error,TResult? Function( AuthPasswordResetSent value)?  passwordResetSent,TResult? Function( AuthCheckingOrganizationCode value)?  checkingOrganizationCode,TResult? Function( AuthOrganizationCodeChecked value)?  organizationCodeChecked,}){
final _that = this;
switch (_that) {
case AuthInitial() when initial != null:
return initial(_that);case AuthLoading() when loading != null:
return loading(_that);case AuthAuthenticated() when authenticated != null:
return authenticated(_that);case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case AuthError() when error != null:
return error(_that);case AuthPasswordResetSent() when passwordResetSent != null:
return passwordResetSent(_that);case AuthCheckingOrganizationCode() when checkingOrganizationCode != null:
return checkingOrganizationCode(_that);case AuthOrganizationCodeChecked() when organizationCodeChecked != null:
return organizationCodeChecked(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( User user)?  authenticated,TResult Function()?  unauthenticated,TResult Function( String message)?  error,TResult Function()?  passwordResetSent,TResult Function()?  checkingOrganizationCode,TResult Function( bool exists)?  organizationCodeChecked,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthInitial() when initial != null:
return initial();case AuthLoading() when loading != null:
return loading();case AuthAuthenticated() when authenticated != null:
return authenticated(_that.user);case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated();case AuthError() when error != null:
return error(_that.message);case AuthPasswordResetSent() when passwordResetSent != null:
return passwordResetSent();case AuthCheckingOrganizationCode() when checkingOrganizationCode != null:
return checkingOrganizationCode();case AuthOrganizationCodeChecked() when organizationCodeChecked != null:
return organizationCodeChecked(_that.exists);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( User user)  authenticated,required TResult Function()  unauthenticated,required TResult Function( String message)  error,required TResult Function()  passwordResetSent,required TResult Function()  checkingOrganizationCode,required TResult Function( bool exists)  organizationCodeChecked,}) {final _that = this;
switch (_that) {
case AuthInitial():
return initial();case AuthLoading():
return loading();case AuthAuthenticated():
return authenticated(_that.user);case AuthUnauthenticated():
return unauthenticated();case AuthError():
return error(_that.message);case AuthPasswordResetSent():
return passwordResetSent();case AuthCheckingOrganizationCode():
return checkingOrganizationCode();case AuthOrganizationCodeChecked():
return organizationCodeChecked(_that.exists);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( User user)?  authenticated,TResult? Function()?  unauthenticated,TResult? Function( String message)?  error,TResult? Function()?  passwordResetSent,TResult? Function()?  checkingOrganizationCode,TResult? Function( bool exists)?  organizationCodeChecked,}) {final _that = this;
switch (_that) {
case AuthInitial() when initial != null:
return initial();case AuthLoading() when loading != null:
return loading();case AuthAuthenticated() when authenticated != null:
return authenticated(_that.user);case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated();case AuthError() when error != null:
return error(_that.message);case AuthPasswordResetSent() when passwordResetSent != null:
return passwordResetSent();case AuthCheckingOrganizationCode() when checkingOrganizationCode != null:
return checkingOrganizationCode();case AuthOrganizationCodeChecked() when organizationCodeChecked != null:
return organizationCodeChecked(_that.exists);case _:
  return null;

}
}

}

/// @nodoc


class AuthInitial implements AuthState {
  const AuthInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.initial()';
}


}




/// @nodoc


class AuthLoading implements AuthState {
  const AuthLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.loading()';
}


}




/// @nodoc


class AuthAuthenticated implements AuthState {
  const AuthAuthenticated(this.user);
  

 final  User user;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthAuthenticatedCopyWith<AuthAuthenticated> get copyWith => _$AuthAuthenticatedCopyWithImpl<AuthAuthenticated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthAuthenticated&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'AuthState.authenticated(user: $user)';
}


}

/// @nodoc
abstract mixin class $AuthAuthenticatedCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthAuthenticatedCopyWith(AuthAuthenticated value, $Res Function(AuthAuthenticated) _then) = _$AuthAuthenticatedCopyWithImpl;
@useResult
$Res call({
 User user
});




}
/// @nodoc
class _$AuthAuthenticatedCopyWithImpl<$Res>
    implements $AuthAuthenticatedCopyWith<$Res> {
  _$AuthAuthenticatedCopyWithImpl(this._self, this._then);

  final AuthAuthenticated _self;
  final $Res Function(AuthAuthenticated) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(AuthAuthenticated(
null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,
  ));
}


}

/// @nodoc


class AuthUnauthenticated implements AuthState {
  const AuthUnauthenticated();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUnauthenticated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.unauthenticated()';
}


}




/// @nodoc


class AuthError implements AuthState {
  const AuthError(this.message);
  

 final  String message;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthErrorCopyWith<AuthError> get copyWith => _$AuthErrorCopyWithImpl<AuthError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AuthState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $AuthErrorCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthErrorCopyWith(AuthError value, $Res Function(AuthError) _then) = _$AuthErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$AuthErrorCopyWithImpl<$Res>
    implements $AuthErrorCopyWith<$Res> {
  _$AuthErrorCopyWithImpl(this._self, this._then);

  final AuthError _self;
  final $Res Function(AuthError) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(AuthError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AuthPasswordResetSent implements AuthState {
  const AuthPasswordResetSent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthPasswordResetSent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.passwordResetSent()';
}


}




/// @nodoc


class AuthCheckingOrganizationCode implements AuthState {
  const AuthCheckingOrganizationCode();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthCheckingOrganizationCode);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.checkingOrganizationCode()';
}


}




/// @nodoc


class AuthOrganizationCodeChecked implements AuthState {
  const AuthOrganizationCodeChecked(this.exists);
  

 final  bool exists;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthOrganizationCodeCheckedCopyWith<AuthOrganizationCodeChecked> get copyWith => _$AuthOrganizationCodeCheckedCopyWithImpl<AuthOrganizationCodeChecked>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthOrganizationCodeChecked&&(identical(other.exists, exists) || other.exists == exists));
}


@override
int get hashCode => Object.hash(runtimeType,exists);

@override
String toString() {
  return 'AuthState.organizationCodeChecked(exists: $exists)';
}


}

/// @nodoc
abstract mixin class $AuthOrganizationCodeCheckedCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthOrganizationCodeCheckedCopyWith(AuthOrganizationCodeChecked value, $Res Function(AuthOrganizationCodeChecked) _then) = _$AuthOrganizationCodeCheckedCopyWithImpl;
@useResult
$Res call({
 bool exists
});




}
/// @nodoc
class _$AuthOrganizationCodeCheckedCopyWithImpl<$Res>
    implements $AuthOrganizationCodeCheckedCopyWith<$Res> {
  _$AuthOrganizationCodeCheckedCopyWithImpl(this._self, this._then);

  final AuthOrganizationCodeChecked _self;
  final $Res Function(AuthOrganizationCodeChecked) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? exists = null,}) {
  return _then(AuthOrganizationCodeChecked(
null == exists ? _self.exists : exists // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
