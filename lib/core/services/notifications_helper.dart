import 'dart:convert';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class NotificationService {
  static Future<String?> _getAccessToken() async {
    try {
      final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
      final clientEmail = dotenv.env['FIREBASE_CLIENT_EMAIL'];
      final privateKey = dotenv.env['FIREBASE_PRIVATE_KEY']?.replaceAll(
        r'\n',
        '\n',
      );

      if (projectId == null || clientEmail == null || privateKey == null) {
        log('❌ Missing FCM environment variables');
        return null;
      }

      final serviceAccountJson = {
        "type": "service_account",
        "project_id": projectId,
        "private_key_id": "715c4a7ce4da3db064d4bd9730473f54d419519e",
        "private_key": privateKey,
        "client_email": clientEmail,
        "client_id": "112756705421339244859",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/fcm-489%40chat-b6488.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com",
      };

      final scopes = ["https://www.googleapis.com/auth/firebase.messaging"];

      final client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
      );

      final credentials = await auth.obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
        client,
      );

      client.close();
      return credentials.accessToken.data;
    } catch (e) {
      log('❌ Error getting access token: $e');
      return null;
    }
  }

  static Future<bool> sendNotification({
    required String deviceToken,
    required String senderName,
    required String message,
    required String roomId,
    bool isGroup = false,
  }) async {
    try {
      if (deviceToken.isEmpty) {
        log('❌ Device token is empty');
        return false;
      }

      final accessToken = await _getAccessToken();
      if (accessToken == null) return false;

      final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
      if (projectId == null) return false;

      final endpoint =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final title = isGroup
          ? '💬 $senderName in ${dotenv.env['APP_NAME'] ?? "Chat"}'
          : '💬 $senderName';

      final notificationData = {
        "message": {
          "token": deviceToken,
          "notification": {"title": title, "body": _truncateMessage(message)},
          "data": {
            "type": "chat_message",
            "room_id": roomId,
            "sender_name": senderName,
            "is_group": isGroup.toString(),
            "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
          },
          "android": {
            "priority": "high",
            "notification": {"channel_id": "chat_messages", "sound": "default"},
          },
          "apns": {
            "payload": {
              "aps": {"sound": "default", "badge": 1},
            },
          },
        },
      };

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(notificationData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        log('✅ Notification sent to $senderName');
        return true;
      } else {
        log('❌ FCM error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      log('🚨 Notification error: $e');
      return false;
    }
  }

  static Future<void> sendToMultiple({
    required List<String> tokens,
    required String senderName,
    required String message,
    required String groupId,
    required String groupName,
  }) async {
    if (tokens.isEmpty) return;

    final accessToken = await _getAccessToken();
    if (accessToken == null) return;

    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    if (projectId == null) return;

    final endpoint =
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

    // Send to each token with delay to avoid rate limiting
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      // Add small delay between sends (except first one)
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      try {
        final notificationData = {
          "message": {
            "token": token,
            "notification": {
              "title": "💬 $senderName in $groupName",
              "body": _truncateMessage(message),
            },
            "data": {
              "type": "group_message",
              "group_id": groupId,
              "sender_name": senderName,
              "group_name": groupName,
              "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
              "click_action": "FLUTTER_NOTIFICATION_CLICK",
            },
          },
        };

        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
              body: jsonEncode(notificationData),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          log('✅ Group notification sent ($i/${tokens.length})');
        } else {
          log(
            '❌ Group notification failed for token $i: ${response.statusCode}',
          );
        }
      } catch (e) {
        log('🚨 Error sending to token $i: $e');
      }
    }
  }

  static String _truncateMessage(String message) {
    return message.length > 100 ? '${message.substring(0, 100)}...' : message;
  }
}
