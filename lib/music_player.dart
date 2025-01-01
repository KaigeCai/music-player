import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicPlayer extends StatefulWidget {
  const MusicPlayer({super.key});

  @override
  State<MusicPlayer> createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  late final Player _player;
  List<String> _audioFiles = [];
  bool _isScanning = false;

  @override
  void initState() {
    _player = Player();
    _loadLastDirectory();
    super.initState();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// 加载上次使用的文件夹路径
  Future<void> _loadLastDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = prefs.getString('last_directory');
    if (directory != null && Directory(directory).existsSync()) {
      _scanAudioFiles(directory);
    }
  }

  /// 保存文件夹路径到本地
  Future<void> _saveLastDirectory(String directory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_directory', directory);
  }

  /// 检查权限并扫描文件夹
  Future<void> _checkAndScanFolder() async {
    await Permission.manageExternalStorage.request();
    await Permission.storage.request();
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory != null) {
      setState(() => _isScanning = true);
      await _saveLastDirectory(directory);
      _scanAudioFiles(directory);
    }
  }

  /// 扫描音频文件
  Future<void> _scanAudioFiles(String directory) async {
    final dir = Directory(directory);
    final files = dir.listSync(recursive: true, followLinks: false);
    final audioExtensions = ['.mp3', '.wav', '.flac', '.aac'];

    List<String> audioFiles = [];
    for (var file in files) {
      if (file is File && audioExtensions.any(file.path.endsWith)) {
        audioFiles.add(file.path);
      }
    }

    setState(() {
      _audioFiles = audioFiles;
      _isScanning = false;
    });
  }

  /// 播放音频文件
  Future<void> _playAudio(String filePath) async {
    await _player.open(Media(filePath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('本地音乐播放器'),
        actions: [
          IconButton(
            icon: Icon(Icons.folder),
            onPressed: _checkAndScanFolder,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_isScanning) {
            return Center(child: CircularProgressIndicator());
          }

          if (_audioFiles.isEmpty) {
            return Center(child: Text('未找到音频文件，请选择一个文件夹。'));
          }

          return OrientationBuilder(
            builder: (context, orientation) {
              final crossAxisCount = orientation == Orientation.portrait ? 3 : 6;
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: _audioFiles.length,
                itemBuilder: (context, index) {
                  final file = _audioFiles[index];
                  return GestureDetector(
                    
                    onTap: () => _playAudio(file),
                    child: GridTile(
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        color: Colors.blueAccent.withValues(alpha: 0.1), 
                        child: Center(
                          child: Text(
                            file.split('/').last,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.0),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
