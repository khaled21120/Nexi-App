import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexi/features/auth/data/models/user_model.dart';
import 'package:nexi/features/home/presentation/cubit/people_cubit.dart';

import '../../../../core/widgets/search_text_field.dart';
import 'widget/users_list_item.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
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
    return RefreshIndicator.adaptive(
      onRefresh: () async {
        context.read<PeopleCubit>().getUsers();
      },
      child: Column(
        children: [
          SearchTextField(
            searchController: _searchController,
            query: _query,
            clearSearch: _clearSearch,
          ),
          Expanded(
            child: BlocBuilder<PeopleCubit, PeopleState>(
              builder: (context, state) {
                if (state is PeopleLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is PeopleError) {
                  return Center(child: Text(state.message));
                } else if (state is PeopleLoaded) {
                  final users = _filterUsers(state.users, _query);
                  if (users.isEmpty) {
                    return const Center(
                      child: Text("No results match your search"),
                    );
                  }
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return UsersListItem(user: users[index]);
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

  List<UserModel> _filterUsers(List<UserModel> users, String query) {
    if (query.isEmpty) return users;
    return users
        .where((u) => u.name?.toLowerCase().contains(query) ?? false)
        .toList();
  }
}
