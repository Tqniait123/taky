import 'package:flutter/material.dart';
import 'package:taqy/features/all/auth/data/models/user_model.dart';
import 'package:taqy/features/all/auth/presentation/cubit/user_cubit/user_cubit.dart';

extension UserCubitX on BuildContext {
  UserCubit get userCubit => UserCubit.get(this);

  bool get isLoggedIn => userCubit.isLoggedIn();
  void setCurrentUser(UserModel user) => userCubit.setCurrentUser(user);
  UserModel get user => UserCubit.get(this).currentUser!;
}
