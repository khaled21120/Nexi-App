import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final String? photoUrl;
  final String? fcmToken;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final bool? isOnline;

  UserModel({
    this.fcmToken,
    this.lastSeen,
    this.createdAt,
    this.isOnline,
    this.photoUrl,
    this.id,
    this.name,
    this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? lastSeen;
    DateTime? createdAt;

    if (json['lastSeen'] != null) {
      if (json['lastSeen'] is Timestamp) {
        lastSeen = (json['lastSeen'] as Timestamp).toDate();
      } else if (json['lastSeen'] is String) {
        lastSeen = DateTime.tryParse(json['lastSeen']);
      }
    }
    if (json['createdAt'] != null) {
      if (json['createdAt'] is Timestamp) {
        createdAt = (json['createdAt'] as Timestamp).toDate();
      } else if (json['createdAt'] is String) {
        createdAt = DateTime.tryParse(json['createdAt']);
      }
    }
    
    return UserModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      fcmToken: json['fcmToken'] as String?,
      lastSeen: lastSeen,
      createdAt: createdAt,
      isOnline: json['isOnline'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'isOnline': isOnline,
    };
  }
}