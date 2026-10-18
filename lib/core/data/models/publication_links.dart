import 'package:stimmapp/core/functions/parse_website_link.dart';

/// Optional supporting material shared by petitions and questionnaires.
class PublicationLinks {
  const PublicationLinks({this.youtubeUrl, this.websiteUrl});

  final String? youtubeUrl;
  final String? websiteUrl;

  static Uri? websiteUri(String? value) => parseWebsiteLink(value);

  static Uri? youtubeUri(String? value) {
    final uri = websiteUri(value);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments;
    String? videoId;
    if (host == 'youtu.be' && segments.length == 1) {
      videoId = segments.first;
    } else if (const {
      'youtube.com',
      'www.youtube.com',
      'm.youtube.com',
    }.contains(host)) {
      if (uri.path == '/watch') {
        videoId = uri.queryParameters['v'];
      } else if (segments.length == 2 &&
          const {'shorts', 'embed', 'live'}.contains(segments.first)) {
        videoId = segments[1];
      }
    }
    return videoId != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(videoId)
        ? uri
        : null;
  }

  Map<String, dynamic> toJson() => {
    if (youtubeUrl != null) 'youtubeUrl': youtubeUrl,
    if (websiteUrl != null) 'websiteUrl': websiteUrl,
  };

  factory PublicationLinks.fromJson(Object? value) {
    final map = value is Map ? value : const {};
    return PublicationLinks(
      youtubeUrl: map['youtubeUrl'] is String
          ? map['youtubeUrl'] as String
          : null,
      websiteUrl: map['websiteUrl'] is String
          ? map['websiteUrl'] as String
          : null,
    );
  }
}
