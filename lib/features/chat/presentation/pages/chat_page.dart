// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:nexi/core/constants/app_colors.dart';
import 'package:nexi/core/constants/app_constants.dart';
import 'package:nexi/core/widgets/custom_text_field.dart';
import 'package:nexi/features/chat/presentation/widgets/chat_appbar.dart';
import 'package:nexi/features/chat/presentation/widgets/group_appbar.dart';
import 'package:nexi/features/groups/presentation/cubit/group_cubit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/utils/helper.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/message_model.dart';
import '../cubit/chats_cubit.dart';
import '../../../groups/data/models/group_model.dart';
import '../widgets/audio_player_message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.currentUser,
    required this.name,
    required this.photoUrl,
    required this.id,
    this.isGroup = false,
    this.group,
  });

  final String name;
  final String photoUrl;
  final String id;
  final bool isGroup;
  final UserModel currentUser;
  final GroupModel? group;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _picker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _player = AudioPlayer();

  final newTextController = TextEditingController();

  bool _isSending = false;
  bool _isRecording = false;
  bool _hasText = false;
  late final String roomId;

  @override
  void initState() {
    super.initState();
    roomId = widget.isGroup
        ? widget.group!.id!
        : Helper.getRoomId(widget.currentUser.id!, widget.id);

    if (widget.isGroup) {
      context.read<ChatsCubit>().listenToGroupMessages(roomId);
    } else {
      context.read<ChatsCubit>().listenToChatsMessages(roomId);
    }

    newTextController.addListener(() {
      final hasTextNow = newTextController.text.trim().isNotEmpty;
      if (hasTextNow != _hasText) {
        setState(() {
          _hasText = hasTextNow;
        });
      }
    });
  }

  @override
  void dispose() {
    newTextController.dispose();
    _audioRecorder.dispose();
    _player.dispose();
    super.dispose();
  }

  void _sendMessage(dynamic content) async {
    setState(() => _isSending = true);
    try {
      if (widget.isGroup) {
        await context.read<GroupCubit>().sendMessageToGroup(
          senderUID: widget.currentUser.id!,
          groupId: roomId,
          content: content,
        );
      } else {
        await context.read<ChatsCubit>().sendMessageToChat(
          senderId: widget.currentUser.id!,
          receiverId: widget.id,
          content: content,
        );
      }

      // Clear text field only for text messages
      if (content is String) {
        newTextController.clear();
      }
    } catch (e) {
      log('Send message error: $e');
      Helper.showSnackBarMessage(context, 'Failed to send message', true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async => await context
                .read<ChatsCubit>()
                .deleteMessage(
                  collectionName: widget.isGroup
                      ? AppConstants.groups
                      : AppConstants.rooms,
                  roomId: roomId,
                  messageId: messageId,
                )
                .then((_) => Navigator.pop(ctx, true)),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      log('Message deleted');
    }
  }

  Future<void> _updateMessage(String messageId, String message) async {
    newTextController.text = message;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Message'),
        content: CustomTextfield(
          controller: newTextController,
          label: 'New Message',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newText = newTextController.text.trim();
              if (newText.isNotEmpty) {
                await context
                    .read<ChatsCubit>()
                    .updateMessage(
                      collectionName: widget.isGroup
                          ? AppConstants.groups
                          : AppConstants.rooms,
                      roomId: roomId,
                      messageId: messageId,
                      data: {'text': newText},
                    )
                    .then((_) => Navigator.pop(ctx, true));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      log('Message updated');
    }
  }

  Future<void> _pickImage(ImageSource source, BuildContext ctx) async {
    Navigator.pop(ctx);
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );

    if (picked != null) {
      _sendMessage(File(picked.path));
    }
  }

  Future<void> _pickFile(BuildContext ctx) async {
    Navigator.pop(ctx);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        if (fileSize <= 10 * 1024 * 1024) {
          _sendMessage({
            'file': file,
            'name': result.files.single.name,
            'type': 'file',
          });
        } else {
          Helper.showSnackBarMessage(
            context,
            'File too large (max 10MB)',
            true,
          );
        }
      }
    } catch (e) {
      log('File pick error: $e');
      Helper.showSnackBarMessage(context, 'Failed to pick file', true);
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text("Gallery"),
              onTap: () => _pickImage(ImageSource.gallery, ctx),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text("Camera"),
              onTap: () => _pickImage(ImageSource.camera, ctx),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.orange),
              title: const Text("File"),
              onTap: () => _pickFile(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startAudio() async {
    try {
      final isGranted = await _audioRecorder.hasPermission();
      if (isGranted) {
        if (mounted) {
          setState(() {
            _isRecording = true;
          });
        }

        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/recordings';
        await Directory(path).create(recursive: true);
        final audioPath =
            '$path/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: audioPath);
      }
    } catch (e) {
      log('Audio recording error: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }
      Helper.showSnackBarMessage(context, 'Failed to start recording', true);
    }
  }

  Future<int> _getAudioDuration(String path) async {
    final duration = await _player.setFilePath(path);
    return duration?.inMilliseconds ?? 0;
  }

  Future<void> _stopAudio() async {
    try {
      final path = await _audioRecorder.stop();

      if (path != null && File(path).existsSync()) {
        setState(() => _isSending = true);

        final duration = await _getAudioDuration(path);

        _sendMessage({
          'file': File(path),
          'name': 'audio_${DateTime.now().millisecondsSinceEpoch}.webm',
          'type': 'audio',
          'mimeType': 'audio/webm',
          'audioDuration': duration,
        });
      }
    } catch (e) {
      Helper.showSnackBarMessage(context, 'Failed to save recording', true);
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }
    }
  }

  types.Message _mapMessage(MessageModel m) {
    final author = types.User(
      id: m.authorId,
      firstName: m.authorName ?? 'Unknown',
      imageUrl: (m.authorImage != null && m.authorImage!.isNotEmpty)
          ? m.authorImage
          : null, // 👈 very important
    );

    final createdAt = m.createdAt?.millisecondsSinceEpoch;

    switch (m.type) {
      case 'image':
        return types.ImageMessage(
          id: m.id,
          author: author,
          uri: m.mediaUrl ?? '',
          createdAt: createdAt,

          name: m.fileName ?? 'Image',
          size: m.mediaSize ?? 0,
          showStatus: true,
          status: _mapStatus(m.status),
        );
      case 'file':
        return types.FileMessage(
          id: m.id,
          author: author,
          name: m.fileName ?? 'File',
          size: m.fileSize ?? 0,
          uri: m.fileUrl ?? '',
          createdAt: createdAt,
          showStatus: true,
          status: _mapStatus(m.status),
        );
      case 'audio':
        return types.AudioMessage(
          id: m.id,
          author: author,
          uri: m.mediaUrl ?? '',
          createdAt: createdAt,
          showStatus: true,
          status: _mapStatus(m.status),
          duration: Duration(milliseconds: m.audioDuration ?? 0),
          name: m.fileName ?? 'Audio',
          size: m.mediaSize ?? 0,
          mimeType: "audio/m4a",
        );
      default:
        return types.TextMessage(
          id: m.id,
          author: author,
          text: m.text ?? '',
          createdAt: createdAt,
          showStatus: true,
          status: _mapStatus(m.status),
        );
    }
  }

  types.Status? _mapStatus(String? status) {
    switch (status) {
      case 'sent':
        return types.Status.sent;
      case 'delivered':
        return types.Status.delivered;
      case 'read':
        return types.Status.seen;
      case 'seen':
        return types.Status.seen;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isGroup
          ? GroupAppbar(group: widget.group!)
          : ChatAppBar(userId: widget.id, roomId: roomId),
      body: BlocConsumer<ChatsCubit, ChatsState>(
        listener: (context, state) {
          if (state is ChatsError) {
            Helper.showSnackBarMessage(context, state.message, true);
          }
        },
        builder: (context, state) {
          if (state is ChatsMessagesStream) {
            return StreamBuilder<List<MessageModel>>(
              stream: state.messages,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                _updateStatus(messages, context);
                final chatMessages = messages.map(_mapMessage).toList();

                return ModalProgressHUD(
                  inAsyncCall: _isSending,
                  child: Chat(
                    key: ValueKey(roomId),
                    messages: chatMessages,
                    user: types.User(
                      id: widget.currentUser.id!,
                      firstName: widget.currentUser.name,
                      imageUrl: widget.currentUser.photoUrl,
                    ),
                    theme: const DefaultChatTheme(
                      primaryColor: AppColors.primary,
                      inputBackgroundColor: Colors.white,
                      inputTextColor: Colors.black87,
                      sendButtonIcon: Icon(
                        Icons.send_rounded,
                        color: Colors.blue,
                      ),
                    ),
                    showUserAvatars: true,
                    showUserNames: widget.isGroup,
                    dateFormat: DateFormat.yMMMd(),
                    timeFormat: DateFormat.jm(),
                    onMessageTap: (context, p1) {
                      if (p1 is types.FileMessage) {
                        Helper.fileLaunch(p1.uri);
                      }
                    },
                    audioMessageBuilder: (message, {required int messageWidth}) {
                      final isMine = message.author.id == widget.currentUser.id;
                      return AudioMessageBubble(
                        message: message,
                        isMine: isMine,
                      );

                      // For other message types, return empty to use default rendering
                    },
                    onAttachmentPressed: _showAttachmentOptions,
                    onSendPressed: (partial) {
                      if (partial.text.trim().isNotEmpty) {
                        _sendMessage(partial.text);
                      }
                    },
                    onMessageLongPress: (ctx, message) {
                      final isMine = message.author.id == widget.currentUser.id;
                      if (!isMine) return;

                      showModalBottomSheet(
                        context: ctx,
                        builder: (c) => Wrap(
                          children: [
                            if (message is types.TextMessage)
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text('Edit'),
                                onTap: () {
                                  Navigator.pop(c);
                                  _updateMessage(message.id, (message).text);
                                },
                              ),
                            ListTile(
                              leading: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              title: const Text('Delete'),
                              onTap: () {
                                Navigator.pop(c);
                                _deleteMessage(message.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    customBottomWidget: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          // Attachment button
                          IconButton(
                            icon: const Icon(
                              Icons.attach_file,
                              color: Colors.blue,
                            ),
                            onPressed: _showAttachmentOptions,
                          ),

                          // Text field
                          Expanded(
                            child: TextField(
                              controller: newTextController,
                              decoration: const InputDecoration(
                                hintText: "Type a message...",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (text) {
                                if (text.trim().isNotEmpty) {
                                  _sendMessage(text);
                                  newTextController.clear();
                                }
                              },
                            ),
                          ),

                          // Mic/Send button
                          IconButton(
                            icon: Icon(
                              _isRecording
                                  ? Icons.stop
                                  : _hasText
                                  ? Icons.send
                                  : Icons.mic,
                              color: _isRecording
                                  ? Colors.red
                                  : _hasText
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            onPressed: () async {
                              if (_isRecording) {
                                await _stopAudio();
                              } else if (_hasText) {
                                final text = newTextController.text.trim();
                                if (text.isNotEmpty) {
                                  _sendMessage(text);
                                  newTextController.clear();
                                }
                              } else {
                                await _startAudio();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _updateStatus(List<MessageModel> messages, BuildContext context) {
    if (messages.isNotEmpty) {
      final unreadExists = messages.any(
        (m) =>
            m.authorId != widget.currentUser.id &&
            (m.status == 'sent' || m.status == 'delivered'),
      );

      if (unreadExists) {
        if (widget.isGroup) {
          context.read<GroupCubit>().markGroupMessagesAsRead(
            groupId: roomId,
            userId: widget.currentUser.id!,
          );
        } else {
          context.read<ChatsCubit>().markChatMessagesAsRead(
            roomId: roomId,
            userId: widget.currentUser.id!,
          );
        }
      }
    }
  }
}
