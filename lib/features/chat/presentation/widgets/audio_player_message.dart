import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nexi/core/constants/app_colors.dart';

class AudioMessageBubble extends StatefulWidget {
  final AudioMessage message;
  final bool isMine;

  const AudioMessageBubble({
    super.key,
    required this.message,
    this.isMine = false,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _duration = widget.message.duration;

    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading =
              state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });
      }
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to errors
    _player.playbackEventStream.listen(
      (event) {},
      onError: (error) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isPlaying = false;
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      try {
        setState(() {
          _hasError = false;
          _isLoading = true;
        });

        // Check if we need to load the audio
        if (_player.audioSource == null) {
          if (widget.message.uri.startsWith('http')) {
            await _player.setUrl(widget.message.uri);
          } else {
            await _player.setFilePath(widget.message.uri);
          }
        }

        await _player.play();
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _seekAudio(double value) async {
    final position = Duration(
      milliseconds: (value * _duration.inMilliseconds).toInt(),
    );
    await _player.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isMine ? AppColors.primary : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button
          IconButton(
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isMine ? Colors.white : theme.primaryColor,
                      ),
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: _hasError
                        ? Colors.red
                        : (widget.isMine ? Colors.white : theme.primaryColor),
                    size: 24,
                  ),
            onPressed: _hasError ? null : _togglePlay,
          ),

          const SizedBox(width: 8),

          // Progress Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    activeTrackColor: widget.isMine
                        ? Colors.white
                        : theme.primaryColor,
                    inactiveTrackColor: widget.isMine
                        ? Colors.white.withValues(alpha:0.5)
                        : Colors.grey.withValues(alpha:0.5),
                    thumbColor: widget.isMine
                        ? Colors.white
                        : theme.primaryColor,
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? (_position.inMilliseconds / _duration.inMilliseconds)
                              .clamp(0.0, 1.0)
                        : 0.0,
                    onChanged: _duration.inMilliseconds > 0 ? _seekAudio : null,
                  ),
                ),

                const SizedBox(height: 4),

                // Time Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isMine
                            ? Colors.white.withValues(alpha:0.8)
                            : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isMine
                            ? Colors.white.withValues(alpha:0.8)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Error Icon
          if (_hasError) ...[
            const SizedBox(width: 8),
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
          ],
        ],
      ),
    );
  }
}
