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
  String? _currentFile;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  Duration? _draggingPosition; // 用于记录拖动中的位置

  @override
  void initState() {
    _player = Player();
    _player.stream.position.listen((position) {
      setState(() => _currentPosition = position);
    });
    _player.stream.duration.listen((duration) {
      setState(() => _totalDuration = duration);
    });
    _player.stream.playing.listen((playing) {
      setState(() => _isPlaying = playing);
    });
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
    setState(() => _currentFile = filePath);
    await _player.open(Media(filePath));
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _seekAudio(Duration position) {
    _player.seek(position);
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
      body: Stack(
        children: [
          Expanded(
            child: Builder(
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
          ),
          if (_currentFile != null)
            BottomSheet(
              onClosing: () {},
              builder: (context) {
                final title = _currentFile?.split('/').last ?? '未知音乐';
                final albumArtPlaceholder = Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey,
                  child: Icon(Icons.music_note, size: 30, color: Colors.white),
                );
                return Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          albumArtPlaceholder,
                          SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  '歌手 - 专辑名',
                                  style: TextStyle(color: Colors.grey, fontSize: 12.0),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                            onPressed: _togglePlayPause,
                          ),
                        ],
                      ),
                      Slider(
                        value: _draggingPosition?.inSeconds.toDouble() ?? _currentPosition.inSeconds.toDouble(),
                        max: _totalDuration.inSeconds.toDouble(),
                        onChangeStart: (value) {
                          // 开始拖动时记录拖动状态
                          _draggingPosition = Duration(seconds: value.toInt());
                          _player.pause();
                        },
                        onChanged: (value) {
                          // 拖动中仅更新 UI 显示，不触发播放器操作
                          setState(() {
                            _draggingPosition = Duration(seconds: value.toInt());
                          });
                        },
                        onChangeEnd: (value) {
                          // 拖动结束时更新播放器的实际进度
                          _seekAudio(Duration(seconds: value.toInt()));
                          setState(() {
                            _draggingPosition = null; // 结束拖动状态
                          });
                          _player.play();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
