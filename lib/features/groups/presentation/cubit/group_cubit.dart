import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:nexi/features/auth/data/models/user_model.dart';
import 'package:nexi/features/groups/data/repos/group_repo.dart';

import '../../data/models/group_model.dart';

part 'group_state.dart';

class GroupCubit extends Cubit<GroupState> {
  GroupCubit(this.groupRepo) : super(GroupInitial());
  final GroupRepo groupRepo;
  StreamSubscription<List<GroupModel>>? _groupsSub;
  StreamSubscription<List<UserModel>>? _membersSub;

  Future<void> getGroups() async {
    emit(GroupsLoading());

    final result = await groupRepo.streamAllGroups();
    result.fold((failure) => emit(GroupsError(failure.errMsg)), (groupsStream) {
      _groupsSub?.cancel();
      _groupsSub = groupsStream.listen(
        (groupsList) {
          emit(GroupsLoaded(groupsList));
        },
        onError: (error) {
          emit(GroupsError(error.toString()));
        },
      );
    });
  }

  Future<void> createOrUpdateGroup(GroupModel group) async {
    emit(GroupsLoading());
    final result = await groupRepo.createOrUpdateGroup(group: group);
    result.fold(
      (failure) => emit(GroupsError(failure.errMsg)),
      (groupId) => emit(GroupCreated(groupId)),
    );
  }

  Future<void> sendMessageToGroup({
    required String senderUID,
    required String groupId,
    required dynamic content,
  }) async {
    emit(GroupsLoading());
    final result = await groupRepo.sendMessageToGroup(
      senderUID: senderUID,
      groupId: groupId,
      content: content,
    );
    result.fold((failure) => emit(GroupsError(failure.errMsg)), (_) {});
  }

  Future<void> deleteGroup(String groupId) async {
    emit(GroupsLoading());
    final result = await groupRepo.deleteGroup(groupId);
    result.fold((failure) => emit(GroupsError(failure.errMsg)), (_) {
      emit(GroupDeleted("Group deleted successfully"));
    });
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    emit(GroupsLoading());
    final result = await groupRepo.leaveGroup(groupId, userId);
    result.fold((failure) => emit(GroupsError(failure.errMsg)), (_) {});
  }

  Future<void> addMembersToGroup(String groupId, List<String> members) async {
    emit(GroupsLoading());
    final result = await groupRepo.addMembersToGroup(groupId, members);
    result.fold((failure) => emit(GroupsError(failure.errMsg)), (_) {});
  }

  Future<void> streamGroupMembers(String groupId) async {
    emit(GroupsLoading());
    final result = await groupRepo.streamGroupMembers(groupId);
    result.fold((failure) => emit(GroupsError(failure.errMsg)), (members) {
      _membersSub?.cancel();
      _membersSub = members.listen(
        (membersList) {
          emit(MembersStreamState(membersList));
        },
        onError: (error) {
          emit(GroupsError(error.toString()));
        },
      );
    });
  }

  Future<void> removeMemberFromGroup(String groupId, String memberId) async {
    emit(GroupsLoading());
    final result = await groupRepo.removeMemberFromGroup(
      groupId: groupId,
      userId: memberId,
    );
    result.fold((failure) => emit(GroupsError(failure.errMsg)), (_) {
      streamGroupMembers(groupId);
      emit(MemberRemoved("Member removed successfully"));
    });
  }

  Future<void> markGroupMessagesAsRead({
    required String groupId,
    required String userId,
  }) async {
    emit(GroupsLoading());
    final result = await groupRepo.markGroupMessagesAsRead(
      groupId: groupId,
      userId: userId,
    );
    result.fold((failure) => emit(GroupsError(failure.errMsg)), (_) {});
  }

  Future<void> updateGroupPicture({
    required String groupId,
    required File picture,
  }) async {
    emit(GroupsLoading());
    final result = await groupRepo.updateGroupPicture(
      groupId: groupId,
      picture: picture,
    );
    result.fold((failure) => emit(GroupsError(failure.errMsg)), (_) {});
  }

  @override
  Future<void> close() {
    _groupsSub?.cancel();
    return super.close();
  }
}
