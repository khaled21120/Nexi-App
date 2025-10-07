import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 35),

          // Avatar placeholder
          Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Name placeholder
          Container(
            width: 120,
            height: 20,
            color: Colors.white,
          ),

          const SizedBox(height: 8),

          // Email placeholder
          Container(
            width: 180,
            height: 16,
            color: Colors.white,
          ),

          const SizedBox(height: 30),

          // Logout button placeholder
          Container(
            width: 140,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}
