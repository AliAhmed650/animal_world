import 'package:flutter/material.dart';

import '../services/sound_player.dart';
import 'browse_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _quizOpened = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            const BrowseScreen(),
            _quizOpened ? const QuizScreen() : const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          SoundPlayer.stop();
          setState(() {
            _tab = i;
            if (i == 1) _quizOpened = true;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pets), label: 'تعرّف'),
          NavigationDestination(
              icon: Icon(Icons.hearing), label: 'لعبة الأصوات'),
        ],
      ),
    );
  }
}
