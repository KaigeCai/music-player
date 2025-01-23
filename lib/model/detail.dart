import 'package:flutter/services.dart';

class Detail {
  final String songTitle;
  final String artistAlbum;
  final Uint8List? coverImage;
  final bool isPlaying;
  final VoidCallback onPlayPauseToggle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Duration currentPosition;
  final Duration totalDuration;
  final Function(Duration) onSeek;

  Detail({
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
}
