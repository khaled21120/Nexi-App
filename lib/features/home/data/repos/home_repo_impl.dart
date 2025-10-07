import 'package:dartz/dartz.dart';

import 'package:nexi/core/errors/error.dart';
import 'package:nexi/core/services/firestore_service.dart';
import 'package:nexi/core/utils/helper.dart';

import 'package:nexi/features/auth/data/models/user_model.dart';

import '../../../../core/constants/app_constants.dart';
import 'home_repo.dart';

class HomeRepoImpl implements HomeRepo {
  final FirestoreService firestore;

  HomeRepoImpl(this.firestore);
  @override
  Future<Either<Failure, UserModel>> getUserData() async {
    final userModel = Helper.getUserDataLocally();
    try {
      final data = await firestore.fetchUserData(
        collection: AppConstants.users,
        docId: userModel!.id!,
      );
      return Right(UserModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Stream<List<UserModel>>>> getAllPeople() async {
    try {
      final data = firestore.streamAllUsers();
      return Right(data);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateOnlineStatus(
    String userId,
    bool isOnline,
  ) async {
    try {
      await firestore.updateOnlineStatus(userId: userId, isOnline: isOnline);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }
}
