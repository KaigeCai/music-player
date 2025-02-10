import 'package:flutter/material.dart';
import '../global/player_provider.dart';
import 'package:provider/provider.dart';

class LyricsWidget extends StatefulWidget {
  final List<LyricLine> lyrics; // 接收歌词数据

  const LyricsWidget({super.key, required this.lyrics});

  @override
  State<LyricsWidget> createState() => _LyricsWidgetState();
}

class _LyricsWidgetState extends State<LyricsWidget> {
  final ScrollController _scrollController = ScrollController();
  int _currentLineIndex = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<PlayerProvider>(context);
    _syncLyrics(provider.currentPosition);
  }

  void _syncLyrics(Duration position) {
    if (widget.lyrics.isEmpty) return; // 如果没有歌词，直接返回

    final milliseconds = position.inMilliseconds;
    int newIndex = -1;

    for (int i = 0; i < widget.lyrics.length; i++) {
      if (widget.lyrics[i].timeStamp <= milliseconds) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _currentLineIndex) {
      _currentLineIndex = newIndex;
      if (_currentLineIndex > 2) {
        _scrollController.animateTo(
          (_currentLineIndex - 2) * 40.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        _syncLyrics(provider.currentPosition);

        // 如果没有歌词，显示“暂无歌词”
        if (widget.lyrics.isEmpty) {
          return const Expanded(
            child: Center(
              child: Text(
                '暂无歌词',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        return Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: widget.lyrics.length,
            itemBuilder: (context, index) {
              final lyric = widget.lyrics[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  lyric.text,
                  style: TextStyle(
                    fontSize: _currentLineIndex == index ? 24 : 18,
                    color: _currentLineIndex == index ? Colors.blue : Colors.grey[600],
                    fontWeight: _currentLineIndex == index ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class LyricLine {
  final int timeStamp; // 毫秒
  final String text;

  LyricLine(this.timeStamp, this.text);
}
