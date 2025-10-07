import 'package:cloud_firestore/cloud_firestore.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class RoomsModel {
  final String? roomId;
  final String? authorId;
  final DateTime? createdAt;
  final String? receiverId;
  final String? receiverName;
  final String? receiverImage;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final List<String>? users;
  RoomsModel({
    this.roomId,
    this.authorId,
    this.createdAt,
    this.receiverId,
    this.receiverName,
    this.receiverImage,
    this.lastMessage,
    this.lastMessageAt,
    this.users,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'roomId': roomId,
      'authorId': authorId,
      'createdAt': createdAt,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverImage': receiverImage,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt,
      'users': users,
    };
  }

  factory RoomsModel.fromJson(Map<String, dynamic> json) {
    return RoomsModel(
      roomId: json['roomId'] as String?,
      authorId: json['authorId'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      receiverId: json['receiverId'] as String?,
      receiverName: json['receiverName'] as String?,
      receiverImage: json['receiverImage'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: (json['lastMessageAt'] as Timestamp).toDate(),
      users: (json['users'] as List<dynamic>?)?.cast<String>(),
    );
  }
}
