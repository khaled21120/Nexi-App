import 'package:flutter/material.dart';
import 'package:nexi/core/constants/app_constants.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_uikit/zego_uikit.dart';

class ZegoService {
  static Future<void> initialize({
    required String userID,
    required String userName,
  }) async {
    await ZegoUIKit().initLog().then((value) async {
      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: AppConstants.appId,
        appSign: AppConstants.appSign,
        userID: userID,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],
        uiConfig: ZegoCallInvitationUIConfig(
          inviter: ZegoCallInvitationInviterUIConfig(
            backgroundBuilder:
                (BuildContext context, Size size, ZegoCallingBuilderInfo info) {
                  return Container();
                },
          ),
          invitee: ZegoCallInvitationInviteeUIConfig(
            backgroundBuilder:
                (BuildContext context, Size size, ZegoCallingBuilderInfo info) {
                  return Container(
                    width: size.width,
                    height: size.height,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.5),
                    ),
                  );
                },
          ),
        ),
      );
    });
  }

  static void updateUser(String userID, String userName) async {
    await ZegoUIKitPrebuiltCallInvitationService().uninit();
    await initialize(userID: userID, userName: userName);
  }

  static void dispose() => ZegoUIKitPrebuiltCallInvitationService().uninit();
}
