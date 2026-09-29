import 'package:flutter/material.dart';

import '../data/animals.dart';
import '../theme.dart';
import '../widgets/animal_photo.dart';
import 'detail_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  String _cat = 'all';
  String _q = '';

  List<Animal> get _list {
    final q = normalizeText(_q);
    return kAnimals.where((a) {
      if (_cat != 'all' && a.cat != _cat) return false;
      if (q.isEmpty) return true;
      return normalizeText('${a.ar} ${a.en} ${a.soundName}').contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    final chips = <String, String>{'all': 'الكل', ...kCategories};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Text(
            'عالم الحيوانات',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'ابحث عن حيوان…',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final e in chips.entries)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: _cat == e.key,
                    onSelected: (_) => setState(() => _cat = e.key),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Text(
            'عدد الحيوانات: ${list.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('لا يوجد حيوان بهذا الاسم. جرّب كلمة أخرى.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) => AnimalTile(
                    animal: list[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(animals: list, index: i),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class AnimalTile extends StatelessWidget {
  const AnimalTile({super.key, required this.animal, required this.onTap});

  final Animal animal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = kCatColor[animal.cat] ?? Colors.teal;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: AnimalPhoto(animal: animal),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: Column(
                children: [
                  Text(
                    animal.ar,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    animal.en,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
