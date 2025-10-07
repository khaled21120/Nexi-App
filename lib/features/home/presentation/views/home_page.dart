import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexi/core/widgets/search_text_field.dart';
import 'package:nexi/features/home/presentation/cubit/people_cubit.dart';
import 'package:nexi/features/home/presentation/views/people_page.dart';
import '../../../../core/services/zego_service.dart';
import '../../../../core/utils/helper.dart';
import '../../../profile/presentation/views/profile_page.dart';
import '../../../chat/data/models/rooms_model.dart';
import '../../../chat/presentation/cubit/chats_cubit.dart';
import 'widget/room_list_item.dart';
import 'widget/shimmer_list_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _pageController = PageController();
  Timer? _debounce;
  String _query = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final peopleCubit = context.read<PeopleCubit>();
    final user = Helper.getUserDataLocally();
    final userId = user?.id;

    if (userId == null || user == null) return;

    if (state == AppLifecycleState.resumed) {
      peopleCubit.updateOnlineStatus(userId: userId, isOnline: true);
      ZegoService.updateUser(userId, user.name ?? '');
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      peopleCubit.updateOnlineStatus(userId: userId, isOnline: false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex != 2 ? AppBar(title: const Text('Nexi')) : null,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildHomeContent(),
          const PeoplePage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator.adaptive(
      onRefresh: () async {
        context.read<ChatsCubit>().getChats();
      },
      child: Column(
        children: [
          SearchTextField(
            searchController: _searchController,
            query: _query,
            clearSearch: _clearSearch,
          ),
          Expanded(
            child: BlocBuilder<ChatsCubit, ChatsState>(
              builder: (context, state) {
                if (state is ChatsLoading) {
                  return ListView.builder(
                    itemCount: 8,
                    itemBuilder: (_, _) => const ShimmerListItem(),
                  );
                } else if (state is ChatsError) {
                  return Center(child: Text(state.message));
                } else if (state is ChatsLoaded) {
                  final rooms = _filterUsers(state.users, _query);
                  if (rooms.isEmpty) {
                    return const Center(
                      child: Text("No results match your search"),
                    );
                  }
                  return ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      return Dismissible(
                        key: Key(rooms[index].roomId ?? ''),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          context.read<ChatsCubit>().deleteChat(
                            rooms[index].roomId ?? '',
                          );
                        },
                        direction: DismissDirection.endToStart,
                        child: RoomListItem(room: rooms[index]),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.fastEaseInToSlowEaseOut,
            );
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue.shade700,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: -0.2,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
          items: [
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _currentIndex == 0
                      ? LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.home_rounded,
                  color: _currentIndex == 0
                      ? Colors.white
                      : Colors.grey.shade500,
                  size: 22,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _currentIndex == 1
                      ? LinearGradient(
                          colors: [
                            Colors.purple.shade400,
                            Colors.purple.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.people_alt_rounded,
                  color: _currentIndex == 1
                      ? Colors.white
                      : Colors.grey.shade500,
                  size: 22,
                ),
              ),
              label: 'People',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _currentIndex == 2
                      ? LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: _currentIndex == 2
                      ? Colors.white
                      : Colors.grey.shade500,
                  size: 22,
                ),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  List<RoomsModel> _filterUsers(List<RoomsModel> users, String query) {
    if (query.isEmpty) return users;
    return users
        .where((u) => u.receiverName?.toLowerCase().contains(query) ?? false)
        .toList();
  }
}
