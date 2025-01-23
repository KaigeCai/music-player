import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:music/music_file_page.dart';
import 'package:music/player_detail_page.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
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
