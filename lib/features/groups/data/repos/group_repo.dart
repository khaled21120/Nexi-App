import 'dart:io';

import 'package:dartz/dartz.dart';
import '../../../../core/errors/error.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/group_model.dart';

abstract class GroupRepo {
  Future<Either<Failure, GroupModel>> createOrUpdateGroup({
    required GroupModel group,
  });

  Future<Either<Failure, Stream<List<GroupModel>>>> streamAllGroups();

  Future<Either<Failure, Stream<List<UserModel>>>> streamGroupMembers(
    String groupId,
  );

  Future<Either<Failure, void>> deleteGroup(String groupId);

  Future<Either<Failure, void>> leaveGroup(String groupId, String userId);

  Future<Either<Failure, void>> addMembersToGroup(
    String groupId,
    List<String> members,
  );

  Future<Either<Failure, void>> removeMemberFromGroup({
    required String groupId,
    required String userId,
  });

  Future<Either<Failure, void>> sendMessageToGroup({
    required String senderUID,
    required String groupId,
    required dynamic content,
  });

  Future<Either<Failure, void>> markGroupMessagesAsRead({
    required String groupId,
    required String userId,
  });

  Future<Either<Failure, void>> updateGroupPicture({
    required String groupId,
    required File picture,
  });
}
