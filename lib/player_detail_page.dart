import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music/global/player_provider.dart';
import 'package:music/widget/lyrics_widget.dart';
import 'package:provider/provider.dart';

class PlayerDetailPage extends StatefulWidget {
  const PlayerDetailPage({super.key});

  @override
  State<PlayerDetailPage> createState() => PlayerDetailPageState();
}

class PlayerDetailPageState extends State<PlayerDetailPage> {
  final GlobalKey imageKey = GlobalKey();
  double imageWidth = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = imageKey.currentContext?.findRenderObject() as RenderBox?;
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
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).pop();
        },
      },
      child: Focus(
        autofocus: true,
        child: Consumer<PlayerProvider>(builder: (context, provider, widget) {
          return Scaffold(
            body: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              scrollDirection: isPortrait ? Axis.vertical : Axis.horizontal,
              child: isPortrait
                  ? PortraitLayout(
                      imageKey: imageKey,
                      lyrics: provider.currentLyrics,
                    )
                  : LandscapeLayout(
                      imageWidth: imageWidth,
                      imageKey: imageKey,
                      lyrics: provider.currentLyrics,
                    ),
            ),
          );
        }),
      ),
    );
  }
}

class PortraitLayout extends StatelessWidget {
  final GlobalKey imageKey;
  final List<LyricLine> lyrics;

  const PortraitLayout({
    super.key,
    required this.imageKey,
    required this.lyrics,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(builder: (context, args, child) {
      return SizedBox(
        height: MediaQuery.of(context).size.height + 1.0,
        child: Column(
          children: [
            AlbumArt(imageKey: imageKey, coverImage: args.coverImage),
            SongInfo(songTitle: args.songTitle, artistAlbum: args.artistAlbum),
            ActionButtons(),
            LyricsWidget(lyrics: args.currentLyrics),
            PlaybackControls(),
            PlaybackProgress(),
          ],
        ),
      );
    });
  }
}

class LandscapeLayout extends StatelessWidget {
  final double imageWidth;
  final GlobalKey imageKey;
  final List<LyricLine> lyrics;

  const LandscapeLayout({
    super.key,
    required this.imageWidth,
    required this.imageKey,
    required this.lyrics,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(builder: (context, args, child) {
      return Row(
        children: [
          AlbumArt(imageKey: imageKey, coverImage: args.coverImage),
          SizedBox(
            width: MediaQuery.of(context).size.width - imageWidth + 1.0,
            height: MediaQuery.of(context).size.height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SongInfo(songTitle: args.songTitle, artistAlbum: args.artistAlbum),
                ActionButtons(),
                LyricsWidget(lyrics: args.currentLyrics),
                PlaybackControls(),
                PlaybackProgress(),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class AlbumArt extends StatelessWidget {
  final GlobalKey imageKey;
  final Uint8List? coverImage;

  const AlbumArt({super.key, required this.imageKey, required this.coverImage});

  @override
  Widget build(BuildContext context) => coverImage != null
      ? AspectRatio(
          key: imageKey,
          aspectRatio: 1.0,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Image.memory(
              coverImage!,
              fit: BoxFit.cover,
            ),
          ),
        )
      : AspectRatio(
          aspectRatio: 1.0,
          key: imageKey,
          child: Container(
            color: Colors.black12,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(
                Icons.music_note,
                color: Colors.black,
              ),
            ),
          ),
        );
}

class SongInfo extends StatelessWidget {
  final String songTitle;
  final String artistAlbum;

  const SongInfo({super.key, required this.songTitle, required this.artistAlbum});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          songTitle,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(
          artistAlbum,
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: Icon(Icons.favorite_border), onPressed: () {}),
        SizedBox(width: 16),
        IconButton(icon: Icon(Icons.lyrics), onPressed: () {}),
        SizedBox(width: 16),
        IconButton(icon: Icon(Icons.more_horiz), onPressed: () {}),
      ],
    );
  }
}

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(builder: (context, args, child) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.skip_previous, size: 36),
            onPressed: args.onPrevious,
          ),
          IconButton(
            icon: Icon(args.isPlaying ? Icons.pause_circle : Icons.play_circle, size: 64),
            onPressed: args.onPlayPauseToggle,
          ),
          IconButton(
            icon: Icon(Icons.skip_next, size: 36),
            onPressed: args.onNext,
          ),
        ],
      );
    });
  }
}

class PlaybackProgress extends StatelessWidget {
  const PlaybackProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(builder: (context, args, child) {
      final int totalSeconds = args.totalDuration.inSeconds;
      final bool hasDuration = totalSeconds > 0;
      final double maxDuration = hasDuration ? totalSeconds.toDouble() : 1.0;

      final double currentPos = args.currentPosition.inSeconds.toDouble();
      final double clampedValue = currentPos.clamp(0.0, maxDuration); // 避免越界

      return Column(
        children: [
          Slider(
            value: clampedValue.isFinite ? clampedValue : 0.0, // 确保 value 合法
            min: 0.0,
            max: maxDuration, // 确保 max 不为 0
            activeColor: Colors.blue,
            onChanged: (value) {
              args.seek(Duration(seconds: value.toInt()));
            },
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDuration(args.currentPosition),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  formatDuration(args.totalDuration),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
}
