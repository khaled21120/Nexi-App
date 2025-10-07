import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nexi/core/widgets/custom_text_field.dart';
import 'package:nexi/features/groups/data/models/group_model.dart';
import 'package:nexi/features/home/presentation/cubit/people_cubit.dart';

import '../../../../core/utils/helper.dart';
import '../cubit/group_cubit.dart';
import '../widgets/people_list_item.dart';

class CreateGroupPage extends StatefulWidget {
  final String currentUserId;

  const CreateGroupPage({super.key, required this.currentUserId});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<String> _selectedMembers = {};

  @override
  void initState() {
    super.initState();
    _selectedMembers.add(widget.currentUserId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createGroup() async {
    if (_formKey.currentState!.validate()) {
      final group = GroupModel(
        name: _nameController.text.trim(),
        adminId: widget.currentUserId,
        members: _selectedMembers.toList(),
      );

      await context.read<GroupCubit>().createOrUpdateGroup(group);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Group"),
        actions: [
          if (_selectedMembers.length > 1)
            TextButton(
              onPressed: _createGroup,
              child: BlocBuilder<GroupCubit, GroupState>(
                builder: (context, state) {
                  return state is GroupsLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create');
                },
              ),
            ),
        ],
      ),
      body: BlocConsumer<GroupCubit, GroupState>(
        listener: (context, state) {
          if (state is GroupCreated) {
            Navigator.of(context).pop();
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
          } else if (state is GroupsError) {
            Helper.showSnackBarMessage(context, state.message, true);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Group Name Input
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Group Name Input
                          Text(
                            'Group Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextfield(
                            controller: _nameController,
                            label: 'Enter group name...',
                            validator: (value) => value == null || value.isEmpty
                                ? "Please enter a group name"
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Members Counter
              _buildMembersCounter(context),

              const SizedBox(height: 8),

              // Members List
              Expanded(child: _buildUsersCheckList()),

              // Create Button
              if (_selectedMembers.length < 2)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Add at least one more member to create a group",
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMembersCounter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.group,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_selectedMembers.length} Members',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersCheckList() {
    return BlocBuilder<PeopleCubit, PeopleState>(
      builder: (context, state) {
        if (state is PeopleLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PeopleError) {
          return Center(child: Text(state.message));
        } else if (state is PeopleLoaded) {
          final users = state.users
              .where((user) => user.id != widget.currentUserId)
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              itemBuilder: (context, index) {
                final user = users[index];
                final isSelected = _selectedMembers.contains(user.id);

                return PeopleListItem(
                  user: user,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedMembers.remove(user.id!);
                      } else {
                        _selectedMembers.add(user.id!);
                      }
                    });
                  },
                );
              },
              itemCount: users.length,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
