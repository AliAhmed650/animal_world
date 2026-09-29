import 'dart:math';

import 'package:flutter/material.dart';

import '../data/animals.dart';
import '../services/sound_player.dart';
import '../services/wiki_service.dart';
import '../theme.dart';
import '../widgets/animal_photo.dart';

/// Listen to a real recording, then pick the animal from four real photos.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _rnd = Random();
  Animal? _answer;
  SoundInfo? _sound;
  List<Animal> _options = [];
  int? _chosen;
  int _score = 0;
  int _total = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _next();
  }

  Future<void> _next() async {
    setState(() {
      _loading = true;
      _chosen = null;
      _error = null;
    });
    final pool = kAnimals.where((a) => a.hasSound).toList();
    for (var i = 0; i < 10; i++) {
      final a = pool[_rnd.nextInt(pool.length)];
      if (a == _answer) continue;
      final s = await WikiService.sound(a);
      if (s == null) continue;
      // Avoid look-alike sounds among the choices (e.g. lion and tiger both roar).
      final others = pool
          .where((x) => x.id != a.id && x.soundName != a.soundName)
          .toList()
        ..shuffle(_rnd);
      final opts = [a, ...others.take(3)]..shuffle(_rnd);
      if (!mounted) return;
      setState(() {
        _answer = a;
        _sound = s;
        _options = opts;
        _loading = false;
      });
      _play();
      return;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = 'تعذّر تحميل صوت من الإنترنت. تأكد من الاتصال وحاول مجددًا.';
    });
  }

  Future<void> _play() async {
    final s = _sound;
    if (s == null) return;
    final ok = await SoundPlayer.play(s);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تشغيل الصوت. جرّب مرة أخرى.')),
      );
    }
  }

  void _choose(int i) {
    if (_chosen != null) return;
    setState(() {
      _chosen = i;
      _total++;
      if (_options[i].id == _answer!.id) _score++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('الإجابات الصحيحة: $_score من $_total',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          if (_loading) ...[
            const SizedBox(height: 80),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            const Text('جاري تحميل صوت حقيقي…'),
          ] else if (_error != null) ...[
            const SizedBox(height: 60),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _next, child: const Text('حاول مجددًا')),
          ] else ...[
            IconButton.filled(
              iconSize: 56,
              padding: const EdgeInsets.all(24),
              onPressed: _play,
              icon: const Icon(Icons.volume_up_rounded),
              tooltip: 'شغّل الصوت مرة أخرى',
            ),
            const SizedBox(height: 12),
            Text('أي حيوان يصدر هذا الصوت؟',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                for (var i = 0; i < _options.length; i++) _option(i),
              ],
            ),
            const SizedBox(height: 16),
            if (_chosen != null) ...[
              Text(
                _options[_chosen!].id == _answer!.id
                    ? 'أحسنت! هذا صوت ${_answer!.ar}'
                    : 'ليست الإجابة الصحيحة. هذا صوت ${_answer!.ar}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _next, child: const Text('السؤال التالي')),
            ],
          ],
        ],
      ),
    );
  }

  Widget _option(int i) {
    final a = _options[i];
    final color = kCatColor[a.cat] ?? Colors.teal;
    final answered = _chosen != null;
    final isRight = a.id == _answer!.id;
    final isWrongPick = answered && _chosen == i && !isRight;
    Color border = color.withValues(alpha: 0.6);
    IconData? mark;
    if (answered && isRight) {
      border = Colors.green;
      mark = Icons.check_circle;
    } else if (isWrongPick) {
      border = Colors.red;
      mark = Icons.cancel;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: answered ? null : () => _choose(i),
      child: Ink(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: mark == null ? 2 : 4),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AnimalPhoto(animal: a),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(a.ar,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ],
            ),
            if (mark != null)
              PositionedDirectional(
                top: 8,
                start: 8,
                child: Icon(mark, color: border, size: 32),
              ),
          ],
        ),
      ),
    );
  }
}
