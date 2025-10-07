import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nexi/core/utils/helper.dart';

import '../../../../chat/data/models/rooms_model.dart';

class RoomListItem extends StatelessWidget {
  final RoomsModel room;

  const RoomListItem({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final name = room.receiverName ?? 'Unknown';
    final lastMessage = room.lastMessage ?? '';
    final photoUrl =
        room.receiverImage ??
        'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y';

    return InkWell(
      onTap: () {
        GoRouter.of(context).pushNamed(
          'chat',
          extra: {
            'id': room.receiverId,
            'name': room.receiverName,
            'photoUrl': room.receiverImage,
            'currentUser': Helper.getUserDataLocally(),
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Group Avatar with Member Count
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade100,
                  ),
                  child: photoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                _buildPlaceholderIcon(),
                          ),
                        )
                      : _buildPlaceholderIcon(),
                ),
              ],
            ),

            const SizedBox(width: 16),

            // Group Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Name and Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(room.lastMessageAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Last Message
                  Text(
                    lastMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Chevron Icon
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(Icons.group_rounded, size: 24, color: Colors.grey.shade400),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final difference = today.difference(messageDate).inDays;

    if (difference == 0) {
      return DateFormat.jm().format(dateTime); // Today - show time
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat.E().format(dateTime); // Day name
    } else {
      return DateFormat.Md().format(dateTime); // Month and day
    }
  }
}
