import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/animals.dart';

/// Wikimedia asks every app to send a descriptive User-Agent.
/// TODO: replace the address below with your own repo / e-mail.
const Map<String, String> kHeaders = {
  'User-Agent':
      'AnimalWorldApp/1.0 (https://github.com/AliAhmed650/animal_world; alii.ahmed.21101@gmail.com)',
};

class AnimalMedia {
  final String? thumbUrl;
  final String? photoUrl;
  final String? pageUrl;
  const AnimalMedia({this.thumbUrl, this.photoUrl, this.pageUrl});
}

class SoundInfo {
  final String url;
  final String title;
  final String? license;
  final String? artist;
  const SoundInfo({
    required this.url,
    required this.title,
    this.license,
    this.artist,
  });
}

/// Fetches real photos (Wikipedia) and real recordings (Wikimedia Commons)
/// at runtime. Results are cached in memory for the session.
class WikiService {
  WikiService._();

  static final Map<String, Future<AnimalMedia>> _media = {};
  static final Map<String, Future<SoundInfo?>> _sounds = {};

  static Future<AnimalMedia> media(Animal a) {
    return _media.putIfAbsent(a.id, () {
      return _loadMedia(a).then((m) {
        if (m.thumbUrl == null) _media.remove(a.id); // retry next time
        return m;
      });
    });
  }

  static Future<SoundInfo?> sound(Animal a) {
    return _sounds.putIfAbsent(a.id, () {
      return _loadSound(a).then((s) {
        if (s == null) _sounds.remove(a.id); // retry next time
        return s;
      });
    });
  }

  static String _title(Animal a) =>
      Uri.encodeComponent(a.wiki.replaceAll(' ', '_'));

  // ---------- photos ----------
  static Future<AnimalMedia> _loadMedia(Animal a) async {
    try {
      final r = await http
          .get(
            Uri.parse(
                'https://en.wikipedia.org/api/rest_v1/page/summary/${_title(a)}'),
            headers: kHeaders,
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return const AnimalMedia();
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final thumb = (j['thumbnail'] as Map?)?['source'] as String?;
      final orig = j['originalimage'] as Map?;
      final origUrl = orig?['source'] as String?;
      final origW = (orig?['width'] as num?)?.toInt();

      String? photo;
      if (thumb != null) {
        if (origW != null && origW < 500 && origUrl != null) {
          photo = origUrl; // never ask Wikimedia for a size bigger than the file
        } else {
          photo = thumb.replaceFirstMapped(RegExp(r'/\d+px-'), (m) => '/500px-');
        }
      } else {
        photo = origUrl;
      }
      final page =
          ((j['content_urls'] as Map?)?['desktop'] as Map?)?['page'] as String?;
      return AnimalMedia(
        thumbUrl: thumb ?? origUrl,
        photoUrl: photo,
        pageUrl: page,
      );
    } catch (_) {
      return const AnimalMedia();
    }
  }

  // ---------- sounds ----------
  static Future<SoundInfo?> _loadSound(Animal a) async {
    final q = a.snd;
    if (q == null) return null;
    try {
      final s = await _commonsSearch(q);
      if (s != null) return s;
    } catch (_) {}
    try {
      return await _articleAudio(a);
    } catch (_) {
      return null;
    }
  }

  static Future<SoundInfo?> _commonsSearch(String q) async {
    final uri = Uri.https('commons.wikimedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'generator': 'search',
      'gsrnamespace': '6',
      'gsrsearch': '$q filetype:audio',
      'gsrlimit': '12',
      'prop': 'imageinfo',
      'iiprop': 'url|mime|extmetadata',
    });
    final r =
        await http.get(uri, headers: kHeaders).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) return null;
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final pages =
        ((j['query'] as Map?)?['pages'] as Map?)?.values.toList() ?? <dynamic>[];
    pages.sort((x, y) =>
        ((x['index'] ?? 0) as num).compareTo((y['index'] ?? 0) as num));

    final tokens =
        q.toLowerCase().split(' ').where((t) => t.length > 2).toList();
    Map? bestInfo;
    String bestTitle = '';
    int bestScore = 0;

    for (final p in pages) {
      final infos = p['imageinfo'] as List?;
      if (infos == null || infos.isEmpty) continue;
      final info = infos.first as Map;
      final mime = (info['mime'] as String?) ?? '';
      final isAudio = mime.startsWith('audio/') || mime == 'application/ogg';
      if (!isAudio || mime.contains('midi')) continue;
      final title = (p['title'] as String?) ?? '';
      final lower = title.toLowerCase();
      final score = tokens.where(lower.contains).length;
      if (score > bestScore) {
        bestScore = score;
        bestInfo = info;
        bestTitle = title;
      }
    }
    if (bestInfo == null) return null;

    final meta = bestInfo['extmetadata'] as Map?;
    final license =
        (meta?['LicenseShortName'] as Map?)?['value'] as String?;
    final artistHtml = (meta?['Artist'] as Map?)?['value'] as String?;
    final artist = artistHtml?.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    return SoundInfo(
      url: bestInfo['url'] as String,
      title: bestTitle.replaceFirst('File:', ''),
      license: license,
      artist: (artist == null || artist.isEmpty) ? null : artist,
    );
  }

  static Future<SoundInfo?> _articleAudio(Animal a) async {
    final r = await http
        .get(
          Uri.parse(
              'https://en.wikipedia.org/api/rest_v1/page/media-list/${_title(a)}'),
          headers: kHeaders,
        )
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) return null;
    final items =
        (jsonDecode(utf8.decode(r.bodyBytes)) as Map)['items'] as List? ??
            <dynamic>[];
    for (final it in items) {
      if (it is! Map || it['type'] != 'audio') continue;
      String? src = (it['original'] as Map?)?['source'] as String?;
      if (src == null) {
        final set = it['srcset'] as List?;
        if (set != null && set.isNotEmpty) {
          src = (set.first as Map)['src'] as String?;
        }
      }
      if (src == null) continue;
      if (src.startsWith('//')) src = 'https:$src';
      return SoundInfo(
        url: src,
        title: ((it['title'] as String?) ?? 'audio').replaceFirst('File:', ''),
      );
    }
    return null;
  }
}
