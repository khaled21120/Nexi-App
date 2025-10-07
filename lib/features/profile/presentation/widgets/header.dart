import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexi/core/utils/font_style.dart';
import '../../../auth/data/models/user_model.dart';
import 'profile_picture.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final createdAt = DateFormat.yMMMd().format(
      user.createdAt ?? DateTime.now(),
    );

    return Column(
      children: [
        // Profile Picture with Status
        const ProfilePicture(),

        const SizedBox(height: 20),

        // User Name
        Text(
          user.name ?? 'User Name',
          style: AppFontStyle.title28.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Email
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_rounded, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              user.email ?? 'Email not provided',
              style: AppFontStyle.subtitle18.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            if (user.isOnline == true)
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Join Date
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'Joined $createdAt',
                style: AppFontStyle.body14.copyWith(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
