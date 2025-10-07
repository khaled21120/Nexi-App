import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

import '../../data/models/user_model.dart';
import '../../data/repos/auth_repo.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepo authRepo;
  AuthBloc({required this.authRepo}) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<ResetPasswordEvent>(_resetPassword);
    on<SignInWithGoogleEvent>(_googleSignIn);
    on<SignInWithFacebookEvent>(_facebookSignIn);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(LoginLoading());
    final result = await authRepo.signIn(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(LoginError(errmsg: failure.errMsg)),
      (user) => emit(LoginLoaded(user: user)),
    );
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(RegisterLoading());
    final result = await authRepo.signUp(
      name: event.name,
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(RegisterError(errMsg: failure.errMsg)),
      (user) => emit(RegisterLoaded(user: user)),
    );
  }


  Future<void> _resetPassword(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(RegisterLoading());
    final result = await authRepo.resetPassword(email: event.email);
    result.fold(
      (failure) => emit(RegisterError(errMsg: failure.errMsg)),
      (user) => emit(AuthResetPassword()),
    );
  }

  Future<void> _googleSignIn(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(RegisterLoading());
    final result = await authRepo.signInWithGoogle();
    result.fold(
      (failure) => emit(RegisterError(errMsg: failure.errMsg)),
      (user) => emit(RegisterLoaded(user: user)),
    );
  }

  Future<void> _facebookSignIn(
    SignInWithFacebookEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(RegisterLoading());
    final result = await authRepo.signUpWithFacebook();
    result.fold(
      (failure) => emit(RegisterError(errMsg: failure.errMsg)),
      (user) => emit(RegisterLoaded(user: user)),
    );
  }
}
