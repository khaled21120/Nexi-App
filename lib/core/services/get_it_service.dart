import 'package:get_it/get_it.dart';
import 'package:nexi/features/auth/data/repos/auth_repo_impl.dart';
import 'package:nexi/features/home/data/repos/home_repo.dart';
import 'package:nexi/features/groups/presentation/cubit/group_cubit.dart';
import 'package:nexi/features/home/presentation/cubit/people_cubit.dart';
import 'package:nexi/features/profile/data/repos/profile_repo.dart';
import 'package:nexi/features/profile/presentation/cubit/profile_cubit.dart';

import '../../features/auth/data/repos/auth_repo.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/chat/data/repos/chat_repo.dart';
import '../../features/chat/data/repos/chat_repo_impl.dart';
import '../../features/groups/data/repos/group_repo.dart';
import '../../features/groups/data/repos/group_repo_impl.dart';
import '../../features/home/data/repos/home_repo_impl.dart';
import '../../features/chat/presentation/cubit/chats_cubit.dart';
import '../../features/profile/data/repos/profile_repo_impl.dart';
import 'fire_auth_service.dart';
import 'firestore_service.dart';

final getIt = GetIt.instance;

void initGetItService() {
  _setupBloc();
  _setupRepos();
  _setupServices();
}

void _setupServices() {
  getIt.registerLazySingleton<FireAuthService>(() => FireAuthService());
  getIt.registerLazySingleton<FirestoreService>(() => FirestoreService());
}

void _setupRepos() {
  getIt.registerLazySingleton<AuthRepo>(
    () => AuthRepoImpl(firestoreService: getIt(), fireAuthService: getIt()),
  );
  getIt.registerLazySingleton<HomeRepo>(() => HomeRepoImpl(getIt()));
  getIt.registerLazySingleton<ProfileRepo>(
    () => ProfileRepoImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<GroupRepo>(() => GroupRepoImpl(getIt()));
  getIt.registerLazySingleton<ChatRepo>(() => ChatRepoImpl(getIt()));
}

void _setupBloc() {
  getIt.registerFactory<AuthBloc>(() => AuthBloc(authRepo: getIt()));
  getIt.registerFactory<ChatsCubit>(() => ChatsCubit(getIt()));
  getIt.registerFactory<PeopleCubit>(() => PeopleCubit(getIt()));
  getIt.registerFactory<ProfileCubit>(() => ProfileCubit(getIt()));
  getIt.registerFactory<GroupCubit>(() => GroupCubit(getIt()));
}
