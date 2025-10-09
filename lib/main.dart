import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nexi/core/services/zego_service.dart';
import 'package:nexi/core/themes/theme.dart';
import 'package:nexi/core/utils/helper.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_uikit/zego_uikit.dart';

import 'core/services/get_it_service.dart';
import 'core/services/local_notifications_service.dart';
import 'core/services/prefs_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/utils/app_routers.dart';
import 'firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await ScreenUtil.ensureScreenSize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PrefsService.init();
  await dotenv.load(fileName: ".env");
  initGetItService();

  runApp(const NexiApp());

  _postInit();
}

Future<void> _postInit() async {
  await LocalNotificationService.init();

  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
  await ZegoUIKit().initLog();
  await ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI([
    ZegoUIKitSignalingPlugin(),
  ]);
  ZegoService.initialize(userID: 'User_Id', userName: 'userName');

  FlutterNativeSplash.remove();
}

class NexiApp extends StatelessWidget {
  const NexiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
