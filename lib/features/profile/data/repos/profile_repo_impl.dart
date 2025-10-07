import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:nexi/core/errors/error.dart';
import 'package:nexi/core/services/prefs_service.dart';

import 'package:nexi/features/auth/data/models/user_model.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/fire_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/helper.dart';
import 'profile_repo.dart';

class ProfileRepoImpl implements ProfileRepo {
  final FireAuthService fireAuthService;
  final FirestoreService firestoreService;
  final _auth = FirebaseAuth.instance;

  ProfileRepoImpl(this.fireAuthService, this.firestoreService);
  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await fireAuthService.deleteAccount();
      await firestoreService.deleteUserData(
        collection: AppConstants.users,
        docId: _auth.currentUser!.uid,
      );
      await PrefsService.removeAll(AppConstants.users);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Stream<UserModel>>> streamUserData(
    String userId,
  ) async {
    try {
      final stream = firestoreService.fetchUserStream(userId);
      return Right(stream);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, UserModel>> getUserData() async {
    try {
      final data = await firestoreService.fetchUserData(
        collection: AppConstants.users,
        docId: _auth.currentUser!.uid,
      );
      await saveUserDataLocally(UserModel.fromJson(data));
      return Right(UserModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await firestoreService.updateOnlineStatus(
        userId: _auth.currentUser!.uid,
        isOnline: false,
      );
      await fireAuthService.signOut();
      await PrefsService.removeAll(AppConstants.users);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfileData({
    required Map<String, dynamic> data,
  }) async {
    try {
      await firestoreService.updateUserData(
        collection: AppConstants.users,
        docId: _auth.currentUser!.uid,
        data: data,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfileImage({
    required File image,
  }) async {
    try {
      final fileExtention = Helper.getMimeType(image.path);
      final fileName = '${_auth.currentUser!.uid}.$fileExtention';
      final url = await firestoreService.uploadImage(
        folderName: 'users_images',
        file: image,
        fileName: fileName,
      );
      await firestoreService.updateUserData(
        collection: AppConstants.users,
        docId: _auth.currentUser!.uid,
        data: {'photoUrl': url},
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<void> saveUserDataLocally(UserModel userModel) async {
    final userData = jsonEncode(userModel.toJson());
    await PrefsService.setString(AppConstants.users, userData);
  }
}
