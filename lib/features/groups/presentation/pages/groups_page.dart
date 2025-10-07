import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nexi/features/groups/presentation/cubit/group_cubit.dart';
import 'package:nexi/features/home/presentation/views/widgets/shimmer_list_item.dart';

import '../../../../core/utils/helper.dart';
import '../../../../core/widgets/search_text_field.dart';
import '../../data/models/group_model.dart';
import '../widgets/group_list_item.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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
    final id = Helper.getUserDataLocally()!.id!;
    return Scaffold(
      appBar: AppBar(title: const Text('Groups'), centerTitle: true),
      body: RefreshIndicator.adaptive(
        onRefresh: () async {
          context.read<GroupCubit>().getGroups();
        },
        child: Column(
          children: [
            SearchTextField(
              searchController: _searchController,
              query: _query,
              clearSearch: _clearSearch,
            ),
            Expanded(
              child: BlocConsumer<GroupCubit, GroupState>(
                listener: (context, state) {
                  if (state is GroupCreated) {
                    GoRouter.of(context).pushNamed(
                      'chat',
                      extra: {
                        'isGroup': true,
                        'id': state.group.id,
                        'name': state.group.name,
                        'photoUrl': state.group.groupImage,
                        'currentUser': Helper.getUserDataLocally(),
                        'group': state.group,
                      },
                    );
                  }
                },
                builder: (context, state) {
                  if (state is GroupsLoading) {
                    return ListView.builder(
                      itemCount: 10,
                      itemBuilder: (_, _) {
                        return const ShimmerListItem();
                      },
                    );
                  } else if (state is GroupsError) {
                    return Center(child: Text(state.message));
                  } else if (state is GroupsLoaded) {
                    if (state.groups.isEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("You haven't joined any groups yet"),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              context.pushNamed('create_group', extra: id);
                            },
                            child: const Text('Create Group'),
                          ),
                        ],
                      );
                    }
                    final group = _filterGroups(state.groups, _query);
                    if (group.isEmpty) {
                      return const Center(
                        child: Text("No results match your search"),
                      );
                    }
                    return ListView.builder(
                      itemCount: group.length,
                      itemBuilder: (_, index) {
                        return GroupListItem(group: group[index]);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<GroupModel> _filterGroups(List<GroupModel> groups, String query) {
    if (query.isEmpty) return groups;
    return groups
        .where((u) => u.name?.toLowerCase().contains(query) ?? false)
        .toList();
  }
}
