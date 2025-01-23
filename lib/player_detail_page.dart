import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music/model/detail.dart';
import 'package:music/widget/lyrics_widget.dart';

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
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

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
          body: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            scrollDirection: isPortrait ? Axis.vertical : Axis.horizontal,
            child: isPortrait
                ? Column(
                    children: _buildLayoutContent(args, isPortrait, context),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
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
                          children: _buildLayoutContent(args, isPortrait, context),
                        ),
                      ),
                      SizedBox(width: 3.0),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLayoutContent(
    Detail args,
    bool isPortrait,
    BuildContext context,
  ) {
    return [
      if (isPortrait)
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

      // Song title
      Text(
        args.songTitle,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),

      // Artist-Album
      Text(
        args.artistAlbum,
        style: TextStyle(fontSize: 16, color: Colors.grey),
        textAlign: TextAlign.center,
      ),

      // Action buttons
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.favorite_border),
            onPressed: () {
              // Favorite button logic
            },
          ),
          SizedBox(width: 16.0),
          IconButton(
            icon: Icon(isPortrait ? Icons.lyrics : Icons.lyrics_outlined),
            onPressed: () {
              // Lyrics button logic
            },
          ),
          SizedBox(width: 16.0),
          IconButton(
            icon: Icon(isPortrait ? Icons.more_horiz : Icons.more_vert_rounded),
            onPressed: () {
              // More button logic
            },
          ),
        ],
      ),

      LyricsWidget(),

      // Playback control buttons
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

      // Progress bar
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
    ];
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
