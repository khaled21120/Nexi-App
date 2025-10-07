import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nexi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nexi/features/groups/presentation/cubit/group_cubit.dart';
import 'package:nexi/features/home/presentation/cubit/people_cubit.dart';
import 'package:nexi/features/chat/presentation/pages/chat_page.dart';
import 'package:nexi/features/groups/presentation/pages/group_settings_page.dart';
import 'package:nexi/features/home/presentation/views/home_page.dart';
import 'package:nexi/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nexi/main.dart';

import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/data/repos/auth_repo.dart';
import '../../features/auth/presentation/views/auth_page.dart';
import '../../features/groups/data/models/group_model.dart';
import '../../features/chat/presentation/cubit/chats_cubit.dart';
import '../../features/groups/presentation/pages/add_member_page.dart';
import '../../features/groups/presentation/pages/groups_page.dart';
import '../../features/groups/presentation/pages/create_group_page.dart';
import '../../features/profile/presentation/views/settings_page.dart';
import '../../features/profile/presentation/widgets/image_preview.dart';
import '../services/get_it_service.dart';
import 'helper.dart';

abstract class AppRouter {
  static final authRepo = getIt<AuthRepo>();
  static final router = GoRouter(
    navigatorKey: navigatorKey,
    redirect: (context, state) async {
      final isSignedIn = await authRepo.isSignedIn();
      final matchedLocation = state.matchedLocation == '/';
      if (isSignedIn && matchedLocation) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'auth',
        builder: (_, _) => BlocProvider(
          create: (_) => AuthBloc(authRepo: getIt()),
          child: const AuthPage(),
        ),
      ),
      GoRoute(
        path: '/image_preview',
        name: 'image_preview',
        builder: (_, state) {
          final imageUrl = state.extra as String;
          return FullImagePreview(imageUrl: imageUrl);
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => getIt.get<ChatsCubit>()..getChats()),
            BlocProvider(create: (_) => getIt.get<PeopleCubit>()..getUsers()),
            BlocProvider(
              create: (_) => getIt.get<ProfileCubit>()..getUserData(),
            ),
          ],
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: '/groups',
        name: 'groups',
        builder: (_, __) => BlocProvider(
          create: (_) => getIt.get<GroupCubit>()..getGroups(),
          child: const GroupsPage(),
        ),
      ),
      GoRoute(
        path: '/profile_settings',
        name: 'profile_settings',
        builder: (_, state) {
          final user = state.extra as UserModel;
          return BlocProvider(
            create: (context) => getIt.get<ProfileCubit>(),
            child: SettingsPage(user: user),
          );
        },
      ),
      GoRoute(
        path: '/group_settings',
        name: 'group_settings',
        builder: (_, state) {
          final group = state.extra as GroupModel;
          return BlocProvider(
            create: (_) => getIt.get<GroupCubit>()..getGroups(),
            child: GroupSettingsPage(
              group: group,
              currentUserId: Helper.getUserDataLocally()!.id!,
            ),
          );
        },
      ),
      GoRoute(
        path: '/add_members',
        name: 'add_members',
        builder: (_, state) {
          final extras = state.extra as Map<String, dynamic>;
          final group = extras['group'] as GroupModel;
          final currentUserId = extras['currentUserId'] as String;

          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => getIt.get<PeopleCubit>()..getUsers(),
              ),
              BlocProvider(create: (context) => getIt.get<GroupCubit>()),
            ],
            child: AddMembersPage(group: group, currentUserId: currentUserId),
          );
        },
      ),

      GoRoute(
        path: '/create_group',
        name: 'create_group',
        builder: (_, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => getIt.get<GroupCubit>()),
            BlocProvider(create: (_) => getIt.get<PeopleCubit>()..getUsers()),
          ],
          child: CreateGroupPage(currentUserId: state.extra as String),
        ),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (_, state) {
          final map = state.extra as Map<String, dynamic>;
          final id = map['id'] as String;
          final name = map['name'] as String;
          final isGroup = map['isGroup'] as bool? ?? false;
          final photoUrl = map['photoUrl'] as String;
          final currentUser = map['currentUser'] as UserModel;
          final group = map['group'] as GroupModel?;
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => getIt.get<ChatsCubit>()),
              BlocProvider(create: (context) => getIt.get<GroupCubit>()),
              BlocProvider(create: (context) => getIt.get<ProfileCubit>()),
            ],
            child: ChatPage(
              currentUser: currentUser,
              name: name,
              photoUrl: photoUrl,
              isGroup: isGroup,
              id: id,
              group: group,
            ),
          );
        },
      ),
    ],
  );
}
