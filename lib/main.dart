import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:music/music_file_page.dart';
import 'package:music/player_detail_page.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  MediaKit.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    // 设置窗口默认属性
    WindowOptions windowOptions = WindowOptions(fullScreen: true);

    // 应用窗口属性
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // 显示窗口
      await windowManager.show();
      // 聚焦窗口
      await windowManager.focus();
    });
  }
  runApp(MusicApp());
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [GlobalNavObserver()],
      initialRoute: '/',
      routes: {
        '/': (context) => MusicFilePage(),
        '/playerDetail': (context) => PlayerDetailPage(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

class GlobalNavObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // 每次进入新页面时隐藏状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // 返回上一页面时隐藏状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }
}
