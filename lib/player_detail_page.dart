import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music/lyrics_widget.dart';

class PlayerDetailPage extends StatefulWidget {
  final String songTitle;
  final String artistAlbum;
  final Uint8List? coverImage; // 封面图片的路径（可以是占位符）

  final bool isPlaying;
  final VoidCallback onPlayPauseToggle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  final Duration currentPosition;
  final Duration totalDuration;
  final ValueChanged<Duration> onSeek;

  const PlayerDetailPage({
    super.key,
    required this.songTitle,
    required this.artistAlbum,
    required this.coverImage,
    required this.isPlaying,
    required this.onPlayPauseToggle,
    required this.onPrevious,
    required this.onNext,
    required this.currentPosition,
    required this.totalDuration,
    required this.onSeek,
  });

  @override
  State<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage> {
  final GlobalKey _imageKey = GlobalKey();
  double imageWidth = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        setState(() {
          imageWidth = renderBox.size.width;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return _buildPortraitLayout(); // 竖屏布局
          } else {
            build(context);
            return _buildLandscapeLayout(); // 横屏布局
          }
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildPortraitLayout() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        children: [
          // 歌曲封面
          AspectRatio(
            key: _imageKey,
            aspectRatio: 1.0,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Image.memory(
                widget.coverImage!,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 歌曲标题
          Text(
            widget.songTitle,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          // 歌手-专辑
          Text(
            widget.artistAlbum,
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),

          // 功能按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.favorite_border),
                onPressed: () {
                  // 收藏按钮逻辑
                },
              ),
              SizedBox(width: 16.0),
              IconButton(
                icon: Icon(Icons.lyrics),
                onPressed: () {
                  // 歌词按钮逻辑
                },
              ),
              SizedBox(width: 16.0),
              IconButton(
                icon: Icon(Icons.more_horiz),
                onPressed: () {
                  // 更多按钮逻辑
                },
              ),
            ],
          ),
          LyricsWidget(),
          // 播放控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.skip_previous, size: 36),
                onPressed: widget.onPrevious,
              ),
              IconButton(
                icon: Icon(
                  widget.isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 64,
                ),
                onPressed: widget.onPlayPauseToggle,
              ),
              IconButton(
                icon: Icon(Icons.skip_next, size: 36),
                onPressed: widget.onNext,
              ),
            ],
          ),

          // 进度条
          Column(
            children: [
              Slider(
                value: widget.currentPosition.inSeconds.toDouble(),
                max: widget.totalDuration.inSeconds.toDouble(),
                activeColor: Colors.blue,
                onChanged: (value) {
                  widget.onSeek(Duration(seconds: value.toInt()));
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(widget.currentPosition),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _formatDuration(widget.totalDuration),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // 歌曲封面
          AspectRatio(
            key: _imageKey,
            aspectRatio: 1.0,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Image.memory(
                widget.coverImage!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width - imageWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                // 歌曲标题
                Text(
                  widget.songTitle,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                // 歌手-专辑
                Text(
                  widget.artistAlbum,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                // 功能按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.favorite_border),
                      onPressed: () {
                        // 收藏按钮逻辑
                      },
                    ),
                    SizedBox(width: 16.0),
                    IconButton(
                      icon: Icon(Icons.lyrics_outlined),
                      onPressed: () {
                        // 歌词按钮逻辑
                      },
                    ),
                    SizedBox(width: 16.0),
                    IconButton(
                      icon: Icon(Icons.more_vert_rounded),
                      onPressed: () {
                        // 更多按钮逻辑
                      },
                    ),
                  ],
                ),
                // LyricsWidget(),
                // 播放控制按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.skip_previous, size: 36),
                      onPressed: widget.onPrevious,
                    ),
                    IconButton(
                      icon: Icon(
                        widget.isPlaying ? Icons.pause_circle : Icons.play_circle,
                        size: 64,
                      ),
                      onPressed: widget.onPlayPauseToggle,
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next, size: 36),
                      onPressed: widget.onNext,
                    ),
                  ],
                ),

                // 进度条
                Column(
                  children: [
                    Slider(
                      value: widget.currentPosition.inSeconds.toDouble(),
                      max: widget.totalDuration.inSeconds.toDouble(),
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        widget.onSeek(Duration(seconds: value.toInt()));
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(widget.currentPosition),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          _formatDuration(widget.totalDuration),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 3.0),
        ],
      ),
    );
  }
}
