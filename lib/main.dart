import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monochrome Beat Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
        ),
      ),
      home: const PlayerScreen(),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ВАШИ ТРЕКИ И КАРТИНКИ (строго как в ваших папках)
  final List<Map<String, String>> _playlist = [
    {
      'title': 'Orchestra',
      'file': 'assets/audio/Orchestra.mp3',
      'cover': 'assets/images/orchestra.jpg',
    },
    {
      'title': 'Payday',
      'file': 'assets/audio/payday triad.mp3',
      'cover': 'assets/images/payday triad.jpg',
    },
    {
      'title': 'Stars',
      'file': 'assets/audio/Please dont sleep.mp3',
      'cover': 'assets/images/Please dont sleep.jpg',
    },
    {
      'title': 'Weekend',
      'file': 'assets/audio/uppp.mp3',
      'cover': 'assets/images/uppp.jpg',
    },
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAudio(_currentIndex);
  }

  Future<void> _loadAudio(int index) async {
    try {
      await _audioPlayer.setAsset(_playlist[index]['file']!);
      setState(() {
        _currentIndex = index;
      });
      // Слушаем окончание трека для автоперехода
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _nextTrack();
        }
      });
    } catch (e) {
      debugPrint("Ошибка загрузки аудио: $e");
    }
  }

  void _nextTrack() {
    int nextIndex = (_currentIndex + 1) % _playlist.length;
    _loadAudio(nextIndex);
    _audioPlayer.play();
  }

  void _prevTrack() {
    int prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    _loadAudio(prevIndex);
    _audioPlayer.play();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'MONOCHROME BEATS',
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Большая обложка
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                image: DecorationImage(
                  image: AssetImage(_playlist[_currentIndex]['cover']!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Название трека
            Text(
              _playlist[_currentIndex]['title']!,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'YOUR PRODUCTION',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 40),

            // Прогресс-бар
            StreamBuilder<Duration>(
              stream: _audioPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                return ProgressBar(
                  progress: position,
                  total: _audioPlayer.duration ?? Duration.zero,
                  onSeek: (duration) => _audioPlayer.seek(duration),
                  baseBarColor: Colors.grey[800]!,
                  progressBarColor: Colors.white,
                  bufferedBarColor: Colors.grey[600],
                  thumbColor: Colors.white,
                  barHeight: 4.0,
                  thumbRadius: 6.0,
                  timeLabelTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Кнопки управления
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 40,
                  color: Colors.white,
                  onPressed: _prevTrack,
                  icon: const Icon(Icons.skip_previous),
                ),
                StreamBuilder<PlayerState>(
                  stream: _audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing;

                    if (processingState == ProcessingState.loading ||
                        processingState == ProcessingState.buffering) {
                      return const CircularProgressIndicator(
                        color: Colors.white,
                      );
                    } else if (playing != true) {
                      return IconButton(
                        iconSize: 80,
                        color: Colors.white,
                        onPressed: _audioPlayer.play,
                        icon: const Icon(Icons.play_circle_filled),
                      );
                    } else {
                      return IconButton(
                        iconSize: 80,
                        color: Colors.white,
                        onPressed: _audioPlayer.pause,
                        icon: const Icon(Icons.pause_circle_filled),
                      );
                    }
                  },
                ),
                IconButton(
                  iconSize: 40,
                  color: Colors.white,
                  onPressed: _nextTrack,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Список треков (Плейлист)
            Expanded(
              child: ListView.builder(
                itemCount: _playlist.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _currentIndex;
                  return ListTile(
                    onTap: () {
                      _loadAudio(index);
                      _audioPlayer.play();
                    },
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        _playlist[index]['cover']!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      _playlist[index]['title']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: Icon(
                      isSelected ? Icons.play_arrow : Icons.circle,
                      size: isSelected ? 20 : 10,
                      color: isSelected ? Colors.white : Colors.grey[800],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
