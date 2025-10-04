import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DressDetailsPage extends StatefulWidget {
  final Map<String, dynamic> dress;

  const DressDetailsPage({super.key, required this.dress});

  @override
  State<DressDetailsPage> createState() => _DressDetailsPageState();
}

class _DressDetailsPageState extends State<DressDetailsPage> {
  late final Future<List<String>> _imageUrlsFuture;
  late final PageController _pageController;
  final ValueNotifier<int> _currentIndex = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _imageUrlsFuture = _loadImages().then((value) {
      _currentIndex.value = 0;
      return value;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndex.dispose();
    super.dispose();
  }

  Future<List<String>> _loadImages() async {
    final inlineImages = _resolveInlineImages();
    final dressId = widget.dress['id'];
    if (dressId == null) {
      return inlineImages;
    }

    try {
      final data = await Supabase.instance.client
          .from('dress_images')
          .select('path,is_main,sort_order')
          .eq('dress_id', dressId)
          .order('is_main', ascending: false)
          .order('sort_order', ascending: true);

      final records = List<Map<String, dynamic>>.from(data as List);
      final urls = <String>[];
      for (final record in records) {
        final path = record['path'] as String?;
        if (path == null || path.isEmpty) continue;
        final isUrl = path.startsWith('http://') || path.startsWith('https://');
        urls.add(
          isUrl
              ? path
              : Supabase.instance.client.storage.from('dresses').getPublicUrl(path),
        );
      }

      if (urls.isNotEmpty) {
        return urls;
      }
    } catch (_) {
      // If remote load fails, fall back to inline images below.
    }

    return inlineImages;
  }

  List<String> _resolveInlineImages() {
    final images = (widget.dress['images'] as List?) ?? const [];
    final resolved = <String>[];
    for (final image in images) {
      if (image is! String || image.isEmpty) continue;
      final isUrl = image.startsWith('http://') || image.startsWith('https://');
      resolved.add(
        isUrl
            ? image
            : Supabase.instance.client.storage.from('dresses').getPublicUrl(image),
      );
    }
    if (resolved.isEmpty) {
      resolved.add('https://placehold.co/900x1200?text=Dress');
    }
    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<List<String>>(
        future: _imageUrlsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load images'));
          }

          final images = snapshot.data ?? const [];
          if (images.isEmpty) {
            return const Center(child: Text('No images available'));
          }

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) => _currentIndex.value = index,
                    itemBuilder: (context, index) {
                      return Center(
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              images[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (images.length > 1)
                  ValueListenableBuilder<int>(
                    valueListenable: _currentIndex,
                    builder: (context, current, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < images.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: current == i ? 20 : 8,
                              decoration: BoxDecoration(
                                color: current == i
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
