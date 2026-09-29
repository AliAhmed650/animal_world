import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/animals.dart';
import '../services/wiki_service.dart';

class AnimalPhoto extends StatelessWidget {
  const AnimalPhoto({
    super.key,
    required this.animal,
    this.large = false,
    this.fit = BoxFit.cover,
  });

  final Animal animal;
  final bool large;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AnimalMedia>(
      future: WikiService.media(animal),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _Box(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final m = snap.data;
        final url = large ? m?.photoUrl : m?.thumbUrl;
        if (url == null) {
          return const _Box(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_not_supported_outlined),
                SizedBox(height: 4),
                Text('لا توجد صورة', style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        }
        return CachedNetworkImage(
          imageUrl: url,
          httpHeaders: kHeaders,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) =>
              const _Box(child: CircularProgressIndicator(strokeWidth: 2)),
          errorWidget: (_, __, ___) =>
              const _Box(child: Icon(Icons.broken_image_outlined)),
        );
      },
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: child,
    );
  }
}
