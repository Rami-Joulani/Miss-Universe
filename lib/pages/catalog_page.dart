import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/dress_card.dart';
import '../widgets/top_banner.dart';
import 'new_payment_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  bool loading = true;
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> _categories = [];

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
      final cats = await Supabase.instance.client
          .from('categories')
          .select('id,name')
          .order('name', ascending: true);
      setState(() {
        rows = List<Map<String, dynamic>>.from(data);
        _categories = List<Map<String, dynamic>>.from(cats);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      // ignore: avoid_print
      print(e);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Builder(
            builder: (ctx) =>
                TopBanner(onMenu: () => Scaffold.of(ctx).openEndDrawer()),
          ),
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
                      final totalWidth =
                          cross * cardWidth +
                          spacing; // no outer padding accounted here
                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: totalWidth + 32,
                          ), // add padding visually
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
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
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.store),
                title: const Text('الصالة الرئيسية'),
                subtitle: const Text('تصفح الفساتين'),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(),
              Expanded(
                child: _categories.isEmpty
                    ? const Center(child: Text('لا يوجد تصنيفات بعد'))
                    : ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (_, i) {
                          final c = _categories[i];
                          return ListTile(
                            leading: const Icon(Icons.label),
                            title: Text('${c['name']}'),
                            onTap: () {
                              // TODO: filter by category id if you add that relation
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.point_of_sale),
                title: const Text('تسجيل دفعة جديدة'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NewPaymentPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('تسجيل الخروج'),
                onTap: _signOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
