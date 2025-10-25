import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SelectCustomerSheet extends StatefulWidget {
  const SelectCustomerSheet({super.key});

  @override
  State<SelectCustomerSheet> createState() => _SelectCustomerSheetState();
}

class _SelectCustomerSheetState extends State<SelectCustomerSheet> {
  final _controller = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  List<Map<String,dynamic>> _results = [];
  bool _loading = false;

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('customers')
          .select('id,name,phone')
          .or('name.ilike.%$q%,phone.ilike.%$q%')
          .limit(50);
      setState(() => _results = List<Map<String,dynamic>>.from(data));
    } catch (_) {
      setState(() => _results = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    // very simple split -> name or phone
    final isPhone = RegExp(r'[0-9\-\+\s]+').hasMatch(q) && q.replaceAll(RegExp(r'\D'), '').length >= 6;
    final payload = {
      'name': isPhone ? 'Customer' : q,
      'phone': isPhone ? q : '0000000',
    };
    try {
      final row = await Supabase.instance.client.from('customers').insert(payload).select('id,name,phone').single();
      if (mounted) {
        Navigator.pop<Map<String,String?>>(context, {
          'id': row['id'] as String,
          'label': '${row['name']} • ${row['phone']}',
        });
      }
    } catch (_) {}
  }

  Future<void> _openCreateForm() async {
    _nameCtrl.clear();
    _phoneCtrl.clear();
    final res = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('اضف زبون'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'الاسم'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('الغاء')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
    if (res != true) return;
    final name = _nameCtrl.text.trim().isEmpty ? 'Customer' : _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim().isEmpty ? '0000000' : _phoneCtrl.text.trim();
    try {
      final row = await Supabase.instance.client
          .from('customers')
          .insert({'name': name, 'phone': phone})
          .select('id,name,phone')
          .single();
      if (mounted) {
        Navigator.pop<Map<String,String?>>(context, {
          'id': row['id'] as String,
          'label': '${row['name']} • ${row['phone']}',
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add: $e')),
      );
    }
  }

  Future<void> _openCreateFormSheet() async {
    _nameCtrl.clear();
    _phoneCtrl.clear();
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('اضف زبون', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'الاسم'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('الغاء')),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('حفظ'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (res == true) {
      final name = _nameCtrl.text.trim().isEmpty ? 'Customer' : _nameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim().isEmpty ? '0000000' : _phoneCtrl.text.trim();
      try {
        final row = await Supabase.instance.client
            .from('customers')
            .insert({'name': name, 'phone': phone})
            .select('id,name,phone')
            .single();
        if (mounted) {
          Navigator.pop<Map<String,String?>>(context, {
            'id': row['id'] as String,
            'label': '${row['name']} • ${row['phone']}',
          });
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'البحث عن زبون من خلال الاسم أو رقم الهاتف',
                  suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 12),
              if (_loading) const LinearProgressIndicator(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final r = _results[i];
                    return ListTile(
                      title: Text(r['name'] ?? ''),
                      subtitle: Text(r['phone'] ?? ''),
                      onTap: () {
                        Navigator.pop<Map<String,String?>>(context, {
                          'id': r['id'] as String,
                          'label': '${r['name']} • ${r['phone']}',
                        });
                      },
                    );
                  },
                ),
              ),
              if (_results.isEmpty && !_loading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'لا توجد نتائج. يمكنك إضافة زبون جديد.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _openCreateFormSheet,
                    icon: const Icon(Icons.person_add),
                    label: const Text('اضف زبون جديد'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}