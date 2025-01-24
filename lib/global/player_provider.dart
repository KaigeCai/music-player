import 'package:flutter/material.dart';
import 'dart:typed_data';

class PlayerProvider with ChangeNotifier {
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

  // Getters
  String get songTitle => _songTitle;
  String get artistAlbum => _artistAlbum;
  Uint8List? get coverImage => _coverImage;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  // 回调函数暴露为公共接口
  VoidCallback get onPlayPauseToggle => _onPlayPauseToggle;
  VoidCallback get onPrevious => _onPrevious;
  VoidCallback get onNext => _onNext;
  Function(Duration) get onSeek => _onSeek;

  // 设置播放信息
  void setSong({
    required Uint8List? coverImage,
    required String title,
    required String artistAlbum,
    required bool isPlaying,
    required Duration currentPositon,
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
    _currentPosition = currentPositon;
    _totalDuration = totalDuration;

    // 初始化回调函数
    _onPlayPauseToggle = onPlayPauseToggle;
    _onPrevious = onPrevious;
    _onNext = onNext;
    _onSeek = onSeek;

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
