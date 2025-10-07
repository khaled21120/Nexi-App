import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FullImagePreview extends StatelessWidget {
  final String imageUrl;

  const FullImagePreview({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: Hero(
              tag: 'profile-avatar',
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.white, size: 50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
