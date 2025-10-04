import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/dress_card.dart';
import '../widgets/top_banner.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  bool loading = true;
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('dresses')
          .select('id,name,images')
          .order('created_at', ascending: false);
      setState(() {
        rows = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      // ignore: avoid_print
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const TopBanner(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                    ? const Center(child: Text('No dresses yet'))
                    : LayoutBuilder(
                        builder: (context, c) {
                          // Always 2 columns and center the grid on wide screens
                          const cross = 2;
                          const spacing = 16.0;
                          const cardAspect = 0.68;
                          // Choose a comfortable card width; grid total width = 2 * cardWidth + spacing
                          const cardWidth = 360.0;
                          final totalWidth = cross * cardWidth + spacing; // no outer padding accounted here
                          return Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: totalWidth + 32), // add padding visually
                              child: GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cross,
                                  mainAxisSpacing: spacing,
                                  crossAxisSpacing: spacing,
                                  childAspectRatio: cardAspect,
                                ),
                                itemCount: rows.length,
                                itemBuilder: (_, i) => DressCard(dress: rows[i]),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
