import 'dart:io';

import 'package:audiotags/audiotags.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:music/player_detail_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicFilePage extends StatefulWidget {
  const MusicFilePage({super.key});

  @override
  State<MusicFilePage> createState() => _MusicFilePageState();
}

class _MusicFilePageState extends State<MusicFilePage> {
  late final Player _player;
  List<String> _audioFiles = [];
  bool _isScanning = false;
  String? _currentFile;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  Duration? _draggingPosition; // 用于记录拖动中的位置
  double _dragOffset = 0.0; // 拖动偏移量
  String songTitle = '';
  List<Tag?> _audioTags = []; // 缓存音频标签数据

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
    List<Tag?> audioTags = [];
    for (var file in files) {
      if (file is File && audioExtensions.any(file.path.endsWith)) {
        audioFiles.add(file.path);
        // 加载音频标签
        try {
          final tag = await AudioTags.read(file.path);
          audioTags.add(tag);
        } catch (e) {
          audioTags.add(null); // 如果加载失败，填充 null
        }
      }
    }
    setState(() {
      _audioFiles = audioFiles;
      _audioTags = audioTags;
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

  // 获取上一首歌曲
  String? _getPreviousSong() {
    final currentIndex = _audioFiles.indexOf(_currentFile ?? '');
    if (currentIndex > 0) {
      return _audioFiles[currentIndex - 1];
    }
    return null; // 如果是第一首，则返回 null
  }

  // 获取下一首歌曲
  String? _getNextSong() {
    final currentIndex = _audioFiles.indexOf(_currentFile ?? '');
    if (currentIndex < _audioFiles.length - 1) {
      return _audioFiles[currentIndex + 1];
    }
    return null; // 如果是最后一首，则返回 null
  }

  // 切换到上一首歌曲
  void _playPrevious() {
    final previous = _getPreviousSong();
    if (previous != null) {
      _playAudio(previous);
    }
  }

  // 切换到下一首歌曲
  void _playNext() {
    final next = _getNextSong();
    if (next != null) {
      _playAudio(next);
    }
  }

  // 构建歌曲显示组件
  Widget _buildSongTile({String? songPath}) {
    if (songPath == null) {
      return SizedBox.shrink(); // 如果没有歌曲，返回一个空组件
    }

    songTitle = _currentFile?.split('/').last ?? '未知音乐';
    final albumArtPlaceholder = ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: 50,
        height: 50,
        color: Colors.grey,
        child: Icon(Icons.music_note, size: 30, color: Colors.white),
      ),
    );

    return Container(
      padding: EdgeInsets.only(left: 22.0, right: 8.0),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 50.0,
            color: Colors.transparent,
          ),
          Row(
            children: [
              albumArtPlaceholder,
              SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      songTitle,
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              const itemWidth = 100.0;
              final crossAxisCount = (screenWidth / itemWidth).floor().clamp(1, 10);

              if (_isScanning) {
                return Center(child: CircularProgressIndicator());
              }

              if (_audioFiles.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('未找到音频文件，请扫描文件夹👇'),
                      SizedBox(height: 12.0),
                      FloatingActionButton(
                        onPressed: _checkAndScanFolder,
                        backgroundColor: Colors.white,
                        shape: CircleBorder(),
                        child: Icon(Icons.folder, color: Colors.black87),
                      ),
                    ],
                  ),
                );
              }
              return GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 3.0, vertical: 38.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 3 / 4,
                  crossAxisSpacing: 3.0,
                  mainAxisSpacing: 6.0,
                ),
                itemCount: _audioFiles.length,
                itemBuilder: (context, index) {
                  final file = _audioFiles[index];
                  final tag = _audioTags[index];
                  String title = tag?.title ?? '未知标题';
                  String artist = tag?.trackArtist ?? '未知艺术家';
                  String album = tag?.album ?? '未知专辑';

                  Widget cover;
                  if (tag?.pictures.isNotEmpty == true) {
                    cover = Image.memory(
                      tag!.pictures.first.bytes,
                      fit: BoxFit.cover,
                    );
                  } else {
                    cover = Container(
                      color: Colors.black12,
                      width: 100.0,
                      height: 100.0,
                      child: Icon(
                        Icons.music_note,
                        size: 100.0,
                      ),
                    ); // 使用默认图标
                  }
                  return GestureDetector(
                    onTap: () => _playAudio(file),
                    child: SingleChildScrollView(
                      physics: NeverScrollableScrollPhysics(), // 禁用滚动
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: cover, // 显示封面
                          ),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "$artist - $album",
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      bottomSheet: Builder(
        builder: (context) {
          final int totalSeconds = _totalDuration.inSeconds;
          final bool hasDuration = totalSeconds > 0;
          final double maxDuration = hasDuration ? totalSeconds.toDouble() : 1.0;

          final double? dragPos = _draggingPosition?.inSeconds.toDouble();
          final double currentPos = _currentPosition.inSeconds.toDouble();
          final double rawValue = dragPos ?? currentPos;

          final currentValue = rawValue.clamp(0.0, maxDuration);

          return Container(
            constraints: BoxConstraints(maxWidth: 400.0, maxHeight: 100.0),
            decoration: BoxDecoration(
              color: Colors.white, // 背景颜色
              borderRadius: BorderRadius.circular(22.0), // 圆角
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.13), // 阴影颜色和透明度
                  blurRadius: 3.0, // 模糊半径
                  spreadRadius: 3.0, // 扩散半径
                  offset: Offset(2, 2), // 阴影偏移
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerDetailPage(
                          songTitle: songTitle,
                          artistAlbum: '歌手 - 专辑名', // 替换为实际数据
                          coverImage: 'assets/placeholder.png', // 替换为实际封面路径
                          isPlaying: _isPlaying,
                          onPlayPauseToggle: _togglePlayPause,
                          onPrevious: _playPrevious,
                          onNext: _playNext,
                          currentPosition: _currentPosition,
                          totalDuration: _totalDuration,
                          onSeek: (position) => _seekAudio(position),
                        ),
                      ),
                    );
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragOffset += details.delta.dx; // 根据滑动距离调整当前偏移量
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    setState(() {
                      if (_dragOffset > MediaQuery.of(context).size.width / 3) {
                        // 偏移量大于屏幕宽度的1/3，切换到上一首
                        _playPrevious();
                      } else if (_dragOffset < -MediaQuery.of(context).size.width / 3) {
                        // 偏移量小于屏幕宽度的-1/3，切换到下一首
                        _playNext();
                      }
                      _dragOffset = 0.0; // 无论是否切换歌曲，重置偏移量
                    });
                  },
                  child: Stack(
                    children: [
                      // 显示上一首歌曲
                      Transform.translate(
                        offset: Offset(_dragOffset - MediaQuery.of(context).size.width, 0),
                        child: _buildSongTile(
                          songPath: _getPreviousSong(),
                        ),
                      ),
                      // 显示当前歌曲
                      Transform.translate(
                        offset: Offset(_dragOffset, 0),
                        child: _buildSongTile(
                          songPath: _currentFile,
                        ),
                      ),
                      // 显示下一首歌曲
                      Transform.translate(
                        offset: Offset(_dragOffset + MediaQuery.of(context).size.width, 0),
                        child: _buildSongTile(
                          songPath: _getNextSong(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 22.0,
                  child: Slider(
                    value: currentValue,
                    activeColor: Colors.blue,
                    max: maxDuration,
                    onChangeStart: (value) {
                      _draggingPosition = Duration(seconds: value.toInt());
                      _player.pause();
                    },
                    onChanged: (value) {
                      setState(() {
                        _draggingPosition = Duration(seconds: value.toInt());
                      });
                    },
                    onChangeEnd: (value) {
                      _seekAudio(Duration(seconds: value.toInt()));
                      setState(() {
                        _draggingPosition = null;
                      });
                      _player.play();
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
