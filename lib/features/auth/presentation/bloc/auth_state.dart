part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class LoginLoading extends AuthState {}

final class LoginLoaded extends AuthState {
  final UserModel user;
  LoginLoaded({required this.user});
}

final class LoginError extends AuthState {
  final String errmsg;
  LoginError({required this.errmsg});
}

final class RegisterLoading extends AuthState {}

final class RegisterLoaded extends AuthState {
  final UserModel user;
  RegisterLoaded({required this.user});
}

final class RegisterError extends AuthState {
  final String errMsg;
  RegisterError({required this.errMsg});
}


final class AuthSignedOut extends AuthState {}

final class AuthResetPassword extends AuthState {
}

final class AuthGoogleSignIn extends AuthState {}

final class AuthError extends AuthState {
  final String errMsg;
  AuthError({required this.errMsg});
}
