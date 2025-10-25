import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SelectStaffSheet extends StatefulWidget {
  const SelectStaffSheet({super.key});

  @override
  State<SelectStaffSheet> createState() => _SelectStaffSheetState();
}

class _SelectStaffSheetState extends State<SelectStaffSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('staff')
          .select('id,name,is_active')
          .eq('is_active', true)
          .order('name');
      setState(() => _rows = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      setState(() => _rows = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تم الاستلام بواسطة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_loading) const LinearProgressIndicator(),
            if (!_loading)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('استخدام حساب الجهاز'),
                subtitle: const Text('نَسب إلى المستخدم المسجّل'),
                onTap: () => Navigator.pop<Map<String, String?>>(context, {
                  'id': null,
                  'label': 'حساب الجهاز',
                }),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _rows.length,
                itemBuilder: (_, i) {
                  final r = _rows[i];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(r['name'] ?? ''),
                    onTap: () => Navigator.pop<Map<String, String?>>(context, {
                      'id': r['id'] as String,
                      'label': r['name'] as String,
                    }),
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
