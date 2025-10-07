import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../features/auth/data/models/user_model.dart';
import '../../features/groups/data/models/group_model.dart';
import '../../features/chat/data/models/message_model.dart';
import '../../features/chat/data/models/rooms_model.dart';
import '../constants/app_constants.dart';
import '../errors/error.dart';
import '../utils/helper.dart';
import 'notifications_helper.dart';

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  Future<void> addUserData({
    required String uid,
    required String name,
    required String email,
    required String photoUrl,
  }) async {
    try {
      await _firestore.collection(AppConstants.users).doc(uid).set({
        'id': uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': photoUrl,
      });
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<Map<String, dynamic>> fetchUserData({
    required String collection,
    required String docId,
  }) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc.data()!;
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<bool> isUserExist({
    required String collection,
    required String docId,
  }) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc.exists;
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> updateUserData({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> deleteUserData({
    required String collection,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
      await _firestore
          .collection('rooms')
          .where('users', arrayContains: docId)
          .get()
          .then(
            (value) =>
                // ignore: avoid_function_literals_in_foreach_calls
                value.docs.forEach((element) => element.reference.delete()),
          );
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> updateUserPhotoUrl({
    required String collection,
    required String docId,
    required String photoUrl,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).update({
        'photoUrl': photoUrl,
      });
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Stream<List<UserModel>> streamAllUsers() {
    try {
      return _firestore.collection('users').snapshots().map((snapshot) {
        return snapshot.docs
            .where((user) => user.id != _auth.currentUser!.uid)
            .map((doc) => UserModel.fromJson(doc.data()))
            .toList();
      });
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Stream<List<RoomsModel>> streamAllRooms() {
    try {
      return _firestore.collection('rooms').snapshots().asyncMap((
        snapshot,
      ) async {
        final currentUserId = _auth.currentUser!.uid;

        final futures = snapshot.docs.map((doc) async {
          final users = List<String>.from(doc['users'] ?? []);
          if (!users.contains(currentUserId)) return null;

          final receiverId = users.firstWhere((id) => id != currentUserId);

          final receiverDoc = await _firestore
              .collection('users')
              .doc(receiverId)
              .get();
          final receiverData = receiverDoc.data() ?? {};

          return RoomsModel.fromJson({
            'roomId': doc.id,
            'receiverId': receiverId,
            'receiverName': receiverData['name'],
            'receiverImage': receiverData['photoUrl'],
            ...doc.data(),
          });
        });

        // Run lookups in parallel & filter nulls
        final rooms = await Future.wait(futures);
        return rooms.whereType<RoomsModel>().toList();
      });
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> deleteChat(String roomId) async {
    try {
      final roomRef = _firestore.collection('rooms').doc(roomId);
      final messagesRef = roomRef.collection('messages');

      final messagesSnapshot = await messagesRef.get();
      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      await roomRef.delete();
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<String> _uploadFile({
    required String collectionName,
    required File file,
    required String roomId,
    required String fileName,
  }) async {
    try {
      final storageRef = _storage
          .ref('${collectionName}_media')
          .child(roomId)
          .child(fileName);

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: Helper.getMimeType(file.path),
          customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
        ),
      );

      final taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<String> uploadImage({
    required String folderName,
    required File file,
    required String fileName,
  }) async {
    try {
      final storageRef = _storage
          .ref(folderName)
          .child(_auth.currentUser!.uid)
          .child(fileName);

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: Helper.getMimeType(file.path),
          customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
        ),
      );

      final taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> _updateLastMessage(
    String collectionName,
    String docId,
    String lastMessage,
    FieldValue timestamp,
  ) async {
    try {
      await _firestore.collection(collectionName).doc(docId).update({
        'lastMessage': lastMessage,
        'lastMessageAt': timestamp,
      });
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<String> createOrGetRoom({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      final roomId = Helper.getRoomId(senderId, receiverId);
      final roomRef = _firestore.collection('rooms').doc(roomId);

      final doc = await roomRef.get();
      if (!doc.exists) {
        await roomRef.set({
          'users': [senderId, receiverId],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return roomId;
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> sendMessage({
    required String collectionName,
    required String userId,
    required String docId,
    required dynamic content,
  }) async {
    try {
      if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');
      if (docId.isEmpty) throw ArgumentError('Document ID cannot be empty');

      final messageRef = _firestore
          .collection(collectionName)
          .doc(docId)
          .collection('messages')
          .doc();

      final currentUser = await fetchUserData(
        collection: 'users',
        docId: userId,
      );

      final messageBody = content is String
          ? content
          : content is Map<String, dynamic> && content['type'] == 'file'
          ? '📎 ${content['fileName']}'
          : content is File
          ? '📷 Image'
          : '🎵 Audio(${Helper.formatDuration(content['audioDuration'])})';

      final senderName = currentUser['name'] ?? 'Someone';

      _sendNotificationsAsync(
        collectionName: collectionName,
        docId: docId,
        userId: userId,
        senderName: senderName,
        messageBody: messageBody,
      );

      // Save message to Firestore
      final timestamp = FieldValue.serverTimestamp();
      Map<String, dynamic> messageData = {
        'id': messageRef.id,
        'authorId': userId,
        'authorName': senderName,
        'authorImage': currentUser['photoUrl'] ?? '',
        'createdAt': timestamp,
        'status': 'sent',
      };

      if (content is File) {
        await _handleImageMessage(
          content,
          docId,
          messageRef,
          messageData,
          collectionName,
          timestamp,
        );
      } else if (content is Map<String, dynamic> && content['file'] != null) {
        await _handleFileMessage(
          content,
          docId,
          messageRef,
          messageData,
          collectionName,
          timestamp,
        );
      } else if (content is String) {
        await _handleTextMessage(
          content,
          messageRef,
          messageData,
          collectionName,
          docId,
          timestamp,
        );
      } else {
        throw ArgumentError('Unsupported content type: ${content.runtimeType}');
      }
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  void _sendNotificationsAsync({
    required String collectionName,
    required String docId,
    required String userId,
    required String senderName,
    required String messageBody,
  }) async {
    try {
      if (collectionName == AppConstants.rooms) {
        await _sendOneToOneNotification(docId, userId, senderName, messageBody);
      } else if (collectionName == AppConstants.groups) {
        await _sendGroupNotification(docId, userId, senderName, messageBody);
      }
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> _sendOneToOneNotification(
    String roomId,
    String userId,
    String senderName,
    String messageBody,
  ) async {
    try {
      final receiverId = roomId.replaceAll(userId, '').replaceAll('_', '');

      if (receiverId.isEmpty) {
        return;
      }

      final receiverData = await fetchUserData(
        collection: 'users',
        docId: receiverId,
      );

      final receiverToken = receiverData['fcmToken'] as String?;

      if (receiverToken != null && receiverToken.isNotEmpty) {
        await NotificationService.sendNotification(
          deviceToken: receiverToken,
          senderName: senderName,
          message: messageBody,
          roomId: roomId,
          isGroup: false,
        );
      } else {
        log('❌ FCM token not found for user: $receiverId');
      }
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> _sendGroupNotification(
    String groupId,
    String userId,
    String senderName,
    String messageBody,
  ) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();

      if (!groupDoc.exists) {
        log('❌ Group not found: $groupId');
        return;
      }

      final members = List<String>.from(
        groupDoc['members'] ?? [],
      ).where((id) => id != userId).toList();

      if (members.isEmpty) return;

      final tokens = await _getMemberTokens(members);

      if (tokens.isNotEmpty) {
        await NotificationService.sendToMultiple(
          tokens: tokens,
          senderName: senderName,
          message: messageBody,
          groupId: groupId,
          groupName: groupDoc['name'] ?? 'Group',
        );
      }
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<List<String>> _getMemberTokens(List<String> memberIds) async {
    try {
      if (memberIds.isEmpty) return [];

      final List<String> allTokens = [];

      for (var i = 0; i < memberIds.length; i += 10) {
        final chunk = memberIds.sublist(
          i,
          i + 10 > memberIds.length ? memberIds.length : i + 10,
        );

        final usersSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        final chunkTokens = usersSnapshot.docs
            .map((doc) => doc['fcmToken'] as String?)
            .where((token) => token != null && token.isNotEmpty)
            .cast<String>()
            .toList();

        allTokens.addAll(chunkTokens);
      }

      return allTokens;
    } catch (e) {
      return [];
    }
  }

  Future<void> _handleImageMessage(
    File imageFile,
    String docId,
    DocumentReference messageRef,
    Map<String, dynamic> messageData,
    String collectionName,
    dynamic timestamp,
  ) async {
    // Validate image file
    if (!await imageFile.exists()) {
      throw Exception('Image file does not exist');
    }

    final fileSize = await imageFile.length();
    if (fileSize > 10 * 1024 * 1024) {
      // 10MB limit
      throw Exception('Image size exceeds 10MB limit');
    }

    final String fileExtension = imageFile.path.split('.').last.toLowerCase();
    final String fileName =
        'image_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    final downloadUrl = await _uploadFile(
      collectionName: collectionName,
      file: imageFile,
      roomId: docId,
      fileName: fileName,
    );

    messageData.addAll({
      'mediaUrl': downloadUrl,
      'type': 'image',
      'fileName': fileName,
      'mediaSize': fileSize,
      'mimeType': Helper.getMimeType(fileExtension),
    });

    await messageRef.set(messageData);
    await _updateLastMessage(collectionName, docId, '📷 Image', timestamp);
  }

  Future<void> _handleFileMessage(
    Map<String, dynamic> content,
    String docId,
    DocumentReference messageRef,
    Map<String, dynamic> messageData,
    String collectionName,
    dynamic timestamp,
  ) async {
    final file = content['file'] as File;
    final fileName =
        content['name'] ?? 'file_${DateTime.now().millisecondsSinceEpoch}';

    if (!await file.exists()) {
      throw Exception('File does not exist');
    }

    final fileSize = await file.length();
    if (fileSize > 25 * 1024 * 1024) {
      throw Exception('File size exceeds 25MB limit');
    }

    final fileExtension = file.path.split('.').last.toLowerCase();
    final fullFileName = '$fileName.$fileExtension';
    final String mimeType =
        content['mimeType'] ?? Helper.getMimeType(fileExtension);

    final downloadUrl = await _uploadFile(
      collectionName: collectionName,
      file: file,
      roomId: docId,
      fileName: fullFileName,
    );
    if (mimeType == 'm4a' || mimeType == 'audio/webm') {
      messageData.addAll({
        'mediaUrl': downloadUrl,
        'type': content['type'],
        'fileName': content['name'],
        'mediaSize': fileSize,
        'audioDuration': content['audioDuration'],
        'mimeType': mimeType,
      });
      await messageRef.set(messageData);
      await _updateLastMessage(
        collectionName,
        docId,
        '🎵 Audio(${Helper.formatDuration(content['audioDuration'])})',
        timestamp,
      );
      return;
    }
    messageData.addAll({
      'fileUrl': downloadUrl,
      'type': 'file',
      'fileName': fullFileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
    });

    await messageRef.set(messageData);
    await _updateLastMessage(collectionName, docId, '📎$fileName', timestamp);
  }

  Future<void> _handleTextMessage(
    String textContent,
    DocumentReference messageRef,
    Map<String, dynamic> messageData,
    String collectionName,
    String docId,
    dynamic timestamp,
  ) async {
    // Validate text content
    if (textContent.trim().isEmpty) {
      throw Exception('Message text cannot be empty');
    }

    messageData.addAll({'text': textContent, 'type': 'text'});

    await messageRef.set(messageData);

    // Truncate long messages for last message preview
    final truncatedMessage = textContent.length > 50
        ? '${textContent.substring(0, 50)}...'
        : textContent;

    await _updateLastMessage(
      collectionName,
      docId,
      truncatedMessage,
      timestamp,
    );
  }

  Stream<List<MessageModel>> messagesStream(
    String collectionName,
    String docId,
  ) {
    try {
      return _firestore
          .collection(collectionName)
          .doc(docId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => MessageModel.fromJson(doc.data()))
                .toList(),
          );
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      final roomRef = _firestore.collection('rooms').doc(roomId);
      final messagesRef = roomRef.collection('messages');

      final messagesSnapshot = await messagesRef.get();
      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      await roomRef.delete();
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> deleteMessage({
    required String collectionName,
    required String roomId,
    required String messageId,
  }) async {
    try {
      final messageRef = _firestore
          .collection(collectionName)
          .doc(roomId)
          .collection('messages')
          .doc(messageId);

      await messageRef.delete();
      await _updateLastMessage(
        collectionName,
        roomId,
        'Message deleted',
        FieldValue.serverTimestamp(),
      );
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> updateMessage({
    required String collectionName,
    required String roomId,
    required String messageId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final messageRef = _firestore
          .collection(collectionName)
          .doc(roomId)
          .collection('messages')
          .doc(messageId);

      await messageRef.update(data);
      await _updateLastMessage(
        collectionName,
        roomId,
        'Message updated',
        FieldValue.serverTimestamp(),
      );
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<GroupModel> createOrUpdateGroup({required GroupModel group}) async {
    try {
      final groupRef = group.id != null
          ? _firestore.collection('groups').doc(group.id)
          : _firestore.collection('groups').doc();

      final data = {
        'id': groupRef.id,
        'name': group.name,
        'description': group.description,
        'adminId': group.adminId,
        'members': group.members,
        'groupImage': group.groupImage ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final doc = await groupRef.get();
      if (doc.exists) {
        await groupRef.update(data);
        _updateLastMessage(
          AppConstants.groups,
          groupRef.id,
          'Group updated',
          FieldValue.serverTimestamp(),
        );
      } else {
        await groupRef.set(data);
        _updateLastMessage(
          AppConstants.groups,
          groupRef.id,
          'Group created',
          FieldValue.serverTimestamp(),
        );
      }

      return GroupModel.fromJson({'id': groupRef.id, ...data});
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Stream<List<GroupModel>> streamAllGroups() {
    try {
      return _firestore
          .collection('groups')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .where(
                  (group) =>
                      (group['members'].contains(_auth.currentUser!.uid)),
                )
                .map(
                  (doc) => GroupModel.fromJson({'id': doc.id, ...doc.data()}),
                )
                .toList();
          });
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      final groupRef = _firestore.collection('groups').doc(groupId);
      await groupRef.delete();
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw ServerFailure('User with ID $userId does not exist.');
      }
      final userName = userDoc.data()!['name'] ?? 'A member';
      final groupRef = _firestore.collection('groups').doc(groupId);
      final doc = await groupRef.get();
      if (doc.exists) {
        final members = List<String>.from(doc['members'] ?? []);
        members.remove(userId);
        await groupRef.update({'members': members});
      }
      await _updateLastMessage(
        AppConstants.groups,
        groupId,
        '$userName left the group',
        FieldValue.serverTimestamp(),
      );
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> removeMemberFromGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw ServerFailure('User with ID $userId does not exist.');
      }
      final userName = userDoc.data()!['name'] ?? 'A member';

      final groupRef = _firestore.collection('groups').doc(groupId);
      final doc = await groupRef.get();
      if (doc.exists) {
        final members = List<String>.from(doc['members'] ?? []);
        members.remove(userId);
        await groupRef.update({'members': members});
      }
      await _updateLastMessage(
        AppConstants.groups,
        groupId,
        '$userName removed from the group',
        FieldValue.serverTimestamp(),
      );
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> addMembersToGroup({
    required String groupId,
    required List<String> newMembers,
  }) async {
    try {
      final groupRef = _firestore.collection('groups').doc(groupId);
      final doc = await groupRef.get();
      if (doc.exists) {
        final members = List<String>.from(doc['members'] ?? []);
        for (var member in newMembers) {
          if (!members.contains(member)) {
            members.add(member);
          } else {
            throw ServerFailure(
              'User $member is already a member of the group.',
            );
          }
        }
        await groupRef.update({'members': members});

        await _updateLastMessage(
          AppConstants.groups,
          groupId,
          'New members added to the group',
          FieldValue.serverTimestamp(),
        );
      }
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<Stream<List<UserModel>>> streamGroupMembers({
    required String groupId,
  }) async {
    try {
      final groupRef = _firestore.collection('groups').doc(groupId);
      final doc = await groupRef.get();
      if (doc.exists) {
        final currentMembers = List<String>.from(doc['members'] ?? []);

        final usersSnapshot = await _firestore
            .collection('users')
            .where('id', whereIn: currentMembers)
            .get();
        final users = usersSnapshot.docs
            .map((doc) => UserModel.fromJson(doc.data()))
            .toList();
        return Stream.value(users);
      } else {
        throw ServerFailure('Group with ID $groupId does not exist.');
      }
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> markChatMessagesAsRead({
    required String roomId,
    required String userId,
  }) async {
    try {
      final messagesQuery = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .where('authorId', isNotEqualTo: userId)
          .get();

      final batch = _firestore.batch();

      for (final doc in messagesQuery.docs) {
        final data = doc.data();

        if (data['status'] == 'sent' || data['status'] == 'delivered') {
          final messageRef = _firestore
              .collection('rooms')
              .doc(roomId)
              .collection('messages')
              .doc(doc.id);

          batch.update(messageRef, {'status': 'read'});
        }
      }

      await batch.commit();
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> markGroupMessagesAsRead({
    required String groupId,
    required String userId,
  }) async {
    try {
      final messagesQuery = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .where('authorId', isNotEqualTo: userId)
          .get();

      final batch = _firestore.batch();

      for (final doc in messagesQuery.docs) {
        final data = doc.data();

        if (data['status'] == 'sent' || data['status'] == 'delivered') {
          final messageRef = _firestore
              .collection('groups')
              .doc(groupId)
              .collection('messages')
              .doc(doc.id);

          batch.update(messageRef, {'status': 'read'});
        }
      }

      await batch.commit();
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Future<void> updateOnlineStatus({
    required String userId,
    required bool isOnline,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }

  Stream<UserModel> fetchUserStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromJson(doc.data()!..['id'] = doc.id));
  }

  Future<void> updateGroupPicture({
    required String groupId,
    required File picture,
  }) async {
    try {
      final fileName = 'group_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final pictureUrl = await _uploadFile(
        collectionName: 'groups',
        file: picture,
        roomId: groupId,
        fileName: fileName,
      );
      final groupRef = _firestore.collection('groups').doc(groupId);
      final doc = await groupRef.get();
      if (doc.exists) {
        await groupRef.update({'groupImage': pictureUrl});
      } else {
        throw ServerFailure('Group with ID $groupId does not exist.');
      }
    } catch (e) {
      throw ServerFailure.fromException(e);
    }
  }
}
