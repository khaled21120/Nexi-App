part of 'group_cubit.dart';

@immutable
sealed class GroupState {}

final class GroupInitial extends GroupState {}

final class GroupsLoading extends GroupState {}

final class GroupsLoaded extends GroupState {
  final List<GroupModel> groups;

  GroupsLoaded(this.groups);
}

final class GroupsError extends GroupState {
  final String message;

  GroupsError(this.message);
}

final class GroupUpdated extends GroupState {
  final String message;

  GroupUpdated(this.message);
}

class GroupCreated extends GroupState {
  final GroupModel group;
  GroupCreated(this.group);
}

class MembersStreamState extends GroupState {
  final List<UserModel> members;
  MembersStreamState(this.members);
}

final class GroupDeleted extends GroupState {
  final String message;

  GroupDeleted(this.message);
}

final class GroupLeft extends GroupState {
  final String message;

  GroupLeft(this.message);
}

final class MembersAdded extends GroupState {
  final String message;

  MembersAdded(this.message);
}

final class MemberRemoved extends GroupState {
  final String message;

  MemberRemoved(this.message);
}
