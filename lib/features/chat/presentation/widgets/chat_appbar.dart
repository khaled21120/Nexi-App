import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nexi/features/auth/data/models/user_model.dart';
import 'package:nexi/features/chat/presentation/widgets/status_text.dart';
import 'package:nexi/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit/zego_uikit.dart';

class ChatAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String userId, roomId;

  const ChatAppBar({super.key, required this.userId, required this.roomId});

  @override
  State<ChatAppBar> createState() => _ChatAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70); // Increased height for better spacing
}

class _ChatAppBarState extends State<ChatAppBar> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().streamUserData(widget.userId);
  }

  String _getStatusText(UserModel user) {
    if (user.isOnline == true) return "Online";

    if (user.lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(user.lastSeen!);

      if (difference.inMinutes < 1) {
        return 'Last seen just now';
      } else if (difference.inHours < 1) {
        return 'Last seen ${difference.inMinutes} min ago';
      } else if (difference.inDays < 1) {
        return 'Last seen ${difference.inHours} hrs ago';
      } else {
        return 'Last seen on ${DateFormat.yMMMd().add_jm().format(user.lastSeen!)}';
      }
    }
    return "Offline";
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded) {
          final user = state.user;

          return AppBar(
            title: Row(
              children: [
                // Modern Avatar with gradient border
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: user.isOnline == true
                          ? [Colors.green, Colors.lightGreen]
                          : [Colors.grey, Colors.grey.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: user.photoUrl != null
                          ? CachedNetworkImageProvider(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 24,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name + Status with better typography
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? "Unknown",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          if (user.isOnline == true) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: user.isOnline == true
                                    ? Colors.green
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: AnimatedStatusText(
                              text: _getStatusText(user),
                              isOnline: user.isOnline == true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Call buttons with modern styling
                if (ZegoUIKitPrebuiltCallInvitationService().isInit) ...[
                  _buildCallButton(
                    icon: Icons.phone_rounded,
                    isVideoCall: false,
                    user: user,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  _buildCallButton(
                    icon: Icons.videocam_rounded,
                    isVideoCall: true,
                    user: user,
                    color: Colors.blue,
                  ),
                ],
              ],
            ),
          );
        }

        if (state is ProfileError) {
          return AppBar(
            backgroundColor: Colors.white,
            elevation: 2,
            title: Text(
              state.message,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          );
        }

        // Loading state with shimmer effect
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
              Column(
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required bool isVideoCall,
    required UserModel user,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: ZegoSendCallInvitationButton(
        icon: ButtonIcon(icon: Icon(icon, color: color)),
        iconSize: const Size(48, 48),
        isVideoCall: isVideoCall,
        resourceID: "nexi_call",
        buttonSize: const Size(48, 48),
        invitees: [ZegoUIKitUser(id: widget.userId, name: user.name ?? "User")],
      ),
    );
  }
}
