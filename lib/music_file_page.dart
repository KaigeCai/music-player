import 'dart:async';
import 'dart:io';

import 'package:audiotags/audiotags.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:music/model/song.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'global/player_provider.dart';

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
  PageController? _pageController;
  bool _isPageControllerInitialized = false; // 是否已初始化
  bool _hasInitialScan = false;

  Song song = Song(
    coverImage: Uint8List(0),
    title: '',
    artist: '',
    album: '',
  );

  StreamSubscription<FileSystemEvent>? _directorySubscription;

  Future<void> _initializeFiles() async {
    if (_hasInitialScan) return; // 防止重复初始化扫描

    final prefs = await SharedPreferences.getInstance();
    final directory = prefs.getString('last_directory');

    if (directory != null && Directory(directory).existsSync()) {
      setState(() => _isScanning = true);
      await _scanAudioFiles(directory);
      _startWatchingDirectory(directory);
      _hasInitialScan = true;
      setState(() => _isScanning = false);
    }
  }

  // 实时监测文件变化
  void _startWatchingDirectory(String directoryPath) {
    final dir = Directory(directoryPath);
    _directorySubscription?.cancel(); // 避免重复监听

    _directorySubscription = dir.watch(events: FileSystemEvent.all).listen((event) async {
      final file = File(event.path);
      if (event is FileSystemCreateEvent) {
        if (await _isAudioFile(file)) {
          final tag = await _loadAudioTag(file.path);

          setState(() {
            _audioFiles.add(file.path);
            _audioTags.add(tag);
            _sortFilesByModifiedTime(); // 添加后重新排序
          });
        }
      } else if (event is FileSystemDeleteEvent) {
        setState(() {
          int index = _audioFiles.indexOf(file.path);
          if (index != -1) {
            _audioFiles.removeAt(index);
            _audioTags.removeAt(index);
          }
        });
      }
    });
  }

  void _sortFilesByModifiedTime() {
    List<Map<String, dynamic>> fileData = [];

    for (int i = 0; i < _audioFiles.length; i++) {
      final file = File(_audioFiles[i]);
      final modifiedTime = file.existsSync() ? file.lastModifiedSync() : DateTime(1970);
      fileData.add({'path': _audioFiles[i], 'modified': modifiedTime, 'tag': _audioTags[i]});
    }

    // 按修改时间降序排序
    fileData.sort((a, b) => b['modified'].compareTo(a['modified']));

    setState(() {
      _audioFiles = fileData.map((e) => e['path'] as String).toList();
      _audioTags = fileData.map((e) => e['tag'] as Tag?).toList();
    });
  }

  Future<bool> _isAudioFile(File file) async {
    const audioExtensions = ['.mp3', '.wav', '.flac', '.aac'];
    return audioExtensions.any(file.path.endsWith);
  }

  Future<Tag?> _loadAudioTag(String filePath) async {
    try {
      return await AudioTags.read(filePath);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    _currentFileIndex = _audioFiles.isNotEmpty ? 0 : null;
    if (!_isPageControllerInitialized) {
      _pageController = PageController(initialPage: 1);
      _isPageControllerInitialized = true;
    }
    Future.microtask(_initializeFiles);
    _player = Player();
    _player.stream.position.listen((position) {
      if (mounted) {
        context.read<PlayerProvider>().syncPlaybackState(
              isPlaying: _isPlaying,
              currentPosition: position,
              totalDuration: _totalDuration,
            );
        setState(() {
          _currentPosition = position; // 确保进度条更新
        });
      }
    });

    _player.stream.duration.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
        context.read<PlayerProvider>().syncPlaybackState(
              isPlaying: _isPlaying,
              currentPosition: duration,
              totalDuration: duration,
            );
      }
    });

    _player.stream.playing.listen((playing) {
      setState(() {
        _isPlaying = playing;
      });
      if (mounted) {
        context.read<PlayerProvider>().syncPlaybackState(
              isPlaying: playing,
              currentPosition: _currentPosition,
              totalDuration: _totalDuration,
            );
      }
    });
    _loadLastDirectory();
    super.initState();
  }

  @override
  void dispose() {
    _pageController!.dispose();
    _player.dispose();
    _directorySubscription?.cancel(); // 停止监听
    super.dispose();
  }

  // 加载上次使用的文件夹路径
  Future<void> _loadLastDirectory() async {
    if (_hasInitialScan) return; // 防止重复初始化扫描
    final prefs = await SharedPreferences.getInstance();
    final directory = prefs.getString('last_directory');
    if (directory != null && Directory(directory).existsSync()) {
      _scanAudioFiles(directory);
      _hasInitialScan = true;
    }
  }

  // 保存文件夹路径到本地
  Future<void> _saveLastDirectory(String directory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_directory', directory);
  }

  Future<void> _checkAndScanFolder() async {
    await Permission.manageExternalStorage.request();
    await Permission.storage.request();
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory != null) {
      setState(() {
        _isScanning = true;
      });
      await _saveLastDirectory(directory);
      _startWatchingDirectory(directory); // 开始监听文件夹变化
      setState(() {
        _isScanning = false;
      });
    }
  }

  // 扫描音频文件
  Future<void> _scanAudioFiles(String directory) async {
    final dir = Directory(directory);
    final files = dir.listSync(recursive: false, followLinks: false);
    final audioExtensions = ['.mp3', '.wav', '.flac', '.aac'];

    List<Map<String, dynamic>> fileData = [];

    for (var file in files) {
      if (file is File && audioExtensions.any(file.path.endsWith)) {
        final modifiedTime = file.lastModifiedSync();
        fileData.add({'path': file.path, 'modified': modifiedTime});
      }
    }

    // 按照修改时间降序排列（最新的在前）
    fileData.sort((a, b) => b['modified'].compareTo(a['modified']));

    List<String> sortedAudioFiles = fileData.map((e) => e['path'] as String).toList();
    List<Tag?> audioTags = [];

    for (var filePath in sortedAudioFiles) {
      try {
        final tag = await AudioTags.read(filePath);
        audioTags.add(tag);
      } catch (e) {
        audioTags.add(null);
      }
    }

    setState(() {
      _audioFiles = sortedAudioFiles;
      _audioTags = audioTags;
    });

    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isScanning = false;
    });
  }

  // 播放音频文件
  Future<void> _playAudio(String filePath) async {
    setState(() {
      _currentFile = filePath;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero; // 确保切换歌曲时进度重置
    });

    final index = _audioFiles.indexOf(filePath);
    final provider = context.read<PlayerProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController?.hasClients ?? false) {
        _pageController?.jumpToPage(index + 1);
      }
    });

    // 加载新歌曲元数据
    final tag = await _loadAudioTag(filePath);
    final fileName = p.basenameWithoutExtension(filePath);

    _player.stream.duration.first.then((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration; // 确保 duration 正确更新
        });
      }
    });

    provider
      ..setCurrentIndex(index)
      ..updateSongMetadata(
        title: tag?.title ?? fileName,
        artistAlbum: '${tag?.trackArtist ?? '未知艺术家'} - ${tag?.album ?? '未知专辑'}',
        coverImage: tag?.pictures.isNotEmpty ?? false ? tag!.pictures.first.bytes : null,
      )
      ..syncPlaybackState(
        isPlaying: true, // 新歌曲自动播放
        currentPosition: Duration.zero,
        totalDuration: _totalDuration,
      );

    await _player.open(Media(filePath));
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
    context.read<PlayerProvider>().syncPlaybackState(
          isPlaying: !_isPlaying,
          currentPosition: _currentPosition,
          totalDuration: _totalDuration,
        );
  }

  void _seekAudio(Duration position) {
    _player.seek(position);
  }

  // 获取上一首歌曲
  String? _getPreviousSong() {
    if (_audioFiles.isEmpty) return null;
    final currentIndex = _audioFiles.indexOf(_currentFile ?? '');
    if (currentIndex == -1) return null; // 🔥 避免无效索引
    final previousIndex = (currentIndex - 1 + _audioFiles.length) % _audioFiles.length;
    return _audioFiles[previousIndex];
  }

  // 获取下一首歌曲
  String? _getNextSong() {
    if (_audioFiles.isEmpty) return null;
    final currentIndex = _audioFiles.indexOf(_currentFile ?? '');
    if (currentIndex == -1) return null; // 🔥 避免无效索引
    final nextIndex = (currentIndex + 1) % _audioFiles.length;
    return _audioFiles[nextIndex];
  }

  // 切换到上一首歌曲
  void _playPrevious() {
    if (_audioFiles.isEmpty) return;
    final previousSong = _getPreviousSong(); // 🔥 确保调用 _getPreviousSong
    if (previousSong != null) {
      setState(() {
        _currentFile = previousSong;
        _currentFileIndex = _audioFiles.indexOf(previousSong);
      });
      _playAudio(previousSong);
      _pageController?.jumpToPage(_currentFileIndex! + 1); // 🔥 让 PageView 也同步
    }
  }

  // 切换到下一首歌曲
  void _playNext() {
    if (_audioFiles.isEmpty) return;
    final nextSong = _getNextSong(); // 🔥 确保调用 _getNextSong
    if (nextSong != null) {
      setState(() {
        _currentFile = nextSong;
        _currentFileIndex = _audioFiles.indexOf(nextSong);
      });
      _playAudio(nextSong);
      _pageController?.jumpToPage(_currentFileIndex! + 1); // 🔥 让 PageView 也同步
    }
  }

  // 构建歌曲显示组件
  Widget _buildSongTile(Song song) {
    return Container(
      margin: EdgeInsets.only(left: 6.0),
      child: Stack(
        children: [
          Row(
            children: [
              ClipRRect(
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
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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

  int _getRealIndex(int index) {
    if (_audioFiles.isEmpty) return 0;
    if (index == 0) return _audioFiles.length - 1; // 第一页 -> 最后一首
    if (index == _audioFiles.length + 1) return 0; // 最后一页 -> 第一首
    return index - 1; // 其他情况，正常索引
  }

  Song _getSongFromIndex(int index) {
    final filePath = _audioFiles[index];
    final tag = _audioTags[index];

    return Song(
      title: tag?.title ?? p.basenameWithoutExtension(filePath),
      artist: tag?.trackArtist ?? '未知艺术家',
      album: tag?.album ?? '未知专辑',
      coverImage: tag?.pictures.isNotEmpty ?? false ? tag!.pictures.first.bytes : null,
    );
  }

  void _handlePageChange(int index) {
    int actualIndex = _getRealIndex(index); // 🔥 获取真实索引

    if (index == 0) {
      // 滑到假的第一页，瞬间跳转到最后一首
      Future.microtask(() {
        _pageController!.jumpToPage(_audioFiles.length);
      });
    } else if (index == _audioFiles.length + 1) {
      // 滑到假的最后一页，瞬间跳转到第一首
      Future.microtask(() {
        _pageController!.jumpToPage(1);
      });
    } else {
      setState(() {
        _currentFileIndex = actualIndex; // 🔥 同步 GridView 索引
        _currentFile = _audioFiles[actualIndex];
      });
      _playAudio(_audioFiles[actualIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: true);

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.escape): () {
          setState(() => exit(0));
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              const itemWidth = 100.0;
              final crossAxisCount = (screenWidth / itemWidth).floor().clamp(1, 10);

              if (_isScanning) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.blue),
                      SizedBox(height: 8.0),
                      Text('扫描文件中...', style: TextStyle(fontSize: 18.0)),
                      Text('已找到 ${_audioFiles.length} 首歌曲'),
                    ],
                  ),
                );
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
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: 220.0,
                    left: 3.0,
                    right: 3.0,
                    top: 3.0,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 3 / 4,
                    crossAxisSpacing: 3.0,
                    mainAxisSpacing: 6.0,
                  ),
                  itemCount: _audioFiles.length,
                  itemBuilder: (context, index) {
                    bool isSelected = index == _currentFileIndex; // 🔥 这里同步 GridView 的选中状态

                    Widget cover;

                    final Tag? tag = _audioTags[index];
                    final file = _audioFiles[index];
                    final fileName = p.basenameWithoutExtension(file);

                    song.title = tag?.title ?? fileName;
                    song.artist = tag?.trackArtist ?? '未知艺术家';
                    song.album = tag?.album ?? '未知专辑';

                    if (tag != null && tag.pictures.isNotEmpty) {
                      song.coverImage = tag.pictures.first.bytes;
                    } else {
                      song.coverImage = null;
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
                          _currentFileIndex = index;
                          _currentFile = _audioFiles[index];
                        });
                        _playAudio(_audioFiles[index]);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.transparent,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
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
                                '${song.artist} - ${song.album}',
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

              final Tag? tag = _audioTags[_currentFileIndex!];
              final Song song = Song(
                title: tag?.title ?? p.basenameWithoutExtension(_currentFile!),
                artist: tag?.trackArtist ?? '未知艺术家',
                album: tag?.album ?? '未知专辑',
                coverImage: (tag?.pictures.isNotEmpty ?? false) ? tag!.pictures.first.bytes : null,
              );

              return Container(
                constraints: BoxConstraints(
                  minWidth: 100.0,
                  minHeight: 100.0,
                  maxWidth: 400.0,
                  maxHeight: 110.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white, // 背景颜色
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(24.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12, // 阴影颜色和透明度
                      blurRadius: 1.0, // 模糊半径
                      spreadRadius: 1.0, // 扩散半径
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(24.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          playerProvider.setSong(
                            coverImage: song.coverImage,
                            title: song.title!,
                            artistAlbum: '${song.artist} - ${song.album}',
                            isPlaying: _isPlaying,
                            onPlayPauseToggle: _togglePlayPause,
                            onPrevious: _playPrevious,
                            onNext: _playNext,
                            currentPosition: _currentPosition,
                            totalDuration: _totalDuration,
                            onSeek: (position) => _seekAudio(position),
                          );
                          Navigator.of(context).pushNamed('/playerDetail');
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
                        child: SizedBox(
                          height: 99.0,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _audioFiles.length + 2, // 🔥 额外加前后两个“假”页面
                            onPageChanged: (index) {
                              _handlePageChange(index);
                            },
                            itemBuilder: (context, index) {
                              int actualIndex = _getRealIndex(index); // 🔥 计算真实歌曲索引
                              Song song = _getSongFromIndex(actualIndex); // 🔥 获取真正的 Song 对象
                              return _buildSongTile(song);
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 11.0,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5.0),
                            trackHeight: 2.0,
                            overlayShape: RoundSliderOverlayShape(overlayRadius: 0.0),
                          ),
                          child: Slider(
                            value: currentValue.isFinite ? currentValue : 0.0, // 避免 NaN 或无效值
                            min: 0.0,
                            max: maxDuration, // 确保 max 不为 0
                            activeColor: Colors.blue,
                            onChangeStart: (value) {
                              setState(() {
                                _draggingPosition = Duration(seconds: value.toInt());
                              });
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
