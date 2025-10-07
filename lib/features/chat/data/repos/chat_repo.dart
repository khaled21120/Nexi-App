import 'package:dartz/dartz.dart';
import '../../../../core/errors/error.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/message_model.dart';
import '../models/rooms_model.dart';

abstract class ChatRepo {
  Future<Either<Failure, UserModel>> getUserData(String userId);

  Future<Either<Failure, Stream<List<RoomsModel>>>> getAllRooms();

  Future<Either<Failure, Stream<List<MessageModel>>>> messagesStream(
    String collectionName,
    String docId,
  );

  Future<Either<Failure, void>> sendMessageToChat({
    required String senderUID,
    required String reciverUID,
    required dynamic content,
  });

  Future<Either<Failure, void>> markChatMessagesAsRead({
    required String roomId,
    required String userId,
  });

  Future<Either<Failure, void>> deleteMessage({
    required String collectionName,
    required String roomId,
    required String messageId,
  });

  Future<Either<Failure, void>> updateMessage({
    required String collectionName,
    required String roomId,
    required String messageId,
    required Map<String, dynamic> data,
  });
  Future<Either<Failure, void>> updateOnlineStatus(String userId, bool isOnline);

  Future<Either<Failure, void>> deleteChat(String roomId);
}
