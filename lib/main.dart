
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) {
    runApp(const ConfigurationApp());
    return;
  }

  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabasePublishableKey,
  );

  runApp(const DioxivetApp());
}

class ConfigurationApp extends StatelessWidget {
  const ConfigurationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dioxivet Academy',
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.pets, size: 64, color: AppTheme.green),
                  SizedBox(height: 16),
                  Text(
                    'Dioxivet Academy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'التطبيق جاهز، لكن إعدادات Supabase غير موجودة. '
                    'أضف SUPABASE_URL وSUPABASE_PUBLISHABLE_KEY في إعدادات البناء.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
          centerTitle: false,
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
      contentUrl: row['content_url'] as String?,
      storagePath: row['storage_path'] as String?,
    );
  }

  String resolveVideoUrl() {
    final direct = contentUrl?.trim() ?? '';

    if (direct.startsWith('https://') || direct.startsWith('http://')) {
      return direct;
    }

    final path = (storagePath?.trim().isNotEmpty ?? false)
        ? storagePath!.trim()
        : 'azareet.mp4.mp4';

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
  late Future<List<Lesson>> _lessons;

  @override
  void initState() {
    super.initState();
    _lessons = _loadLessons();
  }

  Future<List<Lesson>> _loadLessons() async {
    final response = await Supabase.instance.client
        .from('lessons')
        .select('id,title,description,content_type,content_url,storage_path')
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => Lesson.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  void _reload() {
    setState(() {
      _lessons = _loadLessons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pets, size: 28),
            SizedBox(width: 10),
            Text(
              'Dioxivet Academy',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث المحاضرات',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _lessons;
        },
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.green, Color(0xFF29916D)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحبًا بك 👋',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'تعلّم الطب البيطري\nبخطوة كل يوم',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'محاضراتك ومصادرك التعليمية في مكان واحد',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'المحاضرات',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Lesson>>(
              future: _lessons,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return _MessageCard(
                    icon: Icons.cloud_off,
                    title: 'تعذر تحميل المحاضرات',
                    message: 'راجع إعدادات Supabase وسياسات قاعدة البيانات، '
                        'ثم اضغط زر التحديث.\n\nالتفاصيل: ${snapshot.error}',
                    actionLabel: 'إعادة المحاولة',
                    onPressed: _reload,
                  );
                }

                final lessons = snapshot.data ?? [];

                if (lessons.isEmpty) {
                  return const _MessageCard(
                    icon: Icons.video_library_outlined,
                    title: 'لا توجد محاضرات حتى الآن',
                    message: 'بعد إضافة محاضرة إلى جدول lessons ستظهر هنا.',
                  );
                }

                return Column(
                  children: lessons
                      .map(
                        (lesson) => _LessonCard(
                          lesson: lesson,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LessonPage(lesson: lesson),
                              ),
                            );
                          },
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppTheme.mint,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.play_circle_fill,
            color: AppTheme.green,
            size: 32,
          ),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            lesson.description.isEmpty
                ? 'اضغط لمشاهدة المحاضرة'
                : lesson.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
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
            SelectableText(message, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onPressed,
                child: Text(actionLabel!),
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
  VideoPlayerController? _controller;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final url = widget.lesson.resolveVideoUrl();
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          AspectRatio(
            aspectRatio: controller?.value.aspectRatio ?? 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _error != null
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'تعذر تشغيل الفيديو. تأكد من وجود الملف وصلاحيات الوصول إليه.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(controller!),
                            IconButton.filled(
                              iconSize: 42,
                              onPressed: () {
                                setState(() {
                                  if (controller.value.isPlaying) {
                                    controller.pause();
                                  } else {
                                    controller.play();
                                  }
                                });
                              },
                              icon: Icon(
                                controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
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
          if (_error != null) ...[
            const SizedBox(height: 12),
            SelectableText('تفاصيل الخطأ: $_error'),
            TextButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _initializeVideo();
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    );
  }
}
