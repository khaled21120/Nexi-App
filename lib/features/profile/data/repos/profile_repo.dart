import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:nexi/features/auth/data/models/user_model.dart';

import '../../../../core/errors/error.dart';

abstract class ProfileRepo {
  Future<Either<Failure, void>> updateProfileImage({required File image});
  Future<Either<Failure, void>> updateProfileData({
    required Map<String, dynamic> data,
  });
  Future<Either<Failure, UserModel>> getUserData();

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, void>> deleteAccount();

  Future<void> saveUserDataLocally(UserModel userModel);
  Future<Either<Failure, Stream<UserModel>>> streamUserData(String userId);
}
