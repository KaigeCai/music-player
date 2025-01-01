import 'package:flutter/material.dart';

class PlayerDetailPage extends StatelessWidget {
  final String songTitle;
  final String artistAlbum;
  final String coverImage; // 封面图片的路径（可以是占位符）

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
    return Scaffold(
      appBar: AppBar(
        title: Text('播放详情'),
      ),
      body: Column(
        children: [
          // 歌曲封面
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: coverImage.isNotEmpty
                        ? AssetImage(coverImage)
                        : AssetImage('assets/placeholder.png'), // 替换为你的占位符
                    fit: BoxFit.cover,
                  ),
                ),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              artistAlbum,
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),

          // 功能按钮
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: () {
                    // 收藏按钮逻辑
                  },
                ),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.lyrics),
                  onPressed: () {
                    // 歌词按钮逻辑
                  },
                ),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.more_horiz),
                  onPressed: () {
                    // 更多按钮逻辑
                  },
                ),
              ],
            ),
          ),

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Slider(
                  value: currentPosition.inSeconds.toDouble(),
                  max: totalDuration.inSeconds.toDouble(),
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
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
