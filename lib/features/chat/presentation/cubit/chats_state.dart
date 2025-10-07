part of 'chats_cubit.dart';

@immutable
sealed class ChatsState {}

final class ChatsInitial extends ChatsState {}

final class ChatsLoaded extends ChatsState {
  final List<RoomsModel> users;

  ChatsLoaded(this.users);
}

final class ChatsError extends ChatsState {
  final String message;

  ChatsError(this.message);
}

final class ChatsLoading extends ChatsState {}

class ChatsMessagesStream extends ChatsState {
  final Stream<List<MessageModel>> messages;
  ChatsMessagesStream(this.messages);
}

