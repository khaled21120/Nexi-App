import 'package:dartz/dartz.dart';
import 'package:nexi/features/auth/data/models/user_model.dart';

import '../../../../core/errors/error.dart';

abstract class HomeRepo {
  Future<Either<Failure, UserModel>> getUserData();
  Future<Either<Failure, Stream<List<UserModel>>>> getAllPeople();
  Future<Either<Failure, void>> updateOnlineStatus(String userId, bool isOnline);
}
