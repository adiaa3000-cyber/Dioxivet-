
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(const AppErrorApp(
      message: 'إعدادات Supabase غير موجودة.\n'
          'تحقق من إعدادات بناء التطبيق على GitHub.',
    ));
    return;
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
    );
    runApp(const DioxivetApp());
  } catch (e, stack) {
    debugPrint('Supabase initialization failed: $e\n$stack');
    runApp(AppErrorApp(message: 'فشل الاتصال بـ Supabase:\n$e'));
  }
}

class AppTheme {
  static const green = Color(0xFF176B52);
  static const mint = Color(0xFFEAF5EF);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF7F9F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: green,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
}

class AppErrorApp extends StatelessWidget {
  final String message;
  const AppErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pets,
                        size: 64, color: AppTheme.green),
                    const SizedBox(height: 16),
                    const Text(
                      'Dioxivet Academy',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      message,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DioxivetApp extends StatelessWidget {
  const DioxivetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dioxivet Academy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomePage(),
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final String contentType;
  final String? contentUrl;
  final String? storagePath;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.contentType,
    this.contentUrl,
    this.storagePath,
  });

  factory Lesson.fromMap(Map<String, dynamic> row) {
    return Lesson(
      id: '${row['id'] ?? ''}',
      title: '${row['title'] ?? 'محاضرة بدون عنوان'}',
      description: '${row['description'] ?? ''}',
      contentType: '${row['content_type'] ?? 'video'}',
      contentUrl: row['content_url']?.toString(),
      storagePath: row['storage_path']?.toString(),
    );
  }

  String resolveVideoUrl() {
    final direct = contentUrl?.trim() ?? '';

    if (direct.startsWith('https://') ||
        direct.startsWith('http://')) {
      return direct;
    }

    final path = storagePath?.trim() ?? '';
    if (path.isEmpty) {
      throw Exception('مسار الفيديو غير موجود في جدول lessons');
    }

    return Supabase.instance.client.storage
        .from('lecture-videos')
        .getPublicUrl(path);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Lesson>> lessonsFuture;

  @override
  void initState() {
    super.initState();
    lessonsFuture = loadLessons();
  }

  Future<List<Lesson>> loadLessons() async {
    final rows = await Supabase.instance.client
        .from('lessons')
        .select(
          'id,title,description,content_type,content_url,storage_path',
        )
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) =>
            Lesson.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> reload() async {
    final future = loadLessons();
    setState(() => lessonsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pets),
            SizedBox(width: 10),
            Text(
              'Dioxivet Academy',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              reload().catchError((_) {});
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث المحاضرات',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await reload();
        },
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.green,
                    Color(0xFF29916D),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحبًا بك 👋',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'تعلّم الطب البيطري\nبخطوة كل يوم',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'محاضراتك ومصادرك التعليمية في مكان واحد',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'المحاضرات',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Lesson>>(
              future: lessonsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return MessageCard(
                    icon: Icons.cloud_off,
                    title: 'تعذر تحميل المحاضرات',
                    message:
                        'تحقق من جدول lessons وصلاحيات القراءة '
                        'وإعدادات Supabase.\n\n${snapshot.error}',
                    buttonText: 'إعادة المحاولة',
                    onPressed: () {
                      reload().catchError((_) {});
                    },
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const MessageCard(
                    icon: Icons.video_library_outlined,
                    title: 'لا توجد محاضرات',
                    message:
                        'أضف محاضرة إلى جدول lessons في Supabase.',
                  );
                }

                return Column(
                  children: items.map((lesson) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.mint,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.play_circle_fill,
                            size: 32,
                            color: AppTheme.green,
                          ),
                        ),
                        title: Text(
                          lesson.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          lesson.description.isEmpty
                              ? 'اضغط لمشاهدة المحاضرة'
                              : lesson.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing:
                            const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LessonPage(lesson: lesson),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const MessageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 42, color: AppTheme.green),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              message,
              textAlign: TextAlign.center,
            ),
            if (buttonText != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onPressed,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LessonPage extends StatefulWidget {
  final Lesson lesson;

  const LessonPage({super.key, required this.lesson});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  VideoPlayerController? controller;
  String? errorMessage;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    initializeVideo();
  }

  Future<void> initializeVideo() async {
    VideoPlayerController? newController;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final url = widget.lesson.resolveVideoUrl();
      newController =
          VideoPlayerController.networkUrl(Uri.parse(url));

      await newController.initialize();

      if (!mounted) {
        await newController.dispose();
        return;
      }

      setState(() {
        controller = newController;
        loading = false;
      });
    } catch (e, stack) {
      debugPrint('Video initialization failed: $e\n$stack');
      await newController?.dispose();

      if (!mounted) return;

      setState(() {
        errorMessage = '$e';
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = controller;

    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          AspectRatio(
            aspectRatio:
                video != null && video.value.isInitialized
                    ? video.value.aspectRatio
                    : 16 / 9,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(18),
              ),
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'تعذر تشغيل الفيديو',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                TextButton(
                                  onPressed: initializeVideo,
                                  child: const Text('إعادة المحاولة'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : video == null
                          ? const Center(
                              child: Text(
                                'الفيديو غير جاهز',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(video),
                                IconButton.filled(
                                  iconSize: 44,
                                  onPressed: () {
                                    if (video.value.isPlaying) {
                                      video.pause();
                                    } else {
                                      video.play();
                                    }
                                    setState(() {});
                                  },
                                  icon: Icon(
                                    video.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                                ),
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  bottom: 4,
                                  child: VideoProgressIndicator(
                                    video,
                                    allowScrubbing: true,
                                    colors: const VideoProgressColors(
                                      playedColor: Colors.greenAccent,
                                      bufferedColor: Colors.white54,
                                      backgroundColor: Colors.white24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.lesson.title,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.lesson.description.isEmpty
                ? 'محاضرة تعليمية من Dioxivet Academy.'
                : widget.lesson.description,
          ),
        ],
      ),
    );
  }
}
