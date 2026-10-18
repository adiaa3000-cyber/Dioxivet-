
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

const String supabaseUrl =
    String.fromEnvironment('SUPABASE_URL');

const String supabaseKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

const String videoBucket = 'lecture-videos';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(const DioxivetApp(
      startupError:
          'إعدادات Supabase غير موجودة. راجع أسرار GitHub Actions.',
    ));
    return;
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
    );

    runApp(const DioxivetApp());
  } catch (e) {
    runApp(DioxivetApp(
      startupError: 'تعذر تهيئة Supabase:\n$e',
    ));
  }
}

class DioxivetApp extends StatelessWidget {
  final String? startupError;

  const DioxivetApp({super.key, this.startupError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dioxivet Academy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087F73),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
      ),
      home: startupError == null
          ? const HomePage()
          : ErrorPage(message: startupError!),
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final String contentType;
  final String contentUrl;
  final String storagePath;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.contentType,
    required this.contentUrl,
    required this.storagePath,
  });

  factory Lesson.fromMap(Map<String, dynamic> map) {
    String readText(
      List<String> keys, {
      String fallback = '',
    }) {
      for (final key in keys) {
        final value = map[key];

        if (value != null &&
            value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }

      return fallback;
    }

    return Lesson(
      id: readText(['id'], fallback: 'lesson'),
      title: readText(
        ['title', 'name', 'lesson_title'],
        fallback: 'محاضرة بدون عنوان',
      ),
      description: readText(
        ['description', 'details', 'subtitle'],
        fallback: 'اضغط لمشاهدة المحاضرة',
      ),
      contentType: readText(
        ['content_type', 'type', 'media_type'],
        fallback: 'video',
      ),
      contentUrl: readText(
        ['content_url', 'video_url', 'url', 'file_url'],
      ),
      storagePath: readText(
        [
          'storage_path',
          'content_path',
          'file_path',
          'video_path',
          'storage_url',
        ],
      ),
    );
  }
}

class LessonService {
  static final SupabaseClient _client =
      Supabase.instance.client;

  static Future<List<Lesson>> loadLessons() async {
    final response = await _client
        .from('lessons')
        .select();

    final rows =
        List<Map<String, dynamic>>.from(response);

    final lessons =
        rows.map((row) => Lesson.fromMap(row)).toList();

    lessons.sort((a, b) => a.title.compareTo(b.title));

    return lessons;
  }

  static Future<String> resolveVideoUrl(
    Lesson lesson,
  ) async {
    final directUrl = lesson.contentUrl;

    if (directUrl.startsWith('https://') ||
        directUrl.startsWith('http://')) {
      return directUrl;
    }

    // استخدام مسار التخزين لو موجود.
    var path = lesson.storagePath;

    // التعديل المطلوب: الفيديو الافتراضي لأي محاضرة
    // لا يوجد لها رابط مباشر أو مسار مسجل.
    if (path.isEmpty) {
      path = 'azareet.mp4.mp4';
    }

    if (path.startsWith('https://') ||
        path.startsWith('http://')) {
      return path;
    }

    path = path.replaceFirst(RegExp(r'^/+'), '');

    try {
      return await _client.storage
          .from(videoBucket)
          .createSignedUrl(path, 3600);
    } catch (e) {
      throw Exception(
        'تعذر الوصول إلى الفيديو: $path\n'
        'تأكد من وجود الملف داخل Bucket باسم '
        '$videoBucket ومن صلاحيات Storage.\n$e',
      );
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Lesson>> _lessonsFuture;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = LessonService.loadLessons();
  }

  Future<void> _refresh() async {
    setState(() {
      _lessonsFuture = LessonService.loadLessons();
    });

    await _lessonsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dioxivet Academy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor:
            Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'تحديث المحاضرات',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Lesson>>(
          future: _lessonsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ErrorContent(
                title: 'تعذر تحميل المحاضرات',
                message: _friendlyError(snapshot.error),
                onRetry: _refresh,
              );
            }

            final lessons = snapshot.data ?? [];

            if (lessons.isEmpty) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 110),
                  Icon(
                    Icons.video_library_outlined,
                    size: 76,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'لا توجد محاضرات حتى الآن',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'أضف محاضرة إلى جدول lessons '
                      'في Supabase، ثم اضغط تحديث.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            return ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'المحاضرات التعليمية',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text('عدد المحاضرات: ${lessons.length}'),
                const SizedBox(height: 16),
                for (final lesson in lessons)
                  Card(
                    margin:
                        const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        child: const Icon(
                          Icons.play_circle_outline,
                        ),
                      ),
                      title: Text(
                        lesson.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding:
                            const EdgeInsets.only(top: 8),
                        child: Text(lesson.description),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                      ),
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
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class LessonPage extends StatefulWidget {
  final Lesson lesson;

  const LessonPage({
    super.key,
    required this.lesson,
  });

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    VideoPlayerController? controller;

    try {
      final url = await LessonService.resolveVideoUrl(
        widget.lesson,
      );

      controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
      );

      _controller = controller;

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
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
      appBar: AppBar(
        title: Text(widget.lesson.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading)
            const SizedBox(
              height: 220,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            ErrorContent(
              title: 'تعذر تشغيل الفيديو',
              message: _error!,
              onRetry: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _initializeVideo();
              },
            )
          else if (controller != null &&
              controller.value.isInitialized)
            Column(
              children: [
                AspectRatio(
                  aspectRatio:
                      controller.value.aspectRatio > 0
                          ? controller.value.aspectRatio
                          : 16 / 9,
                  child: VideoPlayer(controller),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      iconSize: 36,
                      onPressed: () {
                        if (controller.value.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }

                        setState(() {});
                      },
                      icon: Icon(
                        controller.value.isPlaying
                            ? Icons.pause_circle
                            : Icons.play_circle,
                      ),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 20),
          Text(
            widget.lesson.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.lesson.description),
        ],
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  final String message;

  const ErrorPage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ErrorContent(
        title: 'تعذر تشغيل التطبيق',
        message: message,
        onRetry: () {},
      ),
    );
  }
}

class ErrorContent extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const ErrorContent({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

String _friendlyError(Object? error) {
  final message = error?.toString() ?? 'خطأ غير معروف';

  if (message.contains('permission') ||
      message.contains('42501') ||
      message.contains('RLS')) {
    return 'لا توجد صلاحية لقراءة البيانات. '
        'راجع سياسات RLS في Supabase.\n$message';
  }

  if (message.contains('lessons') ||
      message.contains('column') ||
      message.contains('does not exist')) {
    return 'تعذر قراءة جدول lessons. '
        'راجع اسم الجدول وصلاحياته.\n$message';
  }

  return message;
}
