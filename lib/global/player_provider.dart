import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../widget/lyrics_widget.dart';

class PlayerProvider with ChangeNotifier {
  int? _currentIndex;
  // 播放信息
  Uint8List? _coverImage;
  String _songTitle = '';
  String _artistAlbum = '';

  // 播放状态
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // 自定义回调
  late VoidCallback _onPlayPauseToggle;
  late VoidCallback _onPrevious;
  late VoidCallback _onNext;
  late Function(Duration) _onSeek;

  List<LyricLine> _currentLyrics = [];

  // Getters
  String get songTitle => _songTitle;
  String get artistAlbum => _artistAlbum;
  Uint8List? get coverImage => _coverImage;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  int? get currentIndex => _currentIndex;
  List<LyricLine> get currentLyrics => _currentLyrics;

  // 回调函数暴露为公共接口
  VoidCallback get onPlayPauseToggle => _onPlayPauseToggle;
  VoidCallback get onPrevious => _onPrevious;
  VoidCallback get onNext => _onNext;
  Function(Duration) get onSeek => _onSeek;

  // 更新歌词
  void updateLyrics(List<LyricLine> lyrics) {
    _currentLyrics = lyrics;
    notifyListeners();
  }

  // 设置播放信息
  void setSong({
    required Uint8List? coverImage,
    required String title,
    required String artistAlbum,
    required bool isPlaying,
    required Duration currentPosition,
    required Duration totalDuration,
    required VoidCallback onPlayPauseToggle,
    required VoidCallback onPrevious,
    required VoidCallback onNext,
    required Function(Duration) onSeek,
  }) {
    _songTitle = title;
    _artistAlbum = artistAlbum;
    _coverImage = coverImage;
    _isPlaying = isPlaying;
    _currentPosition = currentPosition;
    _totalDuration = totalDuration;

    // 初始化回调函数
    _onPlayPauseToggle = onPlayPauseToggle;
    _onPrevious = onPrevious;
    _onNext = onNext;
    _onSeek = onSeek;

    notifyListeners();
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void syncPlaybackState({
    required bool isPlaying,
    required Duration currentPosition,
    required Duration totalDuration,
  }) {
    _isPlaying = isPlaying;
    _currentPosition = currentPosition;
    _totalDuration = totalDuration;
    notifyListeners();
  }

  // 新增状态同步方法
  void updateSongMetadata({
    required String title,
    required String artistAlbum,
    required Uint8List? coverImage,
  }) {
    _songTitle = title;
    _artistAlbum = artistAlbum;
    _coverImage = coverImage;
    notifyListeners();
  }

  // 更新当前播放位置
  void seek(Duration position) {
    _currentPosition = position;
    _onSeek(position); // 执行回调
    notifyListeners();
  }

  // 播放/暂停切换
  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    _onPlayPauseToggle(); // 执行回调
    notifyListeners();
  }

  // 播放上一首
  void playPrevious() {
    _onPrevious(); // 执行回调
    notifyListeners();
  }

  // 播放下一首
  void playNext() {
    _onNext(); // 执行回调
    notifyListeners();
  }
}
