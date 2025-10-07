part of 'profile_cubit.dart';

@immutable
sealed class ProfileState {}

final class ProfileInitial extends ProfileState {}

final class ProfileUpdated extends ProfileState {
  final String message;
  ProfileUpdated(this.message);
}

final class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

final class ProfileLoading extends ProfileState {}

final class ProfileImageUpdated extends ProfileState {
  final String message;
  ProfileImageUpdated(this.message);
}

final class ProfileLoaded extends ProfileState {
  final UserModel user;
  ProfileLoaded(this.user);
}

final class ProfileImageError extends ProfileState {
  final String message;
  ProfileImageError(this.message);
}

final class Logout extends ProfileState {
  final String message;
  Logout(this.message);
}

final class DeleteAccount extends ProfileState {
  final String message;
  DeleteAccount(this.message);
}
