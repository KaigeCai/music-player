import 'dart:typed_data';

class Song {
  Song({
    required this.coverImage,
    required this.title,
    required this.artist,
    required this.album,
  });

  Uint8List? coverImage;
  String? title;
  String? artist;
  String? album;
}