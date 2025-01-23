import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music/widget/lyrics_widget.dart';
import 'package:music/model/detail.dart';

class PlayerDetailPage extends StatefulWidget {
  const PlayerDetailPage({super.key});

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
    final args = ModalRoute.of(context)?.settings.arguments as Detail;

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.escape): () {
          setState(() {
            Navigator.of(context).pop();
          });
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.portrait) {
                return _buildPortraitLayout(args); // 竖屏布局
              } else {
                build(context);
                return _buildLandscapeLayout(args); // 横屏布局
              }
            },
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildPortraitLayout(Detail args) {
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
                args.coverImage!,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 歌曲标题
          Text(
            args.songTitle,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          // 歌手-专辑
          Text(
            args.artistAlbum,
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
                onPressed: args.onPrevious,
              ),
              IconButton(
                icon: Icon(
                  args.isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 64,
                ),
                onPressed: args.onPlayPauseToggle,
              ),
              IconButton(
                icon: Icon(Icons.skip_next, size: 36),
                onPressed: args.onNext,
              ),
            ],
          ),

          // 进度条
          Column(
            children: [
              Slider(
                value: args.currentPosition.inSeconds.toDouble(),
                max: args.totalDuration.inSeconds.toDouble(),
                activeColor: Colors.blue,
                onChanged: (value) {
                  args.onSeek(Duration(seconds: value.toInt()));
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(args.currentPosition),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _formatDuration(args.totalDuration),
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

  Widget _buildLandscapeLayout(Detail args) {
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
                args.coverImage!,
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
                  args.songTitle,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                // 歌手-专辑
                Text(
                  args.artistAlbum,
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

                LyricsWidget(),

                // 播放控制按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.skip_previous, size: 36),
                      onPressed: args.onPrevious,
                    ),
                    IconButton(
                      icon: Icon(
                        args.isPlaying ? Icons.pause_circle : Icons.play_circle,
                        size: 64,
                      ),
                      onPressed: args.onPlayPauseToggle,
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next, size: 36),
                      onPressed: args.onNext,
                    ),
                  ],
                ),

                // 进度条
                Column(
                  children: [
                    Slider(
                      value: args.currentPosition.inSeconds.toDouble(),
                      max: args.totalDuration.inSeconds.toDouble(),
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        args.onSeek(Duration(seconds: value.toInt()));
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(args.currentPosition),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          _formatDuration(args.totalDuration),
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
