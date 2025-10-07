import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:nexi/features/profile/data/repos/profile_repo.dart';

import '../../../../core/utils/helper.dart';
import '../../../auth/data/models/user_model.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this.profileRepo) : super(ProfileInitial());
  final ProfileRepo profileRepo;
  StreamSubscription<UserModel>? _userSub;

  @override
  Future<void> close() {
    _userSub?.cancel();
    return super.close();
  }

  Future<void> getUserData() async {
    emit(ProfileLoading());
    final result = await profileRepo.getUserData();
    result.fold(
      (l) => emit(ProfileError(l.errMsg)),
      (r) => emit(ProfileLoaded(r)),
    );
  }
  Future<void> streamUserData(String userId) async {
    emit(ProfileLoading());
    final result = await profileRepo.streamUserData(userId);
    result.fold(
      (l) => emit(ProfileError(l.errMsg)),
      (r) {
        _userSub?.cancel();
        _userSub = r.listen((user) {
          emit(ProfileLoaded(user));
        });
      },
    );
  }

  Future<void> signOut() async {
    emit(ProfileLoading());
    final result = await profileRepo.signOut();
    result.fold(
      (l) => emit(ProfileError(l.errMsg)),
      (r) => emit(Logout('Logged out')),
    );
  }

  Future<void> deleteAccount() async {
    emit(ProfileLoading());
    final result = await profileRepo.deleteAccount();
    result.fold(
      (l) => emit(ProfileError(l.errMsg)),
      (r) => emit(DeleteAccount('Account Deleted')),
    );
  }

  Future<void> _updateProfileImage({required File image}) async {
    emit(ProfileLoading());
    final result = await profileRepo.updateProfileImage(image: image);
    result.fold((l) => emit(ProfileError(l.errMsg)), (r) {
      emit(ProfileImageUpdated('Profile image updated'));
      return getUserData();
    });
  }

  Future<void> updateProfileData({required Map<String, dynamic> data}) async {
    emit(ProfileLoading());
    final result = await profileRepo.updateProfileData(data: data);
    result.fold((l) => emit(ProfileError(l.errMsg)), (r) {
      emit(ProfileUpdated('Profile Updated'));
      return getUserData();
    });
  }

  Future<void> pickAndUploadImage({required bool isCamera}) async {
    final file = await Helper.pickImage(isCamera: isCamera);
    if (file != null) {
      await _updateProfileImage(image: file);
    }
  }
}
