import 'package:dartz/dartz.dart';

import '../../../../core/errors/error.dart';
import '../models/user_model.dart';

abstract class AuthRepo {
  Future<Either<Failure, UserModel>> signIn({
    required String email,
    required String password,
  });
  Future<Either<Failure, UserModel>> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<Either<Failure, UserModel>> signUpWithFacebook();
  Future<Either<Failure, UserModel>> signInWithGoogle();
  Future<bool> isSignedIn();
  Future<void> saveUserDataLocally(UserModel userModel);
  Future<Either<Failure, void>> resetPassword({required String email});
  Future<Either<Failure, void>> fetchUserData({
    required String collection,
    required String docId,
  });
}
