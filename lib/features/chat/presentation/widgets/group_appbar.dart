import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nexi/features/groups/data/models/group_model.dart';
import 'package:nexi/features/groups/presentation/cubit/group_cubit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit/zego_uikit.dart';

import '../../../auth/data/models/user_model.dart';
import 'status_text.dart';

class GroupAppbar extends StatefulWidget implements PreferredSizeWidget {
  final GroupModel group;

  const GroupAppbar({super.key, required this.group});

  @override
  State<GroupAppbar> createState() => _GroupAppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _GroupAppbarState extends State<GroupAppbar> {
  @override
  void initState() {
    super.initState();
    context.read<GroupCubit>().streamGroupMembers(widget.group.id!);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupCubit, GroupState>(
      builder: (context, state) {
        if (state is MembersStreamState) {
          final members = state.members;
          return AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: Row(
              children: [
                // Group Avatar
                InkWell(
                  onTap: () {
                    context.pushNamed('group_settings', extra: widget.group);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: widget.group.groupImage != null && widget.group.groupImage!.isNotEmpty
                          ? CachedNetworkImageProvider(widget.group.groupImage!)
                          : null,
                      child: widget.group.groupImage == null || widget.group.groupImage!.isEmpty
                          ? const Icon(
                              Icons.group,
                              size: 24,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Group Name + Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.group.name ?? "Unknown Group",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AnimatedStatusText(
                        text: widget.group.description ?? "No description",
                        isOnline: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Call buttons
                if (ZegoUIKitPrebuiltCallInvitationService().isInit) ...[
                  _buildCallButton(
                    icon: Icons.phone_rounded,
                    isVideoCall: false,
                    users: members,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  _buildCallButton(
                    icon: Icons.videocam_rounded,
                    isVideoCall: true,
                    users: members,
                    color: Colors.blue,
                  ),
                ],
              ],
            ),
          );
        }

        // Error state
        if (state is GroupsError) {
          return AppBar(
            backgroundColor: Colors.white,
            title: Text(
              "Error loading group",
              style: TextStyle(color: Colors.red.shade600, fontSize: 16),
            ),
          );
        }

        // Loading state
        return AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          title: Row(
            children: [
              // Shimmer avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required bool isVideoCall,
    required List<UserModel> users,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha:.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha:0.3), width: 1.5),
      ),
      child: ZegoSendCallInvitationButton(
        icon: ButtonIcon(icon: Icon(icon, color: color)),
        iconSize: const Size(48, 48),
        isVideoCall: isVideoCall,
        resourceID: "nexi_call",
        buttonSize: const Size(48, 48),
        invitees: users
            .map(
              (user) => ZegoUIKitUser(id: user.id!, name: user.name ?? "User"),
            )
            .toList(),
      ),
    );
  }
}
