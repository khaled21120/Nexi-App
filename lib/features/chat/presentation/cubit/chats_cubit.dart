import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:nexi/features/chat/data/repos/chat_repo.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/message_model.dart';
import '../../data/models/rooms_model.dart';

part 'chats_state.dart';

class ChatsCubit extends Cubit<ChatsState> {
  final ChatRepo chatRepo;
  StreamSubscription<List<RoomsModel>>? _rooomsSub;
  StreamSubscription<List<MessageModel>>? _messagesSub;

  ChatsCubit(this.chatRepo) : super(ChatsInitial());

  List<RoomsModel> rooms = [];
  List<MessageModel> messages = [];

  Future<void> getChats() async {
    emit(ChatsLoading());

    final result = await chatRepo.getAllRooms();
    result.fold((failure) => emit(ChatsError(failure.errMsg)), (usersStream) {
      _rooomsSub?.cancel();

      _rooomsSub = usersStream.listen(
        (usersList) {
          rooms = usersList;
          emit(ChatsLoaded(rooms));
        },
        onError: (error) {
          emit(ChatsError(error.toString()));
        },
      );
    });
  }
  Future<void> listenToChatsMessages(String roomId) async {
    emit(ChatsLoading());

    final result = await chatRepo.messagesStream(AppConstants.rooms, roomId);
    result.fold((failure) => emit(ChatsError(failure.errMsg)), (stream) {
      _messagesSub?.cancel();

      emit(ChatsMessagesStream(stream));
    });
  }

  Future<void> listenToGroupMessages(String groupId) async {
    emit(ChatsLoading());

    final result = await chatRepo.messagesStream(AppConstants.groups, groupId);
    result.fold((failure) => emit(ChatsError(failure.errMsg)), (stream) {
      _messagesSub?.cancel();

      emit(ChatsMessagesStream(stream));
    });
  }

  Future<void> sendMessageToChat({
    required String senderId,
    required String receiverId,
    required dynamic content,
  }) async {
    final result = await chatRepo.sendMessageToChat(
      senderUID: senderId,
      reciverUID: receiverId,
      content: content,
    );

    result.fold((failure) => emit(ChatsError(failure.errMsg)), (_) {});
  }

  Future<void> markChatMessagesAsRead({
    required String roomId,
    required String userId,
  }) async {
    final result = await chatRepo.markChatMessagesAsRead(
      roomId: roomId,
      userId: userId,
    );

    result.fold((failure) => emit(ChatsError(failure.errMsg)), (_) {});
  }

  Future<void> deleteMessage({
    required String collectionName,
    required String roomId,
    required String messageId,
  }) async {
    final result = await chatRepo.deleteMessage(
      collectionName: collectionName,
      roomId: roomId,
      messageId: messageId,
    );
    result.fold((failure) => emit(ChatsError(failure.errMsg)), (_) {});
  }

  Future<void> updateMessage({
    required String collectionName,
    required String roomId,
    required String messageId,
    required Map<String, dynamic> data,
  }) async {
    final result = await chatRepo.updateMessage(
      collectionName: collectionName,
      roomId: roomId,
      messageId: messageId,
      data: data,
    );
    result.fold((failure) => emit(ChatsError(failure.errMsg)), (_) {});
  }

  Future<void> deleteChat(String roomId) async {
    final result = await chatRepo.deleteChat(roomId);
    result.fold((failure) => emit(ChatsError(failure.errMsg)), (_) {});
  }

  @override
  Future<void> close() {
    _rooomsSub?.cancel();
    _messagesSub?.cancel();
    return super.close();
  }

  void updateOnlineStatus({required userId, required bool isOnline}) async {
    final result = await chatRepo.updateOnlineStatus(userId, isOnline);
    result.fold((failure) => emit(ChatsError(failure.errMsg)), (success) {
      // Optionally handle success if needed
    });
  }
}
