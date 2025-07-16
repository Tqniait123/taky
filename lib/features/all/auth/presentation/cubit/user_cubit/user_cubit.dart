import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taqy/features/all/auth/data/models/user_model.dart';

part 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  UserCubit() : super(UserUnauthenticated());
  static UserCubit get(context) => BlocProvider.of(context);
  UserModel? currentUser;

  void setCurrentUser(UserModel user) {
    currentUser = user;
    emit(UserAuthenticated(user));
  }

  void removeCurrentUser() {
    currentUser = null;
    emit(UserUnauthenticated());
  }

  bool isLoggedIn() {
    return currentUser != null;
  }
}
