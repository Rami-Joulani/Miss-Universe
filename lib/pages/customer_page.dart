import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final _q = TextEditingController();
  final List<Map<String,dynamic>> _rows = [];
  bool _loading = false;

  Future<void> _search() async {
    final s = _q.text.trim();
    if (s.isEmpty) return;
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .rpc('search_customers', params: {'q': s}); // optional if you add a function; else do .or(...) like before
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Stub to be filled if you want a full customer browser
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: const Center(child: Text('Implement if needed')),
    );
  }
}