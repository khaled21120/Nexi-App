import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:nexi/core/errors/error.dart';
import 'package:nexi/core/services/fire_auth_service.dart';
import 'package:nexi/features/auth/data/models/user_model.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/prefs_service.dart';
import 'auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  final FireAuthService fireAuthService;
  final FirestoreService firestoreService;
  AuthRepoImpl({required this.firestoreService, required this.fireAuthService});
  @override
  Future<bool> isSignedIn() async {
    try {
      final user = await fireAuthService.isSignedIn();
      return user;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either<Failure, UserModel>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await fireAuthService.signIn(
        email: email,
        password: password,
      );
      final userData = await firestoreService.fetchUserData(
        collection: 'users',
        docId: user.uid,
      );
      await firestoreService.updateOnlineStatus(
        userId: user.uid,
        isOnline: true,
      );
      final userModel = UserModel.fromJson(userData);
      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = await fireAuthService.signUp(
        name: name,
        email: email,
        password: password,
      );
      await firestoreService.addUserData(
        uid: user.uid,
        name: name,
        email: email,
        photoUrl: user.photoURL ?? '',
      );
      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: email,
        photoUrl: user.photoURL ?? '',
      );
      await firestoreService.updateOnlineStatus(
        userId: user.uid,
        isOnline: true,
      );

      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    try {
      await fireAuthService.resetPassword(email: email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchUserData({
    required String collection,
    required String docId,
  }) async {
    try {
      final result = await firestoreService.fetchUserData(
        collection: collection,
        docId: docId,
      );
      return Right(result);
    } on Exception catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<void> saveUserDataLocally(UserModel userModel) async {
    final userData = jsonEncode(userModel.toJson());
    await PrefsService.setString(AppConstants.users, userData);
  }

  @override
  Future<Either<Failure, UserModel>> signInWithGoogle() async {
    try {
      final credentail = await fireAuthService.signInWithGoogle();
      final user = credentail.user;
      final isUserExist = await firestoreService.isUserExist(
        collection: AppConstants.users,
        docId: user!.uid,
      );
      if (!isUserExist) {
        await firestoreService.addUserData(
          uid: user.uid,
          name: user.displayName ?? 'Unknown',
          email: user.email ?? 'Unknown',
          photoUrl: user.photoURL ?? '',
        );
      }
      final userData = await firestoreService.fetchUserData(
        collection: AppConstants.users,
        docId: user.uid,
      );
      final userModel = UserModel.fromJson(userData);
      await firestoreService.updateOnlineStatus(
        userId: user.uid,
        isOnline: true,
      );
      await saveUserDataLocally(userModel);
      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signUpWithFacebook() async {
    try {
      final credentail = await fireAuthService.signInWithFacebook();
      final user = credentail.user;
      final isUserExist = await firestoreService.isUserExist(
        collection: AppConstants.users,
        docId: user!.uid,
      );
      if (!isUserExist) {
        await firestoreService.addUserData(
          uid: user.uid,
          name: user.displayName ?? 'Unknown',
          email: user.email ?? 'Unknown',
          photoUrl: user.photoURL ?? '',
        );
      }
      final userData = await firestoreService.fetchUserData(
        collection: AppConstants.users,
        docId: user.uid,
      );
      final userModel = UserModel.fromJson(userData);
      await firestoreService.updateOnlineStatus(
        userId: user.uid,
        isOnline: true,
      );
      await saveUserDataLocally(userModel);
      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }
}
