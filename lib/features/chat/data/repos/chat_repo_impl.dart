import 'package:dartz/dartz.dart';

import 'package:nexi/core/errors/error.dart';

import 'package:nexi/features/auth/data/models/user_model.dart';

import 'package:nexi/features/chat/data/models/message_model.dart';

import 'package:nexi/features/chat/data/models/rooms_model.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firestore_service.dart';
import 'chat_repo.dart';

class ChatRepoImpl implements ChatRepo {
  final FirestoreService firestore;
  ChatRepoImpl(this.firestore);
  @override
  Future<Either<Failure, void>> deleteMessage({
    required String collectionName,
    required String roomId,
    required String messageId,
  }) async {
    try {
      await firestore.deleteMessage(
        collectionName: collectionName,
        roomId: roomId,
        messageId: messageId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> markChatMessagesAsRead({
    required String roomId,
    required String userId,
  }) async {
    try {
      await firestore.markChatMessagesAsRead(roomId: roomId, userId: userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Stream<List<RoomsModel>>>> getAllRooms() async {
    try {
      final data = firestore.streamAllRooms();
      return Right(data);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, UserModel>> getUserData(String userId) async {
    try {
      final data = await firestore.fetchUserData(
        collection: AppConstants.users,
        docId: userId,
      );
      return Right(UserModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Stream<List<MessageModel>>>> messagesStream(
    String collectionName,
    String docId,
  ) async {
    try {
      final stream = firestore.messagesStream(collectionName, docId);
      return Right(stream);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateOnlineStatus(
    String userId,
    bool isOnline,
  ) async {
    try {
      await firestore.updateOnlineStatus(userId: userId, isOnline: isOnline);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessageToChat({
    required String senderUID,
    required String reciverUID,
    required dynamic content,
  }) async {
    try {
      final roomID = await firestore.createOrGetRoom(
        senderId: senderUID,
        receiverId: reciverUID,
      );
      await firestore.sendMessage(
        collectionName: AppConstants.rooms,
        userId: senderUID,
        docId: roomID,
        content: content,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateMessage({
    required String collectionName,
    required String roomId,
    required String messageId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await firestore.updateMessage(
        collectionName: collectionName,
        roomId: roomId,
        messageId: messageId,
        data: data,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteChat(String roomId) async {
    try {
      await firestore.deleteChat(roomId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.fromException(e));
    }
  }
}
