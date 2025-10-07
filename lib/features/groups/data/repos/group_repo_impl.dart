import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:nexi/core/errors/error.dart';

import 'package:nexi/features/auth/data/models/user_model.dart';

import 'package:nexi/features/groups/data/models/group_model.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firestore_service.dart';
import 'group_repo.dart';

class GroupRepoImpl implements GroupRepo {
  final FirestoreService firestore;
  GroupRepoImpl(this.firestore);
  @override
  Future<Either<Failure, GroupModel>> createOrUpdateGroup({
    required GroupModel group,
  }) async {
    try {
      final groupUId = await firestore.createOrUpdateGroup(group: group);
      return Right(groupUId);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Stream<List<GroupModel>>>> streamAllGroups() async {
    try {
      final data = firestore.streamAllGroups();
      return Right(data);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Stream<List<UserModel>>>> streamGroupMembers(
    String groupId,
  ) async {
    try {
      final data = await firestore.streamGroupMembers(groupId: groupId);
      return Right(data);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> addMembersToGroup(
    String groupId,
    List<String> members,
  ) async {
    try {
      await firestore.addMembersToGroup(groupId: groupId, newMembers: members);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> leaveGroup(
    String groupId,
    String userId,
  ) async {
    try {
      await firestore.leaveGroup(groupId: groupId, userId: userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroup(String groupId) async {
    try {
      await firestore.deleteGroup(groupId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessageToGroup({
    required String senderUID,
    required String groupId,
    required dynamic content,
  }) async {
    try {
      await firestore.sendMessage(
        content: content,
        collectionName: AppConstants.groups,
        userId: senderUID,
        docId: groupId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> markGroupMessagesAsRead({
    required String groupId,
    required String userId,
  }) async {
    try {
      await firestore.markGroupMessagesAsRead(groupId: groupId, userId: userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }


  @override
  Future<Either<Failure, void>> removeMemberFromGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      await firestore.removeMemberFromGroup(groupId: groupId, userId: userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }
  
  @override
  Future<Either<Failure, void>> updateGroupPicture({required String groupId, required File picture}) async{
    try {
      await firestore.updateGroupPicture(groupId: groupId, picture: picture);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }}

}
