import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../features/auth/data/models/user_model.dart';
import '../constants/app_constants.dart';
import '../services/prefs_service.dart';

abstract class Helper {
  static void showSnackBarMessage(context, String message, bool isError) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        showCloseIcon: true,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  static UserModel? getUserDataLocally() {
    final userData = PrefsService.getString(AppConstants.users);
    if (userData == null) return null;
    return UserModel.fromJson(jsonDecode(userData));
  }

  static Future<File?> pickImage({required bool isCamera}) async {
    try {
      final image = await ImagePicker().pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      return null;
    }
  }

  static String? getMimeType(String extension) {
    final mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'zip': 'application/zip',
      'mp3': 'audio/mpeg',
      'mp4': 'video/mp4',
      'txt': 'text/plain',
    };

    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  static String getRoomId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  static String formatDuration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    final days = hours ~/ 24;

    if (days > 0) {
      return '${days}d: ${hours % 24}h';
    } else if (hours > 0) {
      return '${hours}h: ${minutes % 60}m';
    } else if (minutes > 0) {
      return '${minutes}m: ${seconds % 60}s';
    } else if (seconds > 0) {
      return '${seconds}s';
    } else {
      return '${milliseconds}ms';
    }
  }

  static Future<void> fileLaunch(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp.pdf');
      await file.writeAsBytes(bytes, flush: true);

      await OpenFilex.open(file.path);
    } catch (e) {
      throw 'Error opening PDF: $e';
    }
  }
}
