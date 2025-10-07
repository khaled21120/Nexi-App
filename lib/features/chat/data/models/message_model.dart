import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String authorId;
  final String? authorName;
  final String? authorImage;
  final String? text;
  final String? status;
  final String type;
  final DateTime? createdAt;
  final String? mediaUrl;
  final int? mediaSize;
  final String? fileName;
  final int? fileSize;
  final int? audioDuration;
  final String? fileUrl;

  MessageModel({
    this.fileSize,
    this.fileUrl,
    required this.id,
    required this.authorId,
    this.authorName,
    this.authorImage,
    this.text,
    this.status,
    required this.type,
    required this.createdAt,
    this.mediaUrl,
    this.mediaSize,
    this.audioDuration,
    this.fileName,
  });

  /// 🔹 Factory constructor to create a MessageModel from Firestore JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String?,
      authorImage: json['authorImage'] as String?,
      text: json['text'] as String?,
      type: json['type'] as String? ?? 'text',
      audioDuration: json['audioDuration'] as int?,
      status: json['status'] as String?,
createdAt: (json['createdAt'] is Timestamp)
    ? (json['createdAt'] as Timestamp).toDate()
    : (json['createdAt'] is String)
        ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
        : (json['createdAt'] is int)
            ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
            : DateTime.now(),
      mediaUrl: json['mediaUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      fileUrl: json['fileUrl'] as String?,
      mediaSize: json['mediaSize'] as int?,
    );
  }

  /// 🔹 Convert MessageModel into JSON (for Firestore)
  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'authorImage': authorImage,
    'text': text,
    'type': type,
    'status': status,
    'createdAt': createdAt,
    'audioDuration': audioDuration,
    'mediaUrl': mediaUrl,
    'fileName': fileName,
    'fileSize': fileSize,
    'fileUrl': fileUrl,
    'mediaSize': mediaSize,
  };
}
