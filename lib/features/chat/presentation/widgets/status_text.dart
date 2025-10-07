import 'package:flutter/material.dart';

class AnimatedStatusText extends StatefulWidget {
  final String text;
  final bool isOnline;

  const AnimatedStatusText({
    super.key,
    required this.text,
    required this.isOnline,
  });

  @override
  State<AnimatedStatusText> createState() => _AnimatedStatusTextState();
}

class _AnimatedStatusTextState extends State<AnimatedStatusText> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startAnimation();
  }

  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_scrollController.hasClients && mounted) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          _scrollController
              .animateTo(
                maxScroll,
                duration: Duration(seconds: 5 + (maxScroll ~/ 20)),
                curve: Curves.linear,
              )
              .then((_) {
                if (mounted) {
                  _scrollController.jumpTo(0);
                  _startAnimation();
                }
              });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: widget.isOnline ? Colors.green : Colors.grey.shade600,
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}
