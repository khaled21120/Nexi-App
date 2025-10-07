import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nexi/core/constants/app_colors.dart';
import 'package:shimmer/shimmer.dart';

import '../cubit/profile_cubit.dart';

class ProfilePicture extends StatelessWidget {
  const ProfilePicture({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final userImageUrl = state is ProfileLoaded
            ? state.user.photoUrl
            : null;
        final isLoading = state is ProfileLoading;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Main Avatar
            Hero(
              tag: 'profile-avatar',
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: .2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildProfileImage(context, userImageUrl),
                ),
              ),
            ),

            // Loading indicator on top
            if (isLoading)
              const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),

            // Edit Button
            Positioned(right: 5, bottom: 5, child: _buildEditButton(context)),
          ],
        );
      },
    );
  }

  Widget _buildProfileImage(BuildContext context, String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return GestureDetector(
        onTap: () =>
            GoRouter.of(context).pushNamed('image_preview', extra: imageUrl),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildShimmerAvatar(),
          errorWidget: (context, url, error) => _buildShimmerAvatar(),
        ),
      );
    }
    return _buildShimmerAvatar();
  }

  Widget _buildShimmerAvatar() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return InkWell(
      onTap: () => _showImagePickerOptions(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.edit_rounded, size: 28, color: Colors.white),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(ctx);
                  context.read<ProfileCubit>().pickAndUploadImage(
                    isCamera: true,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  context.read<ProfileCubit>().pickAndUploadImage(
                    isCamera: false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
