import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class ChapterVideosScreen extends StatefulWidget {
  final String subject;
  final String chapter;

  const ChapterVideosScreen({
    super.key,
    required this.subject,
    required this.chapter,
  });

  @override
  State<ChapterVideosScreen> createState() => _ChapterVideosScreenState();
}

class VideoMetadata {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final String viewCount;
  final String publishedAt;

  VideoMetadata({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.viewCount,
    required this.publishedAt,
  });

  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'];
    final statistics = json['statistics'];
    return VideoMetadata(
      id: json['id'],
      title: snippet['title'],
      thumbnailUrl: snippet['thumbnails']['high']['url'],
      channelTitle: snippet['channelTitle'],
      viewCount: statistics['viewCount'],
      publishedAt: snippet['publishedAt'],
    );
  }
}

class _ChapterVideosScreenState extends State<ChapterVideosScreen> {
  static const String apiKey = 'AIzaSyD42Kb1ksOUHE8avZzCIsucC1dFQ8oQYI8'; // Replace with your API key
  Future<List<VideoMetadata>> _getVideoLinks() async {
    try {
      print('Fetching videos for subject: ${widget.subject}, chapter: ${widget.chapter}');
      final doc = await FirebaseFirestore.instance
          .collection(widget.subject)
          .doc(widget.chapter)
          .get();

      if (!doc.exists) {
        print('Document does not exist');
        return [];
      }

      final data = doc.data()!;
      print('Document data: $data');
      List<String> videoIds = [];
      
      // Look for any field that contains a YouTube link
      print('Looking for video links in fields: ${data.keys.join(', ')}');
      data.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          print('Checking field $key with value: $value');
          try {
            final uri = Uri.parse(value);
            String? videoId;
            
            // Handle different YouTube URL formats
            if (uri.host.contains('youtube.com')) {
              videoId = uri.queryParameters['v'];
            } else if (uri.host.contains('youtu.be')) {
              videoId = uri.pathSegments.last;
            }
            
            if (videoId != null) {
              print('Found video ID: $videoId in field: $key');
              videoIds.add(videoId);
            }
          } catch (e) {
            print('Error parsing URL in field $key: $e');
          }
        }
      });

      // Fetch video metadata from YouTube API
      if (videoIds.isEmpty) {
        print('No video IDs found');
        return [];
      }

      final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics&id=${videoIds.join(",")}&key=$apiKey',
      );

      try {
        print('Fetching from YouTube API: $url');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return (data['items'] as List)
              .map((item) => VideoMetadata.fromJson(item))
              .toList();
        }
      } catch (e) {
        print('Error fetching video metadata: $e');
      }

      return [];
    } catch (e) {
      print('Error fetching video links: $e');
      return [];
    }
  }

  Future<void> _launchYouTubeVideo(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch video'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.chapter} Videos'),
      ),
      body: FutureBuilder<List<VideoMetadata>>(
        future: _getVideoLinks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final videos = snapshot.data ?? [];

          if (videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No videos available for this chapter',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _launchYouTubeVideo('https://www.youtube.com/watch?v=${video.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: CachedNetworkImage(
                                imageUrl: video.thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  video.channelTitle,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '•',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_formatNumber(int.parse(video.viewCount))} views',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
