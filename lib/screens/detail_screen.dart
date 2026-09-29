import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../data/animals.dart';
import '../services/sound_player.dart';
import '../services/wiki_service.dart';
import '../theme.dart';
import '../widgets/animal_photo.dart';

/// Swipe left/right to move between animals in the current list.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.animals, required this.index});

  final List<Animal> animals;
  final int index;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final PageController _pc = PageController(initialPage: widget.index);
  late int _i = widget.index;

  @override
  void dispose() {
    _pc.dispose();
    SoundPlayer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.animals[_i].ar)),
      body: PageView.builder(
        controller: _pc,
        itemCount: widget.animals.length,
        onPageChanged: (i) {
          SoundPlayer.stop();
          setState(() => _i = i);
        },
        itemBuilder: (context, i) => AnimalPage(animal: widget.animals[i]),
      ),
    );
  }
}

class AnimalPage extends StatelessWidget {
  const AnimalPage({super.key, required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    final color = kCatColor[animal.cat] ?? Colors.teal;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AnimalPhoto(animal: animal, large: true),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Text(animal.ar,
                  style: theme.textTheme.headlineLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(animal.en,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(kCategories[animal.cat] ?? ''),
            backgroundColor: color.withValues(alpha: 0.18),
            side: BorderSide(color: color),
          ),
          const SizedBox(height: 16),
          SoundSection(animal: animal),
          const SizedBox(height: 20),
          FutureBuilder<AnimalMedia>(
            future: WikiService.media(animal),
            builder: (context, snap) {
              final page = snap.data?.pageUrl;
              return Text(
                'مصدر الصورة: ويكيبيديا${page == null ? '' : '\n$page'}',
                style: theme.textTheme.bodySmall,
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ],
      ),
    );
  }
}

class SoundSection extends StatefulWidget {
  const SoundSection({super.key, required this.animal});

  final Animal animal;

  @override
  State<SoundSection> createState() => _SoundSectionState();
}

class _SoundSectionState extends State<SoundSection> {
  bool _loading = false;
  bool _playing = false;
  String? _msg;
  SoundInfo? _info;
  StreamSubscription<PlayerState>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = SoundPlayer.player.playerStateStream.listen((s) {
      final playing = s.playing &&
          s.processingState != ProcessingState.completed &&
          s.processingState != ProcessingState.idle &&
          SoundPlayer.currentUrl != null &&
          SoundPlayer.currentUrl == _info?.url;
      if (playing != _playing && mounted) setState(() => _playing = playing);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await SoundPlayer.stop();
      return;
    }
    setState(() {
      _loading = true;
      _msg = null;
    });
    final info = await WikiService.sound(widget.animal);
    if (!mounted) return;
    if (info == null) {
      setState(() {
        _loading = false;
        _msg = 'لم نجد تسجيلًا صوتيًا حقيقيًا لهذا الحيوان على الإنترنت.';
      });
      return;
    }
    _info = info;
    final ok = await SoundPlayer.play(info);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!ok) {
        final err = SoundPlayer.lastError;
        _msg = 'تعذّر تشغيل الصوت. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.'
            '${err == null ? '' : '\n$err'}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.animal;
    if (!a.hasSound) {
      return Text(
        'هذا الحيوان لا يُصدر صوتًا مسموعًا يُذكر، لذلك لا يوجد له تسجيل.',
        style: theme.textTheme.bodyMedium,
      );
    }
    final info = _info;
    final details = [
      if (info?.license != null) info!.license!,
      if (info?.artist != null) info!.artist!,
    ].join(' — ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: _loading ? null : _toggle,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(_playing ? Icons.stop_rounded : Icons.volume_up_rounded),
          label: Text(_playing ? 'إيقاف' : 'اسمع الصوت الحقيقي'),
        ),
        if (a.soundName.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('الصوت: ${a.soundName}', style: theme.textTheme.titleMedium),
        ],
        if (_msg != null) ...[
          const SizedBox(height: 8),
          Text(_msg!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        if (info != null) ...[
          const SizedBox(height: 8),
          Text(
            'مصدر الصوت: ويكيميديا كومنز\n${info.title}${details.isEmpty ? '' : '\n$details'}',
            style: theme.textTheme.bodySmall,
            textDirection: TextDirection.ltr,
          ),
        ],
      ],
    );
  }
}
