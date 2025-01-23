import 'package:flutter/material.dart';

class LyricsWidget extends StatefulWidget {
  const LyricsWidget({super.key});

  @override
  State<LyricsWidget> createState() => _LyricsWidgetState();
}

class _LyricsWidgetState extends State<LyricsWidget> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text('歌词'),
      ),
    );
  }
}
