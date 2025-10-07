import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:nexi/features/home/data/repos/home_repo.dart';

import '../../../auth/data/models/user_model.dart';

part 'people_state.dart';

class PeopleCubit extends Cubit<PeopleState> {
  PeopleCubit(this.homeRepo) : super(PeopleInitial());
  final HomeRepo homeRepo;

  List<UserModel> users = [];
  StreamSubscription<List<UserModel>>? _peopleSub;

  Future<void> getUsers() async {
    emit(PeopleLoading());
    final result = await homeRepo.getAllPeople();
    result.fold((failure) => emit(PeopleError(failure.errMsg)), (usersStream) {
      _peopleSub?.cancel();
      _peopleSub = usersStream.listen(
        (usersList) {
          users = usersList;
          emit(PeopleLoaded(users));
        },
        onError: (error) {
          emit(PeopleError(error.toString()));
        },
      );
    });
  }

  @override
  Future<void> close() {
    _peopleSub?.cancel();
    return super.close();
  }

  void updateOnlineStatus({required userId, required bool isOnline}) async {
    final result = await homeRepo.updateOnlineStatus(userId, isOnline);
    result.fold((failure) => emit(PeopleError(failure.errMsg)), (success) {
      // Optionally handle success if needed
    });
  }
}
