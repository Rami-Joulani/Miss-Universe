import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SelectOpenGroupSheet extends StatefulWidget {
  final String customerId;
  const SelectOpenGroupSheet({super.key, required this.customerId});

  @override
  State<SelectOpenGroupSheet> createState() => _SelectOpenGroupSheetState();
}

class _SelectOpenGroupSheetState extends State<SelectOpenGroupSheet> {
  bool _loading = true;
  List<Map<String,dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('v_customer_balances')
          .select('group_key,agreement_label,expected_total,paid,balance,status,opened_at')
          .eq('customer_id', widget.customerId)
          .eq('status','open')
          .order('opened_at', ascending: false);
      setState(() => _rows = List<Map<String,dynamic>>.from(data));
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
            const Text('اختر عربون للاستكمال', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_loading) const LinearProgressIndicator(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _rows.length,
                itemBuilder: (_, i) {
                  final r = _rows[i];
                  final label = r['agreement_label'] ?? 'غير مسمى';
                  final bal = r['balance'] ?? 0;
                  return ListTile(
                    title: Text(label),
                    subtitle: Text('الباقي: $bal'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop<String>(context, r['group_key'] as String),
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