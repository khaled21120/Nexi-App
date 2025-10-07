// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:nexi/core/widgets/custom_text_field.dart';
import 'package:nexi/features/groups/data/models/group_model.dart';
import 'package:nexi/features/groups/presentation/cubit/group_cubit.dart';
import 'package:nexi/core/utils/helper.dart';

class GroupSettingsPage extends StatefulWidget {
  final GroupModel group;
  final String currentUserId;

  const GroupSettingsPage({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late bool isAdmin;
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  @override
  void initState() {
    super.initState();
    context.read<GroupCubit>().streamGroupMembers(widget.group.id!);
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(
      text: widget.group.description ?? '',
    );
    isAdmin = widget.group.adminId == widget.currentUserId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final updatedGroup = widget.group.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    await context.read<GroupCubit>().createOrUpdateGroup(updatedGroup);
    // ignore: duplicate_ignore
    // ignore: use_build_context_synchronously
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _confirmAction({
    required String title,
    required String content,
    required VoidCallback onConfirm,
    String confirmText = "Confirm",
    Color confirmColor = Colors.red,
  }) async {
    final ctx = context;
    final result = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText, style: TextStyle(color: confirmColor)),
          ),
        ],
      ),
    );

    if (result == true) onConfirm();
  }

  void _deleteGroup() {
    _confirmAction(
      title: "Delete Group",
      content:
          "Are you sure you want to delete this group? This action cannot be undone.",
      confirmText: "Delete",
      onConfirm: () {
        context.read<GroupCubit>().deleteGroup(widget.group.id!);
      },
    );
  }

  void _leaveGroup() {
    _confirmAction(
      title: "Leave Group",
      content: "Are you sure you want to leave this group?",
      confirmText: "Leave",
      confirmColor: Colors.orange,
      onConfirm: () {
        context.read<GroupCubit>().leaveGroup(
          widget.group.id!,
          widget.currentUserId,
        );
      },
    );
  }

  Future<void> _updateGroupPicture() async {
    final result = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final image = await _picker.pickImage(source: result);
      if (image != null) {
        setState(() => _pickedImage = File(image.path));
        await context.read<GroupCubit>().updateGroupPicture(
          groupId: widget.group.id!,
          picture: File(image.path),
        );
      }
    }
  }

  void _removeMember(String memberId) {
    _confirmAction(
      title: "Remove Member",
      content: "Are you sure you want to remove this member from the group?",
      confirmText: "Remove",
      onConfirm: () {
        context.read<GroupCubit>().removeMemberFromGroup(
          widget.group.id!,
          memberId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Settings"),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
              tooltip: "Save Changes",
            ),
        ],
      ),
      body: BlocConsumer<GroupCubit, GroupState>(
        listener: (context, state) {
          if (state is GroupsError) {
            Helper.showSnackBarMessage(context, state.message, true);
          } else if (state is GroupUpdated) {
            Helper.showSnackBarMessage(
              context,
              "Group updated successfully",
              false,
            );
            Navigator.pop(context);
          } else if (state is GroupDeleted) {
            Helper.showSnackBarMessage(context, state.message, false);
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (state is GroupLeft) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (state is MembersAdded) {
            Helper.showSnackBarMessage(
              context,
              "Member removed successfully",
              false,
            );
          } else if (state is MemberRemoved) {
            Helper.showSnackBarMessage(
              context,
              "Member removed successfully",
              false,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is GroupsLoading;
          final members = state is MembersStreamState ? state.members : [];

          return ModalProgressHUD(
            inAsyncCall: isLoading,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Group Image
                _buildGroupInfo(),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Members
                const Text(
                  "Members",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (members.isEmpty)
                  const Center(
                    child: Text(
                      "No members found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...members.map((member) {
                    final isCurrentUser = member.id == widget.currentUserId;
                    final isGroupAdmin = member.id == widget.group.adminId;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundImage: (member.photoUrl?.isNotEmpty ?? false)
                            ? CachedNetworkImageProvider(member.photoUrl!)
                            : FileImage(File(member.photoUrl!)),
                        child: (member.photoUrl?.isEmpty ?? true)
                            ? const Icon(Icons.person, size: 20)
                            : null,
                      ),
                      title: Row(
                        children: [
                          Text(member.name ?? 'Unknown'),
                          if (isGroupAdmin)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(member.email ?? ''),
                      trailing: isAdmin && !isCurrentUser && !isGroupAdmin
                          ? IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeMember(member.id!),
                            )
                          : null,
                    );
                  }),
                if (isAdmin) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text("Add Members"),
                    onPressed: () async {
                      final isDone = await context.pushNamed<bool?>(
                        'add_members',
                        extra: {
                          'group': widget.group,
                          'currentUserId': widget.currentUserId,
                        },
                      );
                      if (isDone == true) {
                        context.read<GroupCubit>().streamGroupMembers(
                          widget.group.id!,
                        );
                      }
                    },
                  ),
                ],

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                if (isAdmin)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text("Delete Group"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _deleteGroup,
                  ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  icon: const Icon(Icons.exit_to_app),
                  label: Text(isAdmin ? "Leave as Admin" : "Leave Group"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _leaveGroup,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupInfo() {
    return Column(
      children: [
        // Group Avatar with Edit Option
        Stack(
          children: [
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey[200],
              backgroundImage: _pickedImage != null
                  ? FileImage(_pickedImage!)
                  : widget.group.groupImage != null
                  ? CachedNetworkImageProvider(widget.group.groupImage!)
                  : null,
              child: widget.group.groupImage?.isEmpty != false
                  ? const Icon(Icons.group, size: 40, color: Colors.grey)
                  : null,
            ),
            if (isAdmin)
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: () => {_updateGroupPicture()},
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.edit, size: 30, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Group Name
        isAdmin
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Group Name",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CustomTextfield(
                    controller: _nameController,
                    hint: "Enter group name",
                  ),
                ],
              )
            : ListTile(
                title: const Text(
                  "Group Name",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(widget.group.name ?? "No name"),
              ),

        const SizedBox(height: 16),

        // Group Description
        isAdmin
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Group Description",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CustomTextfield(
                    controller: _descriptionController,
                    hint: "Enter group description",
                    validator: (val) {
                      if (val != null && val.length > 100) {
                        return "Description can't be more than 100 characters";
                      }
                      return null;
                    },
                  ),
                ],
              )
            : ListTile(
                title: const Text(
                  "Group Description",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(widget.group.description ?? "No description"),
              ),
      ],
    );
  }
}
