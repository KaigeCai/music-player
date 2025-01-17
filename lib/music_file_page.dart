import 'dart:io';

import 'package:audiotags/audiotags.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:music/player_detail_page.dart';
import 'package:music/song.dart';
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
  List<Tag?> _audioTags = []; // 缓存音频标签数据
  int? _currentFileIndex; // 当前点击的文件索引

  Song song = Song(
    coverImage: Uint8List(0),
    title: '',
    artist: '',
    album: '',
  );

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
  Widget _buildSongTile(Song song) {
    final albumArtPlaceholder = ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: 80,
        height: 80,
        color: Colors.grey,
        child: song.coverImage != null
            ? Image.memory(song.coverImage!)
            : Icon(
                Icons.music_note,
                size: 30,
                color: Colors.white,
              ),
      ),
    );

    return Container(
      margin: EdgeInsets.only(left: 6.0),
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
                      song.title!,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      '${song.artist} - ${song.album}',
                      style: TextStyle(color: Colors.grey, fontSize: 12.0),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
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
      body: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          const itemWidth = 100.0;
          final crossAxisCount = (screenWidth / itemWidth).floor().clamp(1, 10);

          bool isDesktop = !kIsWeb && MediaQuery.of(context).size.width > 600;

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
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: GridView.builder(
              padding: EdgeInsets.only(
                bottom: 220.0,
                left: 3.0,
                right: 4.0,
                top: isDesktop ? 0.0 : 38.0,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 3 / 4,
                crossAxisSpacing: 3.0,
                mainAxisSpacing: 6.0,
              ),
              itemCount: _audioFiles.length,
              itemBuilder: (context, index) {
                final file = _audioFiles[index];
                final Tag? tag = _audioTags[index];
                Widget cover;

                song.title = tag?.title ?? '未知标题';
                song.artist = tag?.trackArtist ?? '未知艺术家';
                song.album = tag?.album ?? '未知专辑';

                if (tag != null && tag.pictures.isNotEmpty) {
                  song.coverImage = tag.pictures.first.bytes;
                } else {
                  song.coverImage = null; // 如果没有封面图，设置为 null
                }

                if (song.coverImage != null) {
                  cover = AspectRatio(
                    aspectRatio: 1.0,
                    child: Image.memory(
                      song.coverImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          color: Colors.black12,
                          child: FittedBox(
                            fit: BoxFit.contain, // 图标根据容器自适应大小
                            child: Icon(
                              Icons.music_note,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  // 使用默认图标
                  cover = AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      color: Colors.black12,
                      child: FittedBox(
                        fit: BoxFit.contain, // 图标根据容器自适应大小
                        child: Icon(
                          Icons.music_note,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentFile = file; // 设置当前文件路径
                      _currentFileIndex = index; // 设置当前文件索引
                    });
                    _playAudio(file);
                  },
                  child: SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(), // 禁用滚动
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: cover, // 显示封面
                        ),
                        Text(
                          song.title!,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${song.artist} - ${song.album}",
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
            ),
          );
        },
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

          if (_currentFile == null || _currentFileIndex == null) {
            return SizedBox.shrink();
          }

          final Tag? tag = _audioTags[_currentFileIndex!]; // 根据当前索引获取对应标签
          final Song song = Song(
            title: tag?.title ?? '未知标题',
            artist: tag?.trackArtist ?? '未知艺术家',
            album: tag?.album ?? '未知专辑',
            coverImage: (tag?.pictures.isNotEmpty ?? false) ? tag!.pictures.first.bytes : null,
          );
          return Container(
            constraints: BoxConstraints(
              minWidth: 100.0,
              minHeight: 100.0,
              maxWidth: 400.0,
              maxHeight: 100.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white, // 背景颜色
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ), // 圆角
              boxShadow: [
                BoxShadow(
                  color: Colors.black12, // 阴影颜色和透明度
                  blurRadius: 1.0, // 模糊半径
                  spreadRadius: 1.0, // 扩散半径
                ),
              ],
            ),
            padding: EdgeInsets.only(top: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerDetailPage(
                          songTitle: song.title!,
                          artistAlbum: '${song.artist} - ${song.album}', // 替换为实际数据
                          coverImage: song.coverImage, // 替换为实际封面路径
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
                  child: // 显示当前歌曲
                      Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: _buildSongTile(song),
                  ),
                ),
                SizedBox(
                  height: 11.0,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5.0), // 调整滑块大小
                      trackHeight: 2.0, // 调整轨道高度
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 0.0),
                    ),
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
