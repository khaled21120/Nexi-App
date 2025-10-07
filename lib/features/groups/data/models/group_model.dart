// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String? id;
  final String? name;
  final String? description;
  final String? adminId;
  final String? groupImage;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final List<String>? members;

  GroupModel({
     this.id,
     this.name,
      this.description,
     this.adminId,
     this.groupImage,
     this.lastMessage,
     this.lastMessageAt,
     this.members,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      adminId: json['adminId'] as String?,
      groupImage: json['groupImage'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: (json['lastMessageAt'] is Timestamp)
          ? (json['lastMessageAt'] as Timestamp).toDate()
          : (json['lastMessageAt'] is String)
          ? DateTime.parse(json['lastMessageAt'])
          : json['lastMessageAt'] ?? DateTime.now(),
      members: (json['members'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'adminId': adminId,
      'groupImage': groupImage,
      'members': members,
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? adminId,
    String? groupImage,
    String? lastMessage,
    DateTime? lastMessageAt,
    List<String>? members,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      adminId: adminId ?? this.adminId,
      groupImage: groupImage ?? this.groupImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      members: members ?? this.members,
    );
  }
}
