import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:music/music_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(MusicApp());
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MusicPlayer(),
    );
  }
}