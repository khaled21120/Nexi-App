import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/group_model.dart';
import '../cubit/group_cubit.dart';
import '../../../home/presentation/cubit/people_cubit.dart';

class AddMembersPage extends StatefulWidget {
  final GroupModel group;
  final String currentUserId;

  const AddMembersPage({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  @override
  State<AddMembersPage> createState() => _AddMembersPageState();
}

class _AddMembersPageState extends State<AddMembersPage> {
  final Set<String> _selectedMembers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Members"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _selectedMembers.isNotEmpty
                ? () async {
                    await context.read<GroupCubit>().addMembersToGroup(
                      widget.group.id!,
                      _selectedMembers.toList(),
                    );
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                : null,
          ),
        ],
      ),
      body: BlocBuilder<PeopleCubit, PeopleState>(
        builder: (context, state) {
          if (state is PeopleLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PeopleError) {
            return Center(child: Text(state.message));
          } else if (state is PeopleLoaded) {
            final users = state.users
                .where((u) => u.id != widget.currentUserId)
                .where((u) => u.id != widget.group.adminId)
                .where((u) => !(widget.group.members?.contains(u.id) ?? false))
                .toList();

            if (users.isEmpty) {
              return const Center(child: Text("No users available"));
            }

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isSelected = _selectedMembers.contains(user.id);

                return CheckboxListTile(
                  title: Text(user.name ?? "Unknown"),
                  subtitle: Text(user.email ?? ""),
                  value: isSelected,
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedMembers.add(user.id!);
                      } else {
                        _selectedMembers.remove(user.id!);
                      }
                    });
                  },
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
