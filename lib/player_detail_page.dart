import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music/lyrics_widget.dart';

class PlayerDetailPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    bool isDesktop = !kIsWeb && MediaQuery.of(context).size.width > 600;
    return Scaffold(
      body: Builder(builder: (context) {
        if (isDesktop) {
          return Row(
            children: [
              // 歌曲封面
              AspectRatio(
                aspectRatio: 1.0,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Image.memory(
                    coverImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 歌曲标题
                    Text(
                      songTitle,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),

                    // 歌手-专辑
                    Text(
                      artistAlbum,
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
                          onPressed: onPrevious,
                        ),
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle : Icons.play_circle,
                            size: 64,
                          ),
                          onPressed: onPlayPauseToggle,
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_next, size: 36),
                          onPressed: onNext,
                        ),
                      ],
                    ),

                    // 进度条
                    Column(
                      children: [
                        Slider(
                          value: currentPosition.inSeconds.toDouble(),
                          max: totalDuration.inSeconds.toDouble(),
                          activeColor: Colors.blue,
                          onChanged: (value) {
                            onSeek(Duration(seconds: value.toInt()));
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(currentPosition),
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              _formatDuration(totalDuration),
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              // 歌曲封面
              AspectRatio(
                aspectRatio: 1.0,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Image.memory(
                    coverImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 歌曲标题
              Text(
                songTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              // 歌手-专辑
              Text(
                artistAlbum,
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
                    onPressed: onPrevious,
                  ),
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle : Icons.play_circle,
                      size: 64,
                    ),
                    onPressed: onPlayPauseToggle,
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next, size: 36),
                    onPressed: onNext,
                  ),
                ],
              ),

              // 进度条
              Column(
                children: [
                  Slider(
                    value: currentPosition.inSeconds.toDouble(),
                    max: totalDuration.inSeconds.toDouble(),
                    activeColor: Colors.blue,
                    onChanged: (value) {
                      onSeek(Duration(seconds: value.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(currentPosition),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _formatDuration(totalDuration),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
