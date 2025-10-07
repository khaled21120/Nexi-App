part of 'people_cubit.dart';

@immutable
sealed class PeopleState {}

final class PeopleInitial extends PeopleState {}

final class PeopleLoading extends PeopleState {}

final class PeopleLoaded extends PeopleState {
  final List<UserModel> users;
  PeopleLoaded(this.users);
}

final class PeopleError extends PeopleState {
  final String message;
  PeopleError(this.message);
}

