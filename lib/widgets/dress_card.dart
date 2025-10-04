import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/details_page.dart';

class DressCard extends StatelessWidget {
  final Map<String, dynamic> dress;
  const DressCard({super.key, required this.dress});

  @override
  Widget build(BuildContext context) {
    final List imgs = (dress['images'] as List?) ?? const [];
    String cover;
    if (imgs.isNotEmpty) {
      final first = imgs.first as String;
      // If the value looks like a URL, use it; otherwise treat as storage path
      final isUrl = first.startsWith('http://') || first.startsWith('https://');
      cover = isUrl
          ? first
          : Supabase.instance.client.storage.from('dresses').getPublicUrl(first);
    } else {
      cover = 'https://placehold.co/900x1200?text=Dress';
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DressDetailsPage(dress: dress),
            ),
          );
        },
        child: SizedBox(
          height: 400,
          child: ClipRect(
            child: Image.network(
              cover,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
  }
}
